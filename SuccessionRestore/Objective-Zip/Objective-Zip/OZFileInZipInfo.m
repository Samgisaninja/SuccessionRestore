//
//  OZFileInZipInfo.m
//  Objective-Zip v. 1.0.5
//
//  Created by Gianluca Bertani on 27/12/09.
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

#import "OZFileInZipInfo.h"


#pragma mark -
#pragma mark OZFileInZipInfo extension

@interface OZFileInZipInfo () {
    
@private
    unsigned long long _length;
    OZZipCompressionLevel _level;
    BOOL _crypted;
    unsigned long long _size;
    NSDate *_date;
    NSUInteger _crc32;
    NSString *_name;
}


@end


#pragma mark -
#pragma mark OZFileInZipInfo implementation

@implementation OZFileInZipInfo


#pragma mark -
#pragma mark Initialization

- (instancetype) initWithName:(NSString *)name length:(unsigned long long)length level:(OZZipCompressionLevel)level crypted:(BOOL)crypted size:(unsigned long long)size date:(NSDate *)date crc32:(NSUInteger)crc32 {
	if (self= [super init]) {
		_name= name;
		_length= length;
		_level= level;
		_crypted= crypted;
		_size= size;
		_date= date;
		_crc32= crc32;
	}
	
	return self;
}


#pragma mark -
#pragma mark Properties

@synthesize name= _name;
@synthesize length= _length;
@synthesize level= _level;
@synthesize crypted= _crypted;
@synthesize size= _size;
@synthesize date= _date;
@synthesize crc32= _crc32;


@end
