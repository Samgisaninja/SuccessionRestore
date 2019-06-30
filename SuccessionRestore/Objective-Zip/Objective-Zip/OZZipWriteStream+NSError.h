//
//  OZZipWriteStream+NSError.h
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

#import "OZZipWriteStream.h"


@interface OZZipWriteStream (NSError)


#pragma mark -
#pragma mark Writing data (NSError variants)

/**
 @brief Compresses and writes data to the new file in the zip file.
 <p>Data are compressed depending on the choice of compression level specified
 during creation of the write stream.</p>
 @param data The data to be compressed and written.
 @param error If passed, may be filled with an NSError is case data could
 not be written.
 @return <code>YES</code> if data has been written, <code>NO</code> if
 data could not be written due to an error.
 */
- (BOOL) writeData:(nonnull NSData *)data error:(NSError * __autoreleasing __nullable * __nullable)error;

/**
 @brief Closes the write stream.
 <p>Once you have finished writing data to the new file, it is important to
 close the stream so system resources may be freed.</p>
 <p>Note: after the stream has been closed any subsequent write will result in
 an error.</p>
 @param error If passed, may be filled with an NSError is case the stream could
 not be closed.
 @return <code>YES</code> if the stream has been closed, <code>NO</code> if
 the stream could not be closed due to an error.
 */
- (BOOL) finishedWritingWithError:(NSError * __autoreleasing __nullable * __nullable)error;


@end
