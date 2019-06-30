//
//  OZZipFile.m
//  Objective-Zip v. 1.0.5
//
//  Created by Gianluca Bertani on 25/12/09.
//  Copyright 2009-2017 Gianluca Bertani. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without 
//  modification, are permitted provided that the following conditions 
//  are met:
//
//  * Redistributions of source code must retain the above copyright notice, 
//    this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, 
//    this list of conditions and the following disclaimer in the documentation 
//    and/or other materials provided with the distribution.
//  * Neither the name of Gianluca Bertani nor the names of its contributors 
//    may be used to endorse or promote products derived from this software 
//    without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "OZZipFile.h"
#import "OZZipFile+Standard.h"
#import "OZZipFile+NSError.h"
#import "OZZipException.h"
#import "OZZipException+Internals.h"
#import "OZZipReadStream.h"
#import "OZZipReadStream+Standard.h"
#import "OZZipReadStream+NSError.h"
#import "OZZipReadStream+Internals.h"
#import "OZZipWriteStream.h"
#import "OZZipWriteStream+Standard.h"
#import "OZZipWriteStream+NSError.h"
#import "OZZipWriteStream+Internals.h"
#import "OZFileInZipInfo.h"
#import "OZFileInZipInfo+Internals.h"
#import "NSDate+DOSDate.h"

#include "zip.h"
#include "unzip.h"

#define FILE_IN_ZIP_MAX_NAME_LENGTH (256)


#pragma mark -
#pragma mark OZZipFile extension

@interface OZZipFile () {
    NSString *_fileName;
    OZZipFileMode _mode;
    BOOL _legacy32BitMode;
    
@private
    zipFile _zipFile;
    unzFile _unzFile;
}


@end


#pragma mark -
#pragma mark OZZipFile implementation

@implementation OZZipFile


#pragma mark -
#pragma mark Initialization

- (instancetype) initWithFileName:(NSString *)fileName mode:(OZZipFileMode)mode {
    return [self initWithFileName:fileName mode:mode legacy32BitMode:NO];
}

- (instancetype) initWithFileName:(NSString *)fileName mode:(OZZipFileMode)mode legacy32BitMode:(BOOL)legacy32BitMode {
	if (self= [super init]) {
		_fileName= fileName;
		_mode= mode;
        _legacy32BitMode= legacy32BitMode;
		
        const char *path= [_fileName cStringUsingEncoding:NSUTF8StringEncoding];
		switch (mode) {
			case OZZipFileModeUnzip:
                
                // Support for legacy 32 bit mode: here we use 32 or 64 bit version
                // alternatively, as internal (common) version is not exposed
                _unzFile= (_legacy32BitMode ? unzOpen(path) : unzOpen64(path));
				if (_unzFile == NULL)
                    @throw [OZZipException zipExceptionWithError:OZ_ERROR_NO_SUCH_FILE reason:@"Can't open '%@'", _fileName];
				break;
				
			case OZZipFileModeCreate:
                
                // Support for legacy 32 bit mode: here we use the common version
                _zipFile= zipOpen3(path, APPEND_STATUS_CREATE, 0, NULL, NULL);
				if (_zipFile == NULL)
                    @throw [OZZipException zipExceptionWithError:OZ_ERROR_NO_SUCH_FILE reason:@"Can't open '%@'", _fileName];
				break;
				
			case OZZipFileModeAppend:
                
                // Support for legacy 32 bit mode: here we use the common version
                _zipFile= zipOpen3(path, APPEND_STATUS_ADDINZIP, 0, NULL, NULL);
				if (_zipFile == NULL)
                    @throw [OZZipException zipExceptionWithError:OZ_ERROR_NO_SUCH_FILE reason:@"Can't open '%@'", _fileName];
				break;
				
			default:
                @throw [OZZipException zipExceptionWithReason:@"Unknown mode %d", _mode];			
		}
	}
	
	return self;
}


