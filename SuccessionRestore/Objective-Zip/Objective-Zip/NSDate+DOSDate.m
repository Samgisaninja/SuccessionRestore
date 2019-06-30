//
//  NSDate+DOSDate.m
//  Objective-Zip v. 1.0.5
//
//  Created by Gianluca Bertani on 13/05/2017.
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

#import "NSDate+DOSDate.h"


@implementation NSDate (DOSDate)


#pragma mark -
#pragma mark Conversion to/from 32 bit DOS date format

- (uint32_t) dosDate {
    NSCalendar *calendar= [NSCalendar currentCalendar];
    NSDateComponents *date= [calendar components:(NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:self];
    
    return (((uint32_t)[date day] + (32 * (uint32_t)[date month]) + (512 * ((uint32_t)[date year] - 1980))) << 16) |
        (((uint32_t)[date second] / 2) + (32 * (uint32_t)[date minute]) + (2048 * (uint32_t)[date hour]));
}

+ (NSDate *) fromDosDate:(uint32_t)dosDate {
    uint64_t date= (uint64_t)(dosDate >> 16);
    
    NSDateComponents *components= [[NSDateComponents alloc] init];
    [components setDay:date & 0x1f];
    [components setMonth:(date & 0x1E0) / 0x20];
    [components setYear:((date & 0x0FE00) / 0x0200) + 1980];
    [components setHour:(dosDate & 0xF800) / 0x800];
    [components setMinute:(dosDate & 0x7E0) / 0x20];
    [components setSecond:2 * (dosDate & 0x1f)];
    
    NSCalendar *calendar= [NSCalendar currentCalendar];
    return [calendar dateFromComponents:components];
}


@end
