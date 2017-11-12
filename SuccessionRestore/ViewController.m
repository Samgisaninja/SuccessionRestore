//
//  ViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 9/27/17.
//  Copyright © 2017 Sam Gardner. All rights reserved.
//

#import "ViewController.h"
#include <sys/sysctl.h>
#include <CoreFoundation/CoreFoundation.h>
#include <spawn.h>
#include <sys/stat.h>
#import "NSTask.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Create a size_t and set it to the size used to allocate modelChar
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    //Gets iOS device model (ex iPhone9,1 == iPhone 7 GSM) and changes label.
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithUTF8String:modelChar];
    free(modelChar);
    self.deviceModelLabel.text = [NSString stringWithFormat:@"%@", deviceModel];
    
    //Gets iOS version (if you need an example, maybe you should learn about iOS more before learning to develop for it) and changes label.
    NSString *deviceVersion = [[UIDevice currentDevice] systemVersion];
    self.iOSVersionLabel.text = [NSString stringWithFormat:@"%@", deviceVersion];
    
    // Set size to the size used to allocate buildChar
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    
    //Gets iOS device build number (ex 10.1.1 == 14B100 or 14B150) and changes label.
    //Thanks, Apple, for releasing two versions of 10.1.1, you really like making things hard on us.
    char *buildChar = malloc(size);
    sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
    NSString *deviceBuild = [NSString stringWithUTF8String:buildChar];
    free(buildChar);
    self.iOSBuildLabel.text = [NSString stringWithFormat:@"%@", deviceBuild];
    
    //Checks to see if DMG has already been downloaded and sets features accordingly
    BOOL DMGAlreadyDownloaded = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Succession/rfs.dmg"];
    if (DMGAlreadyDownloaded == YES) {
        [_downloadDMGButton setTitle:@"Redownload clean rootfilesystem" forState:UIControlStateNormal];
        [_prepareToRestoreButton setTitle:@"Prepare to restore!" forState:UIControlStateNormal];
        [_prepareToRestoreButton setEnabled:YES];
        [_prepareToRestoreButton setUserInteractionEnabled:YES];
        [_prepareToRestoreButton setTitleColor:[UIColor colorWithRed:255.0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] forState:UIControlStateNormal];
    } else {
        [_downloadDMGButton setTitle:@"Download a clean rootfilesystem" forState:UIControlStateNormal];
        [_prepareToRestoreButton setTitle:@"Please download a rootfilesystem first" forState:UIControlStateNormal];
        [_prepareToRestoreButton setEnabled:NO];
        [_prepareToRestoreButton setUserInteractionEnabled:NO];
        [_prepareToRestoreButton setTitleColor:[UIColor colorWithRed:173.0/255.0 green:173.0/255.0 blue:173.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    }
}
/* - (void)viewDidAppear:(BOOL)animated {
    //Checks to see if app is in the root applications folder. Uses viewDidAppear instead of viewDidLoad because viewDidLoad doesn't like UIAlertControllers.
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
    
} */

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

- (IBAction)startDownloadingButton:(id)sender {
    //Creates folder to download to in case Cydia didn't make it
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Succession/ipsw-partial.ipsw"] == YES) {
        //Removes all files in /var/mobile/Media/Succession to delete partial downloads
        NSFileManager* fm = [[NSFileManager alloc] init];
        NSDirectoryEnumerator* en = [fm enumeratorAtPath:@"/var/mobile/Media/Succession"];
        NSError* err = nil;
        BOOL res;
        NSString* file;
        while (file =
               
                [en nextObject]) {
            res = [fm removeItemAtPath:[@"/var/mobile/Media/Succession" stringByAppendingPathComponent:file] error:&err];
            if (!res && err) {
                exit(0);
            }
        }
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Succession/" withIntermediateDirectories:NO attributes:nil error:nil];
    //This code should look familiar, this time instead of setting labels, the information is used to download the right file.
    // Create a size_t and set it to the size used to allocate modelChar
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    //Gets iOS device model (ex iPhone9,1 == iPhone 7 GSM) and stores as an NSString.
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithUTF8String:modelChar];
    free(modelChar);
    
    //Gets iOS version and stores as an NSString.
    NSString *deviceVersion = [[UIDevice currentDevice] systemVersion];
    
    // Set size to the size used to allocate buildChar
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    
    //Gets iOS device build number (ex 10.1.1 == 14B100 or 14B150) and stores as NSString
    //Thanks, Apple, for releasing two versions of 10.1.1, you really like making things hard on us.
    char *buildChar = malloc(size);
    sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
    NSString *deviceBuild = [NSString stringWithUTF8String:buildChar];
    free(buildChar);
    
    // API to get ipsw of any firmware with the buildid and model
    NSString *downloadLinkString = [NSString stringWithFormat:@"http://api.ipsw.me/v2/%@/%@/url/dl", deviceModel, deviceBuild];
    //Finds the documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *downloadPath = [documentsDirectory stringByAppendingString:@"/ipsw.zip"];
    //Downloads the IPSW file for the correct iOS version
    NSURL *downloadLink = [NSURL URLWithString:downloadLinkString];
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                          dataTaskWithURL:downloadLink completionHandler:^(NSData *downloadedIPSWData, NSURLResponse *response, NSError *error) {
[downloadedIPSWData writeToFile:downloadPath atomically:YES];
}];
    [downloadTask resume];
    NSLog(@"Download Complete?");
    //creates directory for the ipsw that's about to be unzipped
    
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Succession/ipsw/" withIntermediateDirectories:NO attributes:nil error:nil];
    //unzips the ipsw
    NSTask *unzipIPSW = [[NSTask alloc] init];
    [unzipIPSW setLaunchPath:@"/bin/unzip"];
    NSArray *unzipIPSWArgs = [NSArray arrayWithObjects:@"-a", @"/var/mobile/Media/Succession/ipsw.zip", @"-d", @"/var/mobile/Media/Succession/ipsw", nil];
    [unzipIPSW setArguments:unzipIPSWArgs];
    [unzipIPSW launch];
    if ([deviceModel isEqualToString:@"iPhone4,1"]) {
        
    } else {
        UIAlertController *deviceNotSupported = [UIAlertController alertControllerWithTitle:@"Device not supported" message:@"Please extract a clean IPSW for your device/iOS version and place the largest DMG file in /var/mobile/Media/Succession. On iOS 9 and older, you will need to decrypt the DMG first." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *closeApp) {
            exit(0);
        }];
        [deviceNotSupported addAction:okAction];
        [self presentViewController:deviceNotSupported animated:YES completion:nil];
    }
    //creates a bool to determine if the dmg needs to be decrypted before mounting
    BOOL needsDecryption = YES;
    //checks to see if the DMG is from an iOS 10 or later version. If so, the dmg is not encrypted
    //if (CFCoreFoundationVersionNumber > 1300) {
      //  needsDecryption = NO;}
    if (needsDecryption == YES) {
        if ([deviceModel isEqualToString:@"iPhone4,1"]) {
            if ([deviceBuild isEqualToString:@"12H321"]) {
                [[NSFileManager defaultManager] moveItemAtPath:@"/var/mobile/Media/Succession/ipsw/058-24033-023.dmg" toPath:@"/var/mobile/Media/Succession/rfs-encrypted.dmg" error:nil];
                NSTask *decryptDMG = [[NSTask alloc] init];
                [decryptDMG setLaunchPath:@"/Applications/SuccessionRestore.app/dmg"];
                NSArray *decryptDMGArgs = [NSArray arrayWithObjects:@"extract", @"/var/mobile/Media/Succession/rfs-encrypted.dmg", @"/var/mobile/Media/Successsion/rfs.dmg", @"-k", @"8fd9823be521060b9160272962fc2f65520de7b5ab55fe574953997e3ee5306d7bab5e02", nil];
                [decryptDMG setArguments:decryptDMGArgs];
                [decryptDMG launch];
            } else {
                UIAlertController *deviceNotSupported = [UIAlertController alertControllerWithTitle:@"Device not supported" message:@"Please extract a clean IPSW for your device/iOS version and place the largest DMG file in /var/mobile/Media/Succession. On iOS 9 and older, you will need to decrypt the DMG first." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *closeApp) {
                    exit(0);
                }];
                [deviceNotSupported addAction:okAction];
                [self presentViewController:deviceNotSupported animated:YES completion:nil];}
        }
    } else {
    }
}
@end