#pragma mark -
#pragma mark Initialization (NSError variants)

- (instancetype) initWithFileName:(NSString *)fileName mode:(OZZipFileMode)mode error:(NSError *__autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        return [self initWithFileName:fileName mode:mode];
    
    } ERROR_WRAP_END_AND_RETURN(error, nil);
}

- (instancetype) initWithFileName:(NSString *)fileName mode:(OZZipFileMode)mode legacy32BitMode:(BOOL)legacy32BitMode error:(NSError *__autoreleasing *)error {
    ERROR_WRAP_BEGIN {

        return [self initWithFileName:fileName mode:mode legacy32BitMode:legacy32BitMode];

    } ERROR_WRAP_END_AND_RETURN(error, nil);
}


#pragma mark -
#pragma mark File writing

- (OZZipWriteStream *) writeFileInZipWithName:(NSString *)fileNameInZip compressionLevel:(OZZipCompressionLevel)compressionLevel {
	if (_mode == OZZipFileModeUnzip)
		@throw [OZZipException zipExceptionWithReason:@"Operation not permitted in Unzip mode"];
	
	zip_fileinfo zi;
	zi.internal_fa= 0;
	zi.external_fa= 0;
	zi.dos_date= [[NSDate date] dosDate];
	
    // Support for legacy 32 bit mode: here we use the common version,
    // passing a flag to tell if it is a 32 or 64 bit file
	int err= zipOpenNewFileInZip3_64(_zipFile,
									 [fileNameInZip cStringUsingEncoding:NSUTF8StringEncoding],
									 &zi,
									 NULL, 0, NULL, 0, NULL,
									 (compressionLevel != OZZipCompressionLevelNone) ? Z_DEFLATED : 0,
									 compressionLevel, 0,
									 -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
                                     NULL, 0,
                                     (_legacy32BitMode ? 0 : 1));
    
    if (err != ZIP_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error opening '%@' in zipfile", fileNameInZip];
	
	return [[OZZipWriteStream alloc] initWithZipFileStruct:_zipFile fileNameInZip:fileNameInZip];
}

- (OZZipWriteStream *) writeFileInZipWithName:(NSString *)fileNameInZip fileDate:(NSDate *)fileDate compressionLevel:(OZZipCompressionLevel)compressionLevel {
	if (_mode == OZZipFileModeUnzip)
		@throw [OZZipException zipExceptionWithReason:@"Operation not permitted in Unzip mode"];
	
	zip_fileinfo zi;
	zi.internal_fa= 0;
	zi.external_fa= 0;
    zi.dos_date= [fileDate dosDate];
	
    // Support for legacy 32 bit mode: here we use the common version,
    // passing a flag to tell if it is a 32 or 64 bit file
	int err= zipOpenNewFileInZip3_64(_zipFile,
									 [fileNameInZip cStringUsingEncoding:NSUTF8StringEncoding],
									 &zi,
									 NULL, 0, NULL, 0, NULL,
									 (compressionLevel != OZZipCompressionLevelNone) ? Z_DEFLATED : 0,
									 compressionLevel, 0,
									 -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
									 NULL, 0,
                                     (_legacy32BitMode ? 0 : 1));
    
	if (err != ZIP_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error opening '%@' in zipfile", fileNameInZip];
	
	return [[OZZipWriteStream alloc] initWithZipFileStruct:_zipFile fileNameInZip:fileNameInZip];
}

- (OZZipWriteStream *) writeFileInZipWithName:(NSString *)fileNameInZip fileDate:(NSDate *)fileDate compressionLevel:(OZZipCompressionLevel)compressionLevel password:(NSString *)password crc32:(uint32_t)crc32 {
	if (_mode == OZZipFileModeUnzip)
		@throw [OZZipException zipExceptionWithReason:@"Operation not permitted in Unzip mode"];
	
	zip_fileinfo zi;
	zi.internal_fa= 0;
	zi.external_fa= 0;
	zi.dos_date= [fileDate dosDate];
	
    // Support for legacy 32 bit mode: here we use the common version,
    // passing a flag to tell if it is a 32 or 64 bit file
	int err= zipOpenNewFileInZip3_64(_zipFile,
									 [fileNameInZip cStringUsingEncoding:NSUTF8StringEncoding],
									 &zi,
									 NULL, 0, NULL, 0, NULL,
									 (compressionLevel != OZZipCompressionLevelNone) ? Z_DEFLATED : 0,
									 compressionLevel, 0,
									 -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
									 [password cStringUsingEncoding:NSUTF8StringEncoding], crc32,
                                     (_legacy32BitMode ? 0 : 1));
    
	if (err != ZIP_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error opening '%@' in zipfile", fileNameInZip];
	
	return [[OZZipWriteStream alloc] initWithZipFileStruct:_zipFile fileNameInZip:fileNameInZip];
}


#pragma mark -
#pragma mark File writing (NSError variants)

- (OZZipWriteStream *) writeFileInZipWithName:(NSString *)fileNameInZip compressionLevel:(OZZipCompressionLevel)compressionLevel error:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        return [self writeFileInZipWithName:fileNameInZip compressionLevel:compressionLevel];
        
    } ERROR_WRAP_END_AND_RETURN(error, nil);
}

- (OZZipWriteStream *) writeFileInZipWithName:(NSString *)fileNameInZip fileDate:(NSDate *)fileDate compressionLevel:(OZZipCompressionLevel)compressionLevel error:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        return [self writeFileInZipWithName:fileNameInZip fileDate:fileDate compressionLevel:compressionLevel];
        
    } ERROR_WRAP_END_AND_RETURN(error, nil);
}

