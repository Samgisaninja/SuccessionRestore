//
//  ViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 9/27/17.
//  Copyright © 2017 Sam Gardner. All rights reserved.
//

#import "HomePageViewController.h"
#import "DownloadViewController.h"
#include <sys/sysctl.h>
#include <CoreFoundation/CoreFoundation.h>
#include <spawn.h>
#include <sys/stat.h>

@interface HomePageViewController ()

@end

@implementation HomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[[self navigationController] navigationBar] setHidden:TRUE];
    // Create a size_t and set it to the size used to allocate modelChar
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    //Gets iOS device model (ex iPhone9,1 == iPhone 7 GSM) and changes label.
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    _deviceModel = [NSString stringWithUTF8String:modelChar];
    free(modelChar);
    self.deviceModelLabel.text = [NSString stringWithFormat:@"%@", _deviceModel];
    
    //Gets iOS version and changes label.
    _deviceVersion = [[UIDevice currentDevice] systemVersion];
    self.iOSVersionLabel.text = [NSString stringWithFormat:@"%@", _deviceVersion];
    
    // Set size to the size used to allocate buildChar
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    
    //Gets iOS device build number (ex 10.1.1 == 14B100 or 14B150) and changes label.
    //Thanks, Apple, for releasing two versions of 10.1.1, you really like making things hard on us.
    char *buildChar = malloc(size);
    sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
    _deviceBuild = [NSString stringWithUTF8String:buildChar];
    free(buildChar);
    self.iOSBuildLabel.text = [NSString stringWithFormat:@"%@", _deviceBuild];
    
    //Checks to see if the app has ever been run before
    static NSString* const hasRunAppOnceKey = @"hasRunAppOnceKey";
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:hasRunAppOnceKey] == NO)
    {
        // If it hasn't been run before, present an alert asking the user to consider donating.
        UIAlertController *pleaseGiveMoney = [UIAlertController alertControllerWithTitle:@"Please consider donating" message:@"This product is free, and I never intend to change that, but if it works for you, I please ask you to consider donating to my paypal to support future products." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *giveMeMoney = [UIAlertAction actionWithTitle:@"Donate" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/SamGardner4"] options:URLOptions completionHandler:nil];
        }];
        UIAlertAction *giveMeMoneyLater = [UIAlertAction actionWithTitle:@"Not now" style:UIAlertActionStyleCancel handler:nil];
        [pleaseGiveMoney addAction:giveMeMoney];
        [pleaseGiveMoney addAction:giveMeMoneyLater];
        [self presentViewController:pleaseGiveMoney animated:TRUE completion:nil];
        [defaults setBool:YES forKey:hasRunAppOnceKey];
    }
}
- (void) viewDidAppear:(BOOL)animated{
    //Checks to see if DMG has already been downloaded and sets buttons accordingly
    BOOL DMGAlreadyDownloaded = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Succession/rfs.dmg"];
    if (DMGAlreadyDownloaded == TRUE) {
        [_downloadDMGButton setHidden:TRUE];
        [_prepareToRestoreButton setHidden:FALSE];
        [_prepareToRestoreButton setEnabled:TRUE];
    } else {
        [_downloadDMGButton setHidden:FALSE];
        [_prepareToRestoreButton setHidden:TRUE];
        [_prepareToRestoreButton setEnabled:FALSE];
    }
}
- (IBAction)contactSupportButton:(id)sender {
    //Opens a PM to my reddit
    NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/message/compose/?to=samg_is_a_ninja"] options:URLOptions completionHandler:nil];
}

- (IBAction)donateButton:(id)sender {
    //Hey, someone actually decided to donate?! <3
    NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/SamGardner4/2"] options:URLOptions completionHandler:nil];
}
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"deviceInfoShare"]) {
        DownloadViewController *destViewController = segue.destinationViewController;
        destViewController.deviceVersion = _deviceVersion;
        destViewController.deviceModel = _deviceModel;
        destViewController.deviceBuild = _deviceBuild;
    }
}
- (IBAction)infoNotAccurateButton:(id)sender {
    //Code that runs the "Information not correct" button
    UIAlertController *infoNotAccurateButtonInfo = [UIAlertController alertControllerWithTitle:@"Please provide your own DMG" message:@"Please extract a clean IPSW for your device/iOS version and place the largest DMG file in /var/mobile/Media/Succession. On iOS 9.3.5 and older, you will need to decrypt the DMG first." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [infoNotAccurateButtonInfo addAction:okAction];
    [self presentViewController:infoNotAccurateButtonInfo animated:YES completion:nil];
}
@end

