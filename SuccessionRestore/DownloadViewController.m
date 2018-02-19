//
//  DownloadViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 2/3/18.
//  Copyright © 2018 Sam Gardner. All rights reserved.
//

#import "DownloadViewController.h"
#include <sys/sysctl.h>

@interface DownloadViewController ()

@end

@implementation DownloadViewController
@synthesize deviceBuild;
@synthesize deviceModel;
@synthesize deviceVersion;
- (void)viewDidLoad {
    [super viewDidLoad];
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startDownloadingButton:(id)sender {
    NSString *ipswAPIURLString = [NSString stringWithFormat:@"https://api.ipsw.me/v2/%@/%@/url/", deviceModel, deviceBuild];
    NSLog(@"SUCCESSIONLOG: ipswAPIURLString is %@", ipswAPIURLString);
    NSURL *ipswAPIURL = [NSURL URLWithString:ipswAPIURLString];
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                          dataTaskWithURL:ipswAPIURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                              _downloadLink = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                              NSLog(@"SUCCESSIONLOG: _downloadLink is %@", _downloadLink);
                                          }];
    [downloadTask resume];
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Succession/ipsw/" withIntermediateDirectories:NO attributes:nil error:nil];
    /* //unzips the ipsw
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
     } */
}

@end
