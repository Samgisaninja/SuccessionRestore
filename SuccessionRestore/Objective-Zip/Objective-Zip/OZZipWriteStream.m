//
//  OZZipWriteStream.m
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

#import "OZZipWriteStream.h"
#import "OZZipWriteStream+Standard.h"
#import "OZZipWriteStream+NSError.h"
#import "OZZipWriteStream+Internals.h"
#import "OZZipException.h"
#import "OZZipException+Internals.h"


#pragma mark -
#pragma mark OZZipWriteStream extension

@interface OZZipWriteStream () {
    NSString *_fileNameInZip;
    
@private
    zipFile _zipFile;
}


@end


#pragma mark -
#pragma mark OZZipWriteStream implementation

@implementation OZZipWriteStream


#pragma mark -
#pragma mark Initialization

- (instancetype) initWithZipFileStruct:(zipFile)zipFile fileNameInZip:(NSString *)fileNameInZip {
	if (self= [super init]) {
		_zipFile= zipFile;
		_fileNameInZip= fileNameInZip;
	}
	
	return self;
}


#pragma mark -
#pragma mark Writing data

- (void) writeData:(NSData *)data {
	int err= zipWriteInFileInZip(_zipFile, [data bytes], (uInt) [data length]);
	if (err < 0)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error writing '%@' in the zipfile", _fileNameInZip];
}

- (void) finishedWriting {
	int err= zipCloseFileInZip(_zipFile);
	if (err != ZIP_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error closing '%@' in the zipfile", _fileNameInZip];
}


#pragma mark -
#pragma mark Writing data (NSError variants)

- (BOOL) writeData:(NSData *)data error:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        [self writeData:data];
        
        return YES;
        
    } ERROR_WRAP_END_AND_RETURN(error, NO);
}

- (BOOL) finishedWritingWithError:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        [self finishedWriting];
        
        return YES;
        
    } ERROR_WRAP_END_AND_RETURN(error, NO);
}


@end
