//
//  OZZipReadStream.m
//  Objective-Zip v. 1.0.5
//
//  Created by Gianluca Bertani on 28/12/09.
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

#import "OZZipReadStream.h"
#import "OZZipReadStream+Standard.h"
#import "OZZipReadStream+NSError.h"
#import "OZZipReadStream+Internals.h"
#import "OZZipException.h"
#import "OZZipException+Internals.h"


#pragma mark -
#pragma mark OZZipReadStream extension

@interface OZZipReadStream () {
    NSString *_fileNameInZip;
    
@private
    unzFile _unzFile;
}


@end


#pragma mark -
#pragma mark OZZipReadStream implementation

@implementation OZZipReadStream


#pragma mark -
#pragma mark Initialization

- (instancetype) initWithUnzFileStruct:(unzFile)unzFile fileNameInZip:(NSString *)fileNameInZip {
	if (self= [super init]) {
		_unzFile= unzFile;
		_fileNameInZip= fileNameInZip;
	}
	
	return self;
}


#pragma mark -
#pragma mark Reading data

- (NSUInteger) readDataWithBuffer:(NSMutableData *)buffer {
	int err= unzReadCurrentFile(_unzFile, [buffer mutableBytes], (uInt) [buffer length]);
	if (err < 0)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error reading '%@' in the zipfile", _fileNameInZip];
	
	return err;
}

- (void) finishedReading {
	int err= unzCloseCurrentFile(_unzFile);
	if (err != UNZ_OK)
		@throw [OZZipException zipExceptionWithError:err reason:@"Error closing '%@' in the zipfile", _fileNameInZip];
}


#pragma mark -
#pragma mark Reading data (NSError variants)

- (NSInteger) readDataWithBuffer:(NSMutableData *)buffer error:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        NSUInteger bytesRead= [self readDataWithBuffer:buffer];
        return (bytesRead == 0) ? OZReadStreamResultEndOfFile : bytesRead;
        
    } ERROR_WRAP_END_AND_RETURN(error, 0);
}

- (BOOL) finishedReadingWithError:(NSError * __autoreleasing *)error {
    ERROR_WRAP_BEGIN {
        
        [self finishedReading];
        
        return YES;
        
    } ERROR_WRAP_END_AND_RETURN(error, NO);
}


@end
