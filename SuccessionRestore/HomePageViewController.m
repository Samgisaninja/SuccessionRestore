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
    
    // Checks if the app has ever been run before
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"]) {
        // Present an alert asking the user to consider donating.
        UIAlertController *pleaseGiveMoney = [UIAlertController alertControllerWithTitle:@"Please consider donating" message:@"This product is free, and I never intend to change that, but if it works for you, I please ask you to consider donating to my paypal to support future products." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *giveMeMoney = [UIAlertAction actionWithTitle:@"Donate" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/SamGardner4"] options:URLOptions completionHandler:nil];
            NSURLSessionDownloadTask *getMOTDTask = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]] downloadTaskWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/Samgisaninja/samgisaninja.github.io/master/motd.plist"]];
            [getMOTDTask resume];
        }];
        UIAlertAction *giveMeMoneyLater = [UIAlertAction actionWithTitle:@"Not now" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSURLSessionDownloadTask *getMOTDTask = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]] downloadTaskWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/Samgisaninja/samgisaninja.github.io/master/motd.plist"]];
            [getMOTDTask resume];
        }];
        [pleaseGiveMoney addAction:giveMeMoney];
        [pleaseGiveMoney addAction:giveMeMoneyLater];
        [self presentViewController:pleaseGiveMoney animated:TRUE completion:nil];
    } else {
        NSURLSessionDownloadTask *getMOTDTask = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]] downloadTaskWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/Samgisaninja/samgisaninja.github.io/master/motd.plist"]];
        [getMOTDTask resume];
    }
    NSMutableDictionary *successionPrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"]];
    if (![successionPrefs objectForKey:@"dry-run"]) {
        [successionPrefs setObject:@(0) forKey:@"dry-run"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
    if (![successionPrefs objectForKey:@"update-install"]) {
        [successionPrefs setObject:@(0) forKey:@"update-install"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
    if (![successionPrefs objectForKey:@"log-file"]) {
        [successionPrefs setObject:@(0) forKey:@"log-file"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
    if (![successionPrefs objectForKey:@"delete-during"]) {
        [successionPrefs setObject:@(0) forKey:@"delete-during"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
    if (![successionPrefs objectForKey:@"create_APFS_orig-fs"]) {
        [successionPrefs setObject:@(0) forKey:@"create_APFS_orig-fs"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
    if (![successionPrefs objectForKey:@"create_APFS_succession-prerestore"]) {
        [successionPrefs setObject:@(0) forKey:@"create_APFS_succession-prerestore"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
    if (![successionPrefs objectForKey:@"advanced-unzip"]) {
        [successionPrefs setObject:@(1) forKey:@"advanced-unzip"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
    if (![successionPrefs objectForKey:@"custom_rsync_path"]) {
        [successionPrefs setObject:@"/usr/bin/rsync" forKey:@"custom_rsync_path"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
    if (![successionPrefs objectForKey:@"custom_ipsw_path"]) {
        [successionPrefs setObject:@"/var/mobile/Media/Succession/ipsw.ipsw" forKey:@"custom_ipsw_path"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
}

- (void) viewDidAppear:(BOOL)animated{
    [[[self navigationController] navigationBar] setHidden:TRUE];
    //Checks to see if DMG has already been downloaded and sets buttons accordingly
    NSDictionary *successionPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Succession/rfs.dmg"]) {
        [_downloadDMGButton setHidden:TRUE];
        [_prepareToRestoreButton setHidden:FALSE];
        [_prepareToRestoreButton setEnabled:TRUE];
        [_infoLabel setHidden:TRUE];
    } else {
        [_downloadDMGButton setHidden:FALSE];
        [_prepareToRestoreButton setHidden:TRUE];
        [_prepareToRestoreButton setEnabled:FALSE];
        [_infoLabel setHidden:FALSE];
        [_infoLabel setText:[NSString stringWithFormat:@"Please download an IPSW\nSuccession can do this automatically (press 'Download clean Filesystem' below) or you can place an IPSW in %@", [successionPrefs objectForKey:@"custom_ipsw_path"]]];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:[successionPrefs objectForKey:@"custom_ipsw_path"]]) {
        UIAlertController *ipswDetected = [UIAlertController alertControllerWithTitle:@"IPSW detected!" message:@"Please go to the download page if you'd like to use the IPSW file you provided." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
        [ipswDetected addAction:okAction];
        [self presentViewController:ipswDetected animated:TRUE completion:nil];
    } else {
        NSArray *contentsOfSuccessionFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Media/Succession/" error:nil];
        for (NSString *file in contentsOfSuccessionFolder) {
            if ([file containsString:@".ipsw"]) {
                UIAlertController *ipswDetected = [UIAlertController alertControllerWithTitle:@"IPSW detected!" message:@"Please go to the download page if you'd like to use the IPSW file you provided." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
                [ipswDetected addAction:okAction];
                [self presentViewController:ipswDetected animated:TRUE completion:nil];
            }
        }
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

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSDictionary *motd = [NSDictionary dictionaryWithContentsOfFile:[location path]];
    if ([[[motd objectForKey:@"all"] objectForKey:@"showMessage"] isEqual:@(1)]) {
        UIAlertController *motdAlert = [UIAlertController alertControllerWithTitle:@"Message" message:[[motd objectForKey:@"all"] objectForKey:@"messageContent"] preferredStyle:UIAlertControllerStyleAlert];
        if ([[[motd objectForKey:@"all"] objectForKey:@"warning"] isEqual: @(1)]) {
            if ([[[motd objectForKey:@"all"] objectForKey:@"disabled"] isEqual: @(1)]) {
                UIAlertAction *disabledAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    exit(0);
                }];
                [motdAlert addAction:disabledAction];
                [self presentViewController:motdAlert animated:TRUE completion:nil];
            } else {
                UIAlertAction *warningAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDestructive handler:nil];
                [motdAlert addAction:warningAction];
                [self presentViewController:motdAlert animated:TRUE completion:nil];
            }
            
        } else {
            UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
            [motdAlert addAction:dismissAction];
            [self presentViewController:motdAlert animated:TRUE completion:nil];
        }
    }
    if ([[[[motd objectForKey:@"successionVersions"] objectForKey:[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]] objectForKey:@"showMessage"] isEqual:@(1)]) {
        UIAlertController *motdAlert = [UIAlertController alertControllerWithTitle:@"Message" message:[[[motd objectForKey:@"successionVersions"] objectForKey:[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]] objectForKey:@"messageContent"] preferredStyle:UIAlertControllerStyleAlert];
        if ([[[[motd objectForKey:@"successionVersions"] objectForKey:[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]] objectForKey:@"warning"] isEqual: @(1)]) {
            if ([[[[motd objectForKey:@"successionVersions"] objectForKey:[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]] objectForKey:@"disabled"] isEqual: @(1)]) {
                UIAlertAction *disabledAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    exit(0);
                }];
                [motdAlert addAction:disabledAction];
                [self presentViewController:motdAlert animated:TRUE completion:nil];
            } else {
                UIAlertAction *warningAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDestructive handler:nil];
                [motdAlert addAction:warningAction];
                [self presentViewController:motdAlert animated:TRUE completion:nil];
            }
            
        } else {
            UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
            [motdAlert addAction:dismissAction];
            [self presentViewController:motdAlert animated:TRUE completion:nil];
        }
    }
    if ([[[[motd objectForKey:@"deviceModels"] objectForKey:_deviceModel] objectForKey:@"showMessage"] isEqual:@(1)]) {
        UIAlertController *motdAlert = [UIAlertController alertControllerWithTitle:@"Message" message:[NSString stringWithFormat:@"%@", [[[motd objectForKey:@"deviceModels"] objectForKey:_deviceModel] objectForKey:@"messageContent"]] preferredStyle:UIAlertControllerStyleAlert];
        if ([[[[motd objectForKey:@"deviceModels"] objectForKey:_deviceModel] objectForKey:@"warning"] isEqual: @(1)]) {
            if ([[[[motd objectForKey:@"deviceModels"] objectForKey:_deviceModel] objectForKey:@"disabled"] isEqual: @(1)]) {
                UIAlertAction *disabledAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    exit(0);
                }];
                [motdAlert addAction:disabledAction];
                [self presentViewController:motdAlert animated:TRUE completion:nil];
            } else {
                UIAlertAction *warningAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDestructive handler:nil];
                [motdAlert addAction:warningAction];
                [self presentViewController:motdAlert animated:TRUE completion:nil];
            }
            
        } else {
            UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
            [motdAlert addAction:dismissAction];
            [self presentViewController:motdAlert animated:TRUE completion:nil];
        }
    }
    if ([[[[motd objectForKey:@"iOSVersions"] objectForKey:_deviceBuild] objectForKey:@"showMessage"] isEqual:@(1)]) {
        UIAlertController *motdAlert = [UIAlertController alertControllerWithTitle:@"Message" message:[[[motd objectForKey:@"iOSVersions"] objectForKey:_deviceBuild] objectForKey:@"messageContent"] preferredStyle:UIAlertControllerStyleAlert];
        if ([[[[motd objectForKey:@"iOSVersions"] objectForKey:_deviceBuild] objectForKey:@"warning"] isEqual: @(1)]) {
            if ([[[[motd objectForKey:@"iOSVersions"] objectForKey:_deviceBuild] objectForKey:@"disabled"] isEqual: @(1)]) {
                UIAlertAction *disabledAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    exit(0);
                }];
                [motdAlert addAction:disabledAction];
                [self presentViewController:motdAlert animated:TRUE completion:nil];
            } else {
                UIAlertAction *warningAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDestructive handler:nil];
                [motdAlert addAction:warningAction];
                [self presentViewController:motdAlert animated:TRUE completion:nil];
            }
            
        } else {
            UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
            [motdAlert addAction:dismissAction];
            [self presentViewController:motdAlert animated:TRUE completion:nil];
        }
    }
}

@end

