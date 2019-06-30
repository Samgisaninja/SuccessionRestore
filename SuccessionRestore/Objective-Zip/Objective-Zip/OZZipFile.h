//
//  OZZipFile.h
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

#import <Foundation/Foundation.h>

#import "OZZipFileMode.h"
#import "OZZipCompressionLevel.h"


@class OZZipReadStream;
@class OZZipWriteStream;
@class OZFileInZipInfo;

/**
 @brief OZZipFile provides read or write access to a single zip file.
 <p> During initialization you must specify the access mode, i.e. if the zip
 file is being created, appended, or unzipped. You can also specify if the zip 
 file must be opened in legacy 32-bit mode, to be compatible with older 
 operating systems (such as some versions of Android).</p>
 <p> If the zip file has been opened in unzip mode, you can list its content,
 move within its content from file to file, and finally open a reading stream 
 of the selected file.</p>
 <p> If the zip file has been opened in creation or append mode, you can open a 
 writing stream to add new files to its content.</p>
 */
@interface OZZipFile : NSObject


#pragma mark -
#pragma mark Properties

/**
 @brief File name of the zip file.
 */
@property (nonatomic, readonly, nonnull) NSString *fileName;

/**
 @brief Access mode specified during opening. Can be:<ul>
 <li>OZZipFileModeUnzip: the zip file has been opened for reading.
 <li>OZZipFileModeCreate: the zip file has been opened for creation.
 <li>OZZipFileModeAppend: the zip file has been opened for writing.
 </ul>
 */
@property (nonatomic, readonly) OZZipFileMode mode;

/**
 @brief <code>YES</code> if the zip file has been opened in 32-bit
 compatibility mode, <code>NO</code> if it has been opened in standard
 (default) 64-bit mode.
 */
@property (nonatomic, readonly) BOOL legacy32BitMode;


@end
