//
//  ViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 9/27/17.
//  Copyright © 2017 Sam Gardner. All rights reserved.
//

#import "ViewController.h"
#include <sys/sysctl.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //Gets iOS device model (ex iPhone9,1 == iPhone 7 GSM)
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithUTF8String:modelChar];
    free(modelChar);
    NSLog(@"%@",deviceModel);
    //Gets iOS version (if you need an example, maybe you should learn about iOS more before learning to develop for it)
    NSString *deviceVersion = [[UIDevice currentDevice] systemVersion];
    NSLog(@"%@",deviceVersion);
    //Gets iOS device build number (ex 10.1.1 == 14B100 or 14B150
    //Thanks, Apple, for releasing two versions of 10.1.1, you really make things hard on us.
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    char *buildChar = malloc(size);
    sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
    NSString *deviceBuild = [NSString stringWithUTF8String:buildChar];
    free(buildChar);
    NSLog(@"%@", deviceBuild);
}



@end