- (OZZipWriteStream *) writeFileInZipWithName:(NSString *)fileNameInZip fileDate:(NSDate *)fileDate compressionLevel:(OZZipCompressionLevel)compressionLevel password:(NSString *)password crc32:(uint32_t)crc32 error:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        return [self writeFileInZipWithName:fileNameInZip fileDate:fileDate compressionLevel:compressionLevel password:password crc32:crc32];
        
    } ERROR_WRAP_END_AND_RETURN(error, nil);
}


#pragma mark -
#pragma mark File seeking and info

- (void) goToFirstFileInZip {
	if (_mode != OZZipFileModeUnzip)
		@throw [OZZipException zipExceptionWithReason:@"Operation permitted only in Unzip mode"];
	
	int err= unzGoToFirstFile(_unzFile);
	if (err != UNZ_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error going to first file in zip of '%@'", _fileName];
}

- (BOOL) goToNextFileInZip {
	if (_mode != OZZipFileModeUnzip)
		@throw [OZZipException zipExceptionWithReason:@"Operation permitted only in Unzip mode"];
	
	int err= unzGoToNextFile(_unzFile);
	if (err == UNZ_END_OF_LIST_OF_FILE)
		return NO;

	if (err != UNZ_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error going to next file in zip of '%@'", _fileName];
	
	return YES;
}

- (BOOL) locateFileInZip:(NSString *)fileNameInZip {
	if (_mode != OZZipFileModeUnzip)
		@throw [OZZipException zipExceptionWithReason:@"Operation permitted only in Unzip mode"];
	
	int err= unzLocateFile(_unzFile, [fileNameInZip cStringUsingEncoding:NSUTF8StringEncoding], NULL);
	if (err == UNZ_END_OF_LIST_OF_FILE)
		return NO;

	if (err != UNZ_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error localting file in zip of '%@'", _fileName];
	
	return YES;
}

- (NSUInteger) numFilesInZip {
    if (_mode != OZZipFileModeUnzip)
        @throw [OZZipException zipExceptionWithReason:@"Operation permitted only in Unzip mode"];
    
    // Support for legacy 32 bit mode: here we use the 32 or 64 bit
    // version alternatively, as there is not internal (common) version
    if (_legacy32BitMode) {
        unz_global_info gi;
        
        int err= unzGetGlobalInfo(_unzFile, &gi);
        if (err != UNZ_OK)
            @throw [OZZipException zipExceptionWithError:err reason:@"Error getting global info of '%@'", _fileName];
        
        return gi.number_entry;
        
    } else {
        unz_global_info64 gi;
        
        int err= unzGetGlobalInfo64(_unzFile, &gi);
        if (err != UNZ_OK)
            @throw [OZZipException zipExceptionWithError:err reason:@"Error getting global info of '%@'", _fileName];
        
        return (NSUInteger) gi.number_entry;
    }
}

- (NSArray *) listFileInZipInfos {
    NSUInteger num= [self numFilesInZip];
    if (num < 1)
        return [NSArray array];
    
    NSMutableArray *files= [[NSMutableArray alloc] initWithCapacity:num];
    
    [self goToFirstFileInZip];
    for (int i= 0; i < num; i++) {
        OZFileInZipInfo *info= [self getCurrentFileInZipInfo];
        [files addObject:info];
        
        if ((i +1) < num)
            [self goToNextFileInZip];
    }
    
    return files;
}

- (OZFileInZipInfo *) getCurrentFileInZipInfo {
	if (_mode != OZZipFileModeUnzip)
		@throw [OZZipException zipExceptionWithReason:@"Operation permitted only in Unzip mode"];

	char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
	unz_file_info64 file_info;
	
    // Support for legacy 32 bit mode: here we use the 64 bit version,
    // as it also internally called from the 32 bit version
	int err= unzGetCurrentFileInfo64(_unzFile, &file_info, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
	if (err != UNZ_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error getting current file info of '%@'", _fileName];
	
	NSString *name= [NSString stringWithCString:filename_inzip encoding:NSUTF8StringEncoding];
	
	OZZipCompressionLevel level= OZZipCompressionLevelNone;
	if (file_info.compression_method != 0) {
		switch ((file_info.flag & 0x6) / 2) {
			case 0:
				level= OZZipCompressionLevelDefault;
				break;
				
			case 1:
				level= OZZipCompressionLevelBest;
				break;
				
			default:
				level= OZZipCompressionLevelFastest;
				break;
		}
	}
	
	BOOL crypted= ((file_info.flag & 1) != 0);
	NSDate *date= [NSDate fromDosDate:file_info.dos_date];
	
	OZFileInZipInfo *info= [[OZFileInZipInfo alloc] initWithName:name
                                                          length:file_info.uncompressed_size
                                                           level:level
                                                         crypted:crypted
                                                            size:file_info.compressed_size
                                                            date:date
                                                           crc32:file_info.crc];
	return info;
}


#pragma mark -
#pragma mark File seeking and info (NSError variants)

- (BOOL) goToFirstFileInZipWithError:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        [self goToFirstFileInZip];
        
        return YES;
        
    } ERROR_WRAP_END_AND_RETURN(error, NO);
}

- (BOOL) goToNextFileInZipWithError:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        return [self goToNextFileInZip];
        
    } ERROR_WRAP_END_AND_RETURN(error, NO);
}

- (NSInteger) locateFileInZip:(NSString *)fileNameInZip error:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        BOOL located= [self locateFileInZip:fileNameInZip];
        return (located ? OZLocateFileResultFound : OZLocateFileResultNotFound);
        
    } ERROR_WRAP_END_AND_RETURN(error, 0);
}

