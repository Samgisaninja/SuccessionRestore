//
//  OZZipException.m
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

#import "OZZipException.h"


#pragma mark -
#pragma mark OZZipException extension

@interface OZZipException () {
    
@private
    NSInteger _error;
}


@end


#pragma mark -
#pragma mark OZZipException constants

const NSInteger OZ_ERROR_NO_SUCH_FILE= -9001;


#pragma mark -
#pragma mark OZZipException implementation

@implementation OZZipException


#pragma mark -
#pragma mark Initialization

+ (OZZipException *) zipExceptionWithReason:(NSString *)format, ... {

    // Variable arguments formatting
    va_list arguments;
    va_start(arguments, format);
    NSString *reason= [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    
    return [[OZZipException alloc] initWithReason:reason];
}

+ (OZZipException *) zipExceptionWithError:(NSInteger)error reason:(NSString *)format, ... {
    
    // Variable arguments formatting
    va_list arguments;
    va_start(arguments, format);
    NSString *reason= [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    
    return [[OZZipException alloc] initWithError:error reason:reason];
}

- (instancetype) initWithReason:(NSString *)reason {
	if (self= [super initWithName:@"OZZipException" reason:reason userInfo:nil]) {
		_error= 0;
	}
	
	return self;
}

- (instancetype) initWithError:(NSInteger)error reason:(NSString *)reason {
	if (self= [super initWithName:@"OZZipException" reason:reason userInfo:nil]) {
		_error= error;
	}
	
	return self;
}


#pragma mark -
#pragma mark Properties

@synthesize error= _error;


@end
