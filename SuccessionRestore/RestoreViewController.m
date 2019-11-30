//
//  RestoreViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 11/28/19.
//  Copyright © 2019 Sam Gardner. All rights reserved.
//

#import "RestoreViewController.h"
#include <sys/sysctl.h>

@interface RestoreViewController ()

@end

@implementation RestoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //Load Preferences
    _successionPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"];
    //Get device machine ID, used several times in the future
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    _deviceModel = [NSString stringWithUTF8String:modelChar];
    free(modelChar);
    if ([_deviceModel containsString:@"iPhone"]) {
        _deviceType = @"iPhone";
    } else if ([_deviceModel containsString:@"iPad"]) {
        _deviceType = @"iPad";
    } else if ([_deviceModel containsString:@"iPod"]) {
        _deviceType = @"iPod";
    } else if ([_deviceModel containsString:@"AppleTV"]) {
        _deviceType = @"Apple TV";
    } else {
        _deviceType = @"unknown iOS device";
    }
    //Set up UI
    if ([self isMounted]) {
        [[self titleLabel] setText:@"WARNING!!!"];
        [[self subtitleLabel] setText:@"Running this tool will immediately delete all data from your device. Please make a backup of any data that you want to keep. This will also return your device to the setup screen.  A valid SIM card may be needed for activation on iPhones and cellular iPads."];
        [[self eraseButton] setTitle:[NSString stringWithFormat:@"Erase %@", _deviceType] forState:UIControlStateNormal];
        [[self eraseButton] setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [[self eraseButton] setEnabled:TRUE];
        [[self outputLabel] setHidden:TRUE];
        [[self progressIndicator] setHidden:TRUE];
        [[self restoreProgressBar] setHidden:TRUE];
    } else {
        [[self titleLabel] setText:@"Attaching..."];
        [[self subtitleLabel] setText:@"This should take less than 10 seconds"];
        [[self eraseButton] setTitle:@"Please Wait..." forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [[self eraseButton] setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
        } else {
            [[self eraseButton] setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
        }
        [[self outputLabel] setHidden:TRUE];
        [[self progressIndicator] setHidden:TRUE];
        [[self restoreProgressBar] setHidden:TRUE];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    
}

- (IBAction)tappedRestoreButton:(id)sender {
    
}

-(BOOL)isMounted{
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
        return TRUE;
    } else {
        return FALSE;
    }
}

@end