- (NSUInteger) numFilesInZipWithError:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        return [self numFilesInZip];
        
    } ERROR_WRAP_END_AND_RETURN(error, 0);
}

- (NSArray *) listFileInZipInfosWithError:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        return [self listFileInZipInfos];
        
    } ERROR_WRAP_END_AND_RETURN(error, nil);
}

- (OZFileInZipInfo *) getCurrentFileInZipInfoWithError:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        return [self getCurrentFileInZipInfo];
        
    } ERROR_WRAP_END_AND_RETURN(error, nil);
}


#pragma mark -
#pragma mark File reading

- (OZZipReadStream *) readCurrentFileInZip {
	if (_mode != OZZipFileModeUnzip)
		@throw [OZZipException zipExceptionWithReason:@"Operation permitted only in Unzip mode"];

	char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
	unz_file_info64 file_info;
	
    // Support for legacy 32 bit mode: here we use the 64 bit version,
    // as it also internally called from the 32 bit version
	int err= unzGetCurrentFileInfo64(_unzFile, &file_info, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
	if (err != UNZ_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error getting current file info of '%@'", _fileName];
	
	NSString *fileNameInZip= [NSString stringWithCString:filename_inzip encoding:NSUTF8StringEncoding];
	
	err= unzOpenCurrentFilePassword(_unzFile, NULL);
	if (err != UNZ_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error opening current file of '%@'", _fileName];
	
	return [[OZZipReadStream alloc] initWithUnzFileStruct:_unzFile fileNameInZip:fileNameInZip];
}

- (OZZipReadStream *) readCurrentFileInZipWithPassword:(NSString *)password {
	if (_mode != OZZipFileModeUnzip)
		@throw [OZZipException zipExceptionWithReason:@"Operation permitted only in Unzip mode"];
	
	char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
	unz_file_info64 file_info;
	
    // Support for legacy 32 bit mode: here we use the 64 bit version,
    // as it also internally called from the 32 bit version
	int err= unzGetCurrentFileInfo64(_unzFile, &file_info, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
	if (err != UNZ_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error getting current file info of '%@'", _fileName];
	
	NSString *fileNameInZip= [NSString stringWithCString:filename_inzip encoding:NSUTF8StringEncoding];

	err= unzOpenCurrentFilePassword(_unzFile, [password cStringUsingEncoding:NSUTF8StringEncoding]);
	if (err != UNZ_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error opening current file of '%@'", _fileName];
	
	return [[OZZipReadStream alloc] initWithUnzFileStruct:_unzFile fileNameInZip:fileNameInZip];
}


#pragma mark -
#pragma mark File reading (NSError variants)

- (OZZipReadStream *) readCurrentFileInZipWithError:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        return [self readCurrentFileInZip];
        
    } ERROR_WRAP_END_AND_RETURN(error, nil);
}

- (OZZipReadStream *) readCurrentFileInZipWithPassword:(NSString *)password error:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        return [self readCurrentFileInZipWithPassword:password];
        
    } ERROR_WRAP_END_AND_RETURN(error, nil);
}


#pragma mark -
#pragma mark Closing

- (void) close {
	switch (_mode) {
		case OZZipFileModeUnzip: {
			int err= unzClose(_unzFile);
			if (err != UNZ_OK)
				@throw [OZZipException zipExceptionWithError:err reason:@"Error closing '%@'", _fileName];
			break;
		}
			
		case OZZipFileModeCreate: {
			int err= zipClose(_zipFile, NULL);
			if (err != ZIP_OK)
				@throw [OZZipException zipExceptionWithError:err reason:@"Error closing '%@'", _fileName];
			break;
		}
			
		case OZZipFileModeAppend: {
			int err= zipClose(_zipFile, NULL);
			if (err != ZIP_OK)
				@throw [OZZipException zipExceptionWithError:err reason:@"Error closing '%@'", _fileName];
			break;
		}

		default:
			@throw [OZZipException zipExceptionWithReason:@"Unknown mode %d", _mode];
	}
}


#pragma mark -
#pragma mark Closing (NSError variants)

- (BOOL) closeWithError:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        [self close];
        
        return YES;
        
    } ERROR_WRAP_END_AND_RETURN(error, NO);
}


#pragma mark -
#pragma mark Properties

@synthesize fileName= _fileName;
@synthesize mode= _mode;
@synthesize legacy32BitMode= _legacy32BitMode;


@end
