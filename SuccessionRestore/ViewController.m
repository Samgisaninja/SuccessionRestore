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
    //Thanks, Apple, for releasing two versions of 10.1.1, you really like making things hard on us.
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    char *buildChar = malloc(size);
    sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
    NSString *deviceBuild = [NSString stringWithUTF8String:buildChar];
    free(buildChar);
    NSLog(@"%@", deviceBuild);
}

 - (void)viewDidAppear:(BOOL)animated {
    //Checks to see if app is in the root applications folder. Uses viewDidAppear instead of viewDidLoad because viewDidLoad doesn't like UIAlertControllers
    BOOL isRoot = [[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/SuccessionRestore.app"];
    if (isRoot == YES) {
        
    } else {
        UIAlertController *notRunningAsRoot = [UIAlertController alertControllerWithTitle:@"Succession isn't running as root" message:@"You need a jailbreak to use this app" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *exitApp = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *closeApp) {
            exit(0);
            }];
        [notRunningAsRoot addAction:exitApp];
        [self presentViewController:notRunningAsRoot animated:YES completion:nil];
    }
    
}

- (IBAction)contactSupportButton:(id)sender {
    //Opens a PM to my reddit
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/message/compose/?to=samg_is_a_ninja"]];
}

- (IBAction)donateButton:(id)sender {
    //Hey, someone actually decided to donate?! <3
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/Sam4Gardner/2"]];
}

- (IBAction)infoNotAccurateButton:(id)sender {
    //Code that runs the "Information not correct" button
    UIAlertController *infoNotAccurateButtonInfo = [UIAlertController alertControllerWithTitle:@"Please provide your own DMG" message:@"Please extract a clean IPSW for your device/iOS version and place the largest DMG file in /var/mobile/Media/Succession. On iOS 9 and older, you will need to decrypt the DMG first." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [infoNotAccurateButtonInfo addAction:okAction];
    [self presentViewController:infoNotAccurateButtonInfo animated:YES completion:nil];
}


@end
