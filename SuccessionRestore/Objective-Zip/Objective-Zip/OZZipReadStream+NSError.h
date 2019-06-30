//
//  OZZipReadStream+NSError.h
//  Objective-Zip v. 1.0.5
//
//  Created by Gianluca Bertani on 09/09/15.
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


/**
 @brief Indicates the end of the file has been reached.
 */
static const NSInteger OZReadStreamResultEndOfFile= -1;


@interface OZZipReadStream (NSError)


#pragma mark -
#pragma mark Reading data (NSError variants)

/**
 @brief Reads and uncompresses data from the file in the zip file and stores
 them in the specified buffer.
 @param buffer The buffer where read and uncompressed data must be stored.
 @param error If passed, may be filled with an NSError is case data could
 not be read.
 @return The number of uncompressed bytes read, <code>OZReadStreamResultEndOfFile</code>
 if the end of the file has been reached, or <code>0</code>
 if data could not be read due to an error.
 <br/>NOTE: return value convention is different in the standard (non-NSError
 compliant) interface.
 */
- (NSInteger) __attribute__((swift_error(nonnull_error))) readDataWithBuffer:(nonnull NSMutableData *)buffer error:(NSError * __autoreleasing __nullable * __nullable)error;

/**
 @brief Closes the read steam.
 <p>Once you have finished read data to the file, it is important to close
 the stream so system resources may be freed.</p>
 <p>Note: after the stream has been closed any subsequent read will result in
 an error.</p>
 @param error If passed, may be filled with an NSError is case the stream could
 not be closed.
 @return <code>YES</code> if the stream has been closed, <code>NO</code> if
 the stream could not be closed due to an error.
 */
- (BOOL) finishedReadingWithError:(NSError * __autoreleasing __nullable * __nullable)error;


@end
