//
//  OZZipException.h
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

extern const NSInteger OZ_ERROR_NO_SUCH_FILE;


/**
 @brief OZZipException is a custom exception type to quickly discern between
 error originated during the zip/unzip process or elsewhere.
 </p>All exceptions thrown by Objective-Zip are of OZZipException type.</p>
 */
@interface OZZipException : NSException 


#pragma mark -
#pragma mark Properties

/**
 @brief Underlying error code provided by MiniZip/ZLib libraries. May be
 <code>0</code> if the exception originated in the Objective-Zip layer.
 <p>Common error codes are:<ul>
 <li>-1: System error.
 <li>-103: Bad zip file.
 <li>-104: Internal error.
 <li>-105: CRC error.
 </ul></p>
 */
@property (nonatomic, readonly) NSInteger error;


@end
