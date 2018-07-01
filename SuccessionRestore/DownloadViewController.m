//
//  DownloadViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 2/3/18.
//  Copyright © 2018 Sam Gardner. All rights reserved.
//

#import "DownloadViewController.h"
#include <sys/sysctl.h>
#import "ZipArchive/ZipArchive.h"
#import "HomePageViewController.h"

@interface DownloadViewController ()

@end

@implementation DownloadViewController
@synthesize deviceBuild;
@synthesize deviceModel;
@synthesize deviceVersion;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self downloadProgressBar] setHidden:TRUE];
    self.activityLabel.text = @"";
    [[self unzipActivityIndicator] setHidden:TRUE];
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Succession/ipsw.ipsw"]) {
        UIAlertController *ipswDetected = [UIAlertController alertControllerWithTitle:@"IPSW file detected!" message:@"You can either use the IPSW file you provided at /var/mobile/Media/Succession/ipsw.ipsw or you can download a clean one. If you choose to use the IPSW you provided, and that IPSW does not match your device and version of iOS, the device will not boot after running Succession and you will be forced to restore to a signed iOS version through iTunes. Please be careful." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *useProvidedIPSW = [UIAlertAction actionWithTitle:@"Use provided IPSW" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[self unzipActivityIndicator] setHidden:FALSE];
            self.activityLabel.text = @"Unzipping...";
            [_startDownloadButton setEnabled:FALSE];
            [_startDownloadButton setTitle:@"Working, please do not leave the app..." forState:UIControlStateNormal];
            [_startDownloadButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            __weak typeof(self) weakself = self;
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [weakself postDownload];
            });
        }];
        UIAlertAction *downloadNewIPSW = [UIAlertAction actionWithTitle:@"Download a clean IPSW" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self startDownload];
        }];
        [ipswDetected addAction:useProvidedIPSW];
        [ipswDetected addAction:downloadNewIPSW];
        [self presentViewController:ipswDetected animated:TRUE completion:nil];
        
    }
}
- (IBAction)backButtonAction:(id)sender {
    [[self navigationController] popToRootViewControllerAnimated:TRUE];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startDownloadButtonAction:(id)sender {
    [_startDownloadButton setEnabled:FALSE];
    [_startDownloadButton setTitle:@"Working, please do not leave the app..." forState:UIControlStateNormal];
    [_startDownloadButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self startDownload];
}
-(void) startDownload {
    self.activityLabel.text = @"Preparing download...";
    if (kCFCoreFoundationVersionNumber < 1300) {
        UIAlertController *deviceNotSupported = [UIAlertController alertControllerWithTitle:@"Device not supported" message:@"Please extract a clean IPSW for your device/iOS version and place the largest DMG file in /var/mobile/Media/Succession. On iOS 9.3.5 and older, you will need to decrypt the DMG first." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            exit(0);
        }];
        [deviceNotSupported addAction:exitAction];
        [self presentViewController:deviceNotSupported animated:TRUE completion:nil];
    } else {
    //Removes all files in /var/mobile/Media/Succession to delete any mess from previous uses
    NSFileManager* fm = [[NSFileManager alloc] init];
        NSDirectoryEnumerator* en = [fm enumeratorAtPath:@"/var/mobile/Media/Succession"];
        NSError* error = nil;
        BOOL res;
        NSString* file;
        while (file =
               
               [en nextObject]) {
            res = [fm removeItemAtPath:[@"/var/mobile/Media/Succession" stringByAppendingPathComponent:file] error:&error];
            if (!res && error) {
                self.activityLabel.text = [NSString stringWithFormat:@"Error deleting files: %@", [error localizedDescription]];
            }
        }
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Succession/" withIntermediateDirectories:NO attributes:nil error:nil];
    self.activityLabel.text = @"Finding IPSW...";
    NSString *ipswAPIURLString = [NSString stringWithFormat:@"https://api.ipsw.me/v2/%@/%@/url/", deviceModel, deviceBuild];
    NSURL *ipswAPIURL = [NSURL URLWithString:ipswAPIURLString];
    [[self downloadProgressBar] setHidden:FALSE];
    NSURLSessionDataTask *getDownloadLinkTask = [[NSURLSession sharedSession] dataTaskWithURL:ipswAPIURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString * downloadLinkString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString * activityLabelText = [downloadLinkString stringByAppendingString:@"Found IPSW at"];
        self.activityLabel.text = activityLabelText;
        _downloadLink = [NSURL URLWithString:downloadLinkString];
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.timeoutIntervalForRequest = 12000.0;
        sessionConfig.timeoutIntervalForResource = 12000.0;
        NSURLSessionDownloadTask *task = [[NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]] downloadTaskWithURL:_downloadLink];
        [task resume];
    }];
    [getDownloadLinkTask resume];
    }
}
- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    [[self downloadProgressBar] setHidden:TRUE];
    self.activityLabel.text = @"Retrieving Download...";
    [[self unzipActivityIndicator] setHidden:FALSE];
    NSError * error;
    [[NSFileManager defaultManager] moveItemAtPath:[location path] toPath:@"/var/mobile/Media/Succession/ipsw.ipsw" error:&error];
    if (error != nil) {
        self.activityLabel.text = [NSString stringWithFormat:@"Error moving downloaded ipsw: %@", error];
    } else {
        [self postDownload];
    }
}
- (void) postDownload {
    NSError * error;
    [[NSFileManager defaultManager] moveItemAtPath:@"/var/mobile/Media/Succession/ipsw.ipsw" toPath:@"/var/mobile/Media/Succession/ipsw.zip" error:&error];
    ZipArchive * unzipIPSW = [[ZipArchive alloc] init];
    if([unzipIPSW UnzipOpenFile:@"/var/mobile/Media/Succession/ipsw.zip"]) {
        if([unzipIPSW UnzipFileTo:[@"/var/mobile/Media/Succession" stringByAppendingPathComponent:@"extracted"] overWrite:YES] != NO) {
            self.activityLabel.text = @"Cleaning up...";
                [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Succession/ipsw.zip" error:&error];
                if (error != nil) {
                    self.activityLabel.text = [NSString stringWithFormat:@"Error deleting IPSW: %@", [error localizedDescription]];
                } else {
                    self.activityLabel.text = @"Identifying rootfilesystem dmg";
                    NSArray * extractedFolderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Media/Succession/extracted/" error:&error];
                    for (int i=0; i<[extractedFolderContents count]; i++) {
                        NSString *checkingFile = [extractedFolderContents objectAtIndex:i];
                        NSString *checkingFilePath = [@"/var/mobile/Media/Succession/extracted/" stringByAppendingPathComponent:checkingFile];
                        unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:checkingFilePath error:nil] fileSize];
                        NSLog(@"Size of %@ is %llu", checkingFile, fileSize);
                        if (fileSize > 1824896633) {
                            self.activityLabel.text = [NSString stringWithFormat:@"Identified rootfilesystem as %@...", checkingFile];
                            [[NSFileManager defaultManager] moveItemAtPath:checkingFilePath toPath:@"/var/mobile/Media/Succession/rfs.dmg" error:&error];
                            self.activityLabel.text = @"Cleaning up...";
                            [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Succession/extracted/" error:&error];
                            UIAlertController *downloadComplete = [UIAlertController alertControllerWithTitle:@"Download Complete" message:@"Please relaunch the app to restore" preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *backToHomePage = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                                exit(0);
                            }];
                            [downloadComplete addAction:backToHomePage];
                            [self presentViewController:downloadComplete animated:TRUE completion:nil];
                            break;
                        }
                    }
                }
            }
            
            [unzipIPSW UnzipCloseFile];
        }
}
- (void) URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float totalSize = (totalBytesExpectedToWrite/1024)/1024.f;
    float writtenSize = (totalBytesWritten/1024)/1024.f;
    if (writtenSize < (totalSize - 0.1)) {
        self.activityLabel.text = [NSString stringWithFormat:@"Downloading IPSW: %.2f of %.2f MB", writtenSize, totalSize];
        self.downloadProgressBar.progress = (writtenSize/totalSize);
    }
    if (writtenSize > (totalSize - 0.25)) {
        self.activityLabel.text = @"Unzipping...";
        [[self downloadProgressBar] setHidden:TRUE];
        [[self unzipActivityIndicator] setHidden:FALSE];
    }
}
@end
