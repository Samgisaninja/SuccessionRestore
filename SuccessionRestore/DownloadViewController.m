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
#import <MessageUI/MFMailComposeViewController.h>

@interface DownloadViewController ()

@end

@implementation DownloadViewController
@synthesize deviceBuild;
@synthesize deviceModel;
@synthesize deviceVersion;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Set up UI
    [[self downloadProgressBar] setHidden:TRUE];
    self.activityLabel.text = @"";
    [[self unzipActivityIndicator] setHidden:TRUE];
    // This creates a font that is 'monospaced', (each character is the same width). This font is later used for the download progress label, since that label is rapidly updated, monospacing the font makes it readable.
    UIFont *systemFont = [UIFont systemFontOfSize:17];
    UIFontDescriptor *monospacedNumberFontDescriptor = [systemFont.fontDescriptor fontDescriptorByAddingAttributes: @{UIFontDescriptorFeatureSettingsAttribute: @[@{UIFontFeatureTypeIdentifierKey: @6, UIFontFeatureSelectorIdentifierKey: @0}]}];
    _monospacedNumberSystemFont = [UIFont fontWithDescriptor:monospacedNumberFontDescriptor size:0];
    // Load preferences
    NSDictionary *successionPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"];
    // Read contents of succession folder
    NSArray *successionFolderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Media/Succession/" error:nil];
    // Check to see if the user has provided their own IPSW, and if so, offer to extract it instead of downloading one
    if ([[NSFileManager defaultManager] fileExistsAtPath:[successionPrefs objectForKey:@"custom_ipsw_path"]]) {
        UIAlertController *ipswDetected = [UIAlertController alertControllerWithTitle:@"IPSW file detected!" message:[NSString stringWithFormat:@"You can either use the IPSW file you provided at %@ or you can download a clean one. If you choose to use the IPSW you provided, and that IPSW does not match your device and version of iOS, the device will not boot after running Succession and you will be forced to restore to a signed iOS version through iTunes. Please be careful.", [successionPrefs objectForKey:@"custom_ipsw_path"]] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *useProvidedIPSW = [UIAlertAction actionWithTitle:@"Use provided IPSW" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // If the user taps 'Use provided IPSW, this code is run. I do not understand why 'weakself' is necessary, I believe uroboro suggested I use it because of some memory issue(?) Anyways...
            [[self unzipActivityIndicator] setHidden:FALSE];
            self.activityLabel.text = @"Unzipping...";
            [self->_startDownloadButton setEnabled:FALSE];
            [self->_startDownloadButton setTitle:@"Working, please do not leave the app..." forState:UIControlStateNormal];
            [self->_startDownloadButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            __weak typeof(self) weakself = self;
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                // executes the code under -(void)postDownload
                [weakself postDownload];
            });
        }];
        UIAlertAction *downloadNewIPSW = [UIAlertAction actionWithTitle:@"Download a clean IPSW" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            // Sets up UI for downloading and executes the code under -(void)startDownload. The "self->" is there to shut up an Xcode warning, if Xcode warns you about this in your project, you should probably add it.
            [self->_startDownloadButton setEnabled:FALSE];
            [self->_startDownloadButton setTitle:@"Working, please do not leave the app..." forState:UIControlStateNormal];
            [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];
            [self->_startDownloadButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [self startDownload];
        }];
        [ipswDetected addAction:useProvidedIPSW];
        [ipswDetected addAction:downloadNewIPSW];
        [self presentViewController:ipswDetected animated:TRUE completion:nil];
    } else {
        for (NSString *file in successionFolderContents) {
            if ([file containsString:@".ipsw"]) {
                UIAlertController *possibleIPSWMatchAlert = [UIAlertController alertControllerWithTitle:@"IPSW File Detected" message:[NSString stringWithFormat:@"I found an IPSW file, %@, would you like to move this IPSW to %@ and use it to restore?", file, [successionPrefs objectForKey:@"custom_ipsw_path"]] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *moveIPSW = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Use %@", file] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSString *successionFolder = @"/var/mobile/Media/Succession/";
                    [[NSFileManager defaultManager] moveItemAtPath:[successionFolder stringByAppendingPathComponent:file] toPath:[successionPrefs objectForKey:@"custom_ipsw_path"] error:nil];
                    [[self navigationController] popToRootViewControllerAnimated:TRUE];
                }];
                UIAlertAction *downloadIPSW = [UIAlertAction actionWithTitle:@"Download IPSW from Apple" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    // Sets up UI for downloading and executes the code under -(void)startDownload. The "self->" is there to shut up an Xcode warning, if Xcode warns you about this in your project, you should probably add it.
                    [self->_startDownloadButton setEnabled:FALSE];
                    [self->_startDownloadButton setTitle:@"Working, please do not leave the app..." forState:UIControlStateNormal];
                    [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];
                    [self->_startDownloadButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
                    [self startDownload];
                }];
                [possibleIPSWMatchAlert addAction:moveIPSW];
                [possibleIPSWMatchAlert addAction:downloadIPSW];
                [self presentViewController:possibleIPSWMatchAlert animated:TRUE completion:nil];
            }
        }
    }
}

- (IBAction)backButtonAction:(id)sender {
    // Go back to the home page
    [[self navigationController] popToRootViewControllerAnimated:TRUE];
}

- (IBAction)startDownloadButtonAction:(id)sender {
    // Set Up UI and run code under -(void)startDownload
    [_startDownloadButton setEnabled:FALSE];
    [_startDownloadButton setTitle:@"Working, please do not leave the app..." forState:UIControlStateNormal];
    [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];
    [_startDownloadButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self startDownload];
}

-(void) startDownload {
    self.activityLabel.text = @"Preparing download...";
    // If the iOS version is older than iOS 10, the root filesystem DMG is encrypted. Succession does not currently have support for decrypting DMGs, so ask the user to do it for us.
    if (kCFCoreFoundationVersionNumber < 1300) {
        UIAlertController *deviceNotSupported = [UIAlertController alertControllerWithTitle:@"Device not supported" message:@"Please extract a clean IPSW for your device/iOS version and place the largest DMG file in /var/mobile/Media/Succession. On iOS 9.3.5 and older, you will need to decrypt the DMG first." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            exit(0);
        }];
        [deviceNotSupported addAction:exitAction];
        [self presentViewController:deviceNotSupported animated:TRUE completion:nil];
    } else {
    // Removes all files in /var/mobile/Media/Succession to delete any mess from previous uses
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
    // Deletes partial downloads in Succession's sandbox folder
    NSString *tmpDir = NSTemporaryDirectory();
    [[NSFileManager defaultManager] removeItemAtPath:tmpDir error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpDir withIntermediateDirectories:TRUE attributes:nil error:nil];
    // Creates /var/mobile/Media/Succession in case dpkg didn't do so, or if the user deleted it
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Succession/" withIntermediateDirectories:TRUE attributes:nil error:nil];
    self.activityLabel.text = @"Finding IPSW...";
        if ([[[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ReleaseType"] isEqualToString:@"Beta"]) {
            [[self downloadProgressBar] setHidden:FALSE];
            NSString * betaDownloadLink = [NSURL URLWithString:@"https://raw.githubusercontent.com/Samgisaninja/SuccessionRestore/master/beta.plist"];
            // update the UI, but unless the user has a really really slow device, they probably won't ever see this:
            NSString * activityLabelText = [NSString stringWithFormat:@"Getting beta plist"];
            self.activityLabel.text = activityLabelText;
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            // set the timeout for the download request to 200 minutes (12000 seconds), that should be enough time, eh?
            sessionConfig.timeoutIntervalForRequest = 12000.0;
            sessionConfig.timeoutIntervalForResource = 12000.0;
            // define a download task with the custom timeout and download link
            NSURLSessionDownloadTask *getBetaTask = [[NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]] downloadTaskWithURL:betaDownloadLink];
            // start the beta plist download task. NSURLSessionDownloadTasks call
            //
            // "-(void) URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite"
            //
            // frequently throughout the download process, which is where my code for updating the UI is. They also call
            //
            // - (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
            //
            // when finished, which is where I have my code for what to do once the download is finished
            [getBetaTask resume];
        } else {
            // ipsw.me has an API that provides the apple download link to an ipsw for a specific device/iOS build number. If you want, you can try this, typing https://api.ipsw.me/v2/iPhone10,3/16C104/url/ into a web broswer returns http://updates-http.cdn-apple.com/2018FallFCS/fullrestores/041-28434/A2958D62-02EA-11E9-9292-C8F3416D60E4/iPhone10,3,iPhone10,6_12.1.2_16C104_Restore.ipsw
            NSString *ipswAPIURLString = [NSString stringWithFormat:@"https://api.ipsw.me/v2/%@/%@/url/", deviceModel, deviceBuild];
            // to use the API mentioned above, I create a string that incorporates the iOS buildnumber and device model, then it is converted into an NSURL...
            NSURL *ipswAPIURL = [NSURL URLWithString:ipswAPIURLString];
            // and after a little UI config...
            [[self downloadProgressBar] setHidden:FALSE];
            // the request is made, and the string received from ipsw.me is passed to an NSData object called 'data' in the completion handler. Note that the request is created below, but it is not actually run until [getDownloadLinkTask resume];
            NSURLSessionDataTask *getDownloadLinkTask = [[NSURLSession sharedSession] dataTaskWithURL:ipswAPIURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                // so now we have a direct link to where apple is hosting the IPSW for the user's device/firmware, but it's in a rather useless NSData object, so let's convet that to an NSString
                NSString * downloadLinkString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                // update the UI, but unless the user has a really really slow device, they probably won't ever see this:
                NSString * activityLabelText = [NSString stringWithFormat:@"Found IPSW at %@", downloadLinkString];
                self.activityLabel.text = activityLabelText;
                // now we reference _downloadLink, created in DownloadViewController.h, and set it equal to the NSURL version of the string we received from ipsw.me
                self->_downloadLink = [NSURL URLWithString:downloadLinkString];
                NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
                // set the timeout for the download request to 200 minutes (12000 seconds), that should be enough time, eh?
                sessionConfig.timeoutIntervalForRequest = 12000.0;
                sessionConfig.timeoutIntervalForResource = 12000.0;
                // define a download task with the custom timeout and download link
                NSURLSessionDownloadTask *task = [[NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]] downloadTaskWithURL:self->_downloadLink];
                // start the ipsw download task. NSURLSessionDownloadTasks call
                //
                // "-(void) URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite"
                //
                // frequently throughout the download process, which is where my code for updating the UI is. They also call
                //
                // - (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
                //
                // when finished, which is where I have my code for what to do once the download is finished
                [task resume];
            }];
            [getDownloadLinkTask resume];
        }
    }
}

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    // so this method gets executed when "a download finished, and it's located at the NSString returned by [location path]". This presents the problem of, "well, was it a beta version, and it just downloaded the beta information plist from my github, or did it just finish downloading an IPSW?". The filename and extension are not preserved, so the best way I could think of to determine which was to check if the file was big (IPSW) or small (plist).
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:[location path] error:nil] fileSize];
    // the smallest IPSW ever to exist, the iPhone 2G on iPhone OS 1.0, was a whopping 96 MB (wow). This is tiny by today's standards of 3GB IPSWs (and that number continues to grow with each update), but 96 MB is still massive compared to the beta plist.
    if (fileSize < 96000000) {
        // Create a dictionary with the contents of the downloaded plist
        NSDictionary *betaLinks = [NSDictionary dictionaryWithContentsOfFile:[location path]];
        // If the beta plist contains the device's build number...
        if ([betaLinks objectForKey:deviceBuild]) {
            // and the build number has the device's hardware...
            if ([[betaLinks objectForKey:deviceBuild] objectForKey:deviceModel]) {
                // then get the matching link.
                NSString *downloadLinkString = [NSString stringWithFormat:@"%@", [[betaLinks objectForKey:deviceBuild] objectForKey:deviceModel]];
                NSString * activityLabelText = [NSString stringWithFormat:@"Found IPSW at %@", downloadLinkString];
                self.activityLabel.text = activityLabelText;
                // now we reference _downloadLink, created in DownloadViewController.h, and set it equal to the NSURL version of the string we received from ipsw.me
                _downloadLink = [NSURL URLWithString:downloadLinkString];
                NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
                // set the timeout for the download request to 200 minutes (12000 seconds), that should be enough time, eh?
                sessionConfig.timeoutIntervalForRequest = 12000.0;
                sessionConfig.timeoutIntervalForResource = 12000.0;
                // define a download task with the custom timeout and download link
                NSURLSessionDownloadTask *task = [[NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]] downloadTaskWithURL:self->_downloadLink];
                [task resume];
            } else {
                // if the device's model isn't in the beta list, then present an alert with an action to send an email to me requesting beta support
                UIAlertController *requestBetaSupportAlert = [UIAlertController alertControllerWithTitle:@"Your device is not currently supported" message:@"Please send an email with your device model and iOS build number to stgardner4@att.net request support" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
                [requestBetaSupportAlert addAction:dismissAction];
                // check to see if the device can send email using the stock mail app
                if ([MFMailComposeViewController canSendMail]) {
                    UIAlertAction *sendMailAction = [UIAlertAction actionWithTitle:@"Send email" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        MFMailComposeViewController* composeVC = [[MFMailComposeViewController alloc] init];
                        composeVC.mailComposeDelegate = self;
                        [composeVC setToRecipients:@[@"stgardner4@att.net"]];
                        [composeVC setSubject:@"Succession: Add beta support request"];
                        [composeVC setMessageBody:[NSString stringWithFormat:@"%@\n%@", self->deviceBuild, self->deviceModel] isHTML:NO];
                        [self presentViewController:composeVC animated:YES completion:nil];
                    }];
                    [requestBetaSupportAlert addAction:sendMailAction];
                }
                [self presentViewController:requestBetaSupportAlert animated:TRUE completion:nil];
            }
        } else {
            UIAlertController *requestBetaSupportAlert = [UIAlertController alertControllerWithTitle:@"Your device is not currently supported" message:@"Please send an email with your device model and iOS build number to stgardner4@att.net request support" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
            [requestBetaSupportAlert addAction:dismissAction];
            if ([MFMailComposeViewController canSendMail]) {
                UIAlertAction *sendMailAction = [UIAlertAction actionWithTitle:@"Send email" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    MFMailComposeViewController* composeVC = [[MFMailComposeViewController alloc] init];
                    composeVC.mailComposeDelegate = self;
                    [composeVC setToRecipients:@[@"stgardner4@att.net"]];
                    [composeVC setSubject:@"Succession: Add beta support request"];
                    [composeVC setMessageBody:[NSString stringWithFormat:@"%@\n%@", self->deviceBuild, self->deviceModel] isHTML:NO];
                    [self presentViewController:composeVC animated:YES completion:nil];
                }];
                [requestBetaSupportAlert addAction:sendMailAction];
            }
            [self presentViewController:requestBetaSupportAlert animated:TRUE completion:nil];
        }
    } else {
        // so, the IPSW download is now complete, but it's in... well we don't really know. but iOS knows! to be specific, it exists at [location path]. [location path] is not nearly as easy to work with as /var/mobile/Media/Succession/ipsw.ipsw, so let's move it there.
        [[self downloadProgressBar] setHidden:TRUE];
        self.activityLabel.text = @"Retrieving Download...";
        [[self unzipActivityIndicator] setHidden:FALSE];
        NSError * error;
        // NSFileManager lets us do pretty much anything with files, and also, if there's an error, error information will be stored in the NSError object I created above.
        [[NSFileManager defaultManager] moveItemAtPath:[location path] toPath:@"/var/mobile/Media/Succession/ipsw.ipsw" error:&error];
        // I've never come across an error with this, but it's better to have error handling than to... not. Assuming there's no error, continue on to -(void)postDownload
        if (error != nil) {
            self.activityLabel.text = [NSString stringWithFormat:@"Error moving downloaded ipsw: %@", error];
        } else {
            [self postDownload];
        }
    }
}

- (void) postDownload {
    NSError * error;
    NSDictionary *successionPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"];
    // Rename the ipsw.ipsw file to ipsw.zip. Imagine you're using an `mv` command via terminal to rename something. It's the same concept.
    [[NSFileManager defaultManager] moveItemAtPath:[successionPrefs objectForKey:@"custom_ipsw_path"] toPath:@"/var/mobile/Media/Succession/ipsw.zip" error:&error];
    // ZipArchive was a library that I found on cocoapods, AFAIK iOS does not have it's own archive (de)compression tools, so I had to import one. Hence the #import "ZipArchive/ZipArchive.h".
    // Create a zipArchive object
    ZipArchive * unzipIPSW = [[ZipArchive alloc] init];
    // This is a really really long and probably overwhelming-looking chain of if statements, but basically, if any of them fail, it will return false and not continue to execute.
    // Tells unzipIPSW that it needs to operate on /var/mobile/Media/Succession/ipsw.zip
    if([unzipIPSW UnzipOpenFile:@"/var/mobile/Media/Succession/ipsw.zip"]) {
        // Tells unzipIPSW that it needs to extract to /var/mobile/Media/Succession/extracted
        if([unzipIPSW UnzipFileTo:[@"/var/mobile/Media/Succession" stringByAppendingPathComponent:@"extracted"] overWrite:YES] != NO) {
            // extraction complete, update UI to reflect this
            self.activityLabel.text = @"Cleaning up...";
            // delete the compressed IPSW to save space on device
                [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Succession/ipsw.zip" error:&error];
            // if error does not equal nil? not sure why I did that but ok I guess. anyways, if there's no error, it continues on.
                if (error != nil) {
                    self.activityLabel.text = [NSString stringWithFormat:@"Error deleting IPSW: %@", [error localizedDescription]];
                } else {
                    // Now we verify if the IPSW that's just been extracted actually matches the device/version that it's being downloaded to
                    NSDictionary *IPSWBuildManifest = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Media/Succession/extracted/BuildManifest.plist"];
                    if ([[IPSWBuildManifest objectForKey:@"ProductBuildVersion"] isEqualToString:deviceBuild]) {
                        if ([[IPSWBuildManifest objectForKey:@"SupportedProductTypes"] containsObject:deviceModel]) {
                            NSError *error;
                            self.activityLabel.text = @"Identifying rootfilesystem dmg";
                            // Create an array with the contents of the folder that the ipsw was extracted to.
                            NSArray * extractedFolderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Media/Succession/extracted/" error:&error];
                            // yay, for loops. so how this works: In the first argument of the for loop, I create an integer, "i" (i is for Index), which has starting value of 0. All of the code inside the for loop is executed with i equal to zero. When control reaches the end of what's inside the for loop, it reads the third argument (in this case, "i++". The "i++" means "add one to i", so then the entire for loop is run with i equal to 1. The next time it is executed it runs with i equal to 2, and so on.
                            // You might be wondering, "how do for loops ever stop?" That's where the second argument comes in, every time 1 is added to i, it checks to see if i matches the condition in the second argument. In this case, I have it set so that the for loop will run if i is less than the number of files in the 'extracted' folder. As soon as i is greater than or equal to the number of files in the extracted folder, the loop exits.
                            for (int i=0; i<[extractedFolderContents count]; i++) {
                                // Gets the name of the file that's currently being checked
                                NSString *checkingFile = [extractedFolderContents objectAtIndex:i];
                                // Get the path to that file
                                NSString *checkingFilePath = [@"/var/mobile/Media/Succession/extracted/" stringByAppendingPathComponent:checkingFile];
                                // Get the size of the file at that path
                                unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:checkingFilePath error:nil] fileSize];
                                // if the file size is greater than 1824896633 bytes (1.8 gigabytes), then we can safely assume that it is the root filesystem.
                                if (fileSize > 1824896633) {
                                    // Again, no one will ever see this, but it's there
                                    self.activityLabel.text = [NSString stringWithFormat:@"Identified rootfilesystem as %@...", checkingFile];
                                    // Move the root filesystem dmg to /var/mobile/Media/Succession/rfs.dmg
                                    [[NSFileManager defaultManager] moveItemAtPath:checkingFilePath toPath:@"/var/mobile/Media/Succession/rfs.dmg" error:&error];
                                    self.activityLabel.text = @"Cleaning up...";
                                    // Delete everything else
                                    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Succession/extracted/" error:&error];
                                    // Let the user know that download is now complete
                                    UIAlertController *downloadComplete = [UIAlertController alertControllerWithTitle:@"Download Complete" message:@"The rootfilesystem was successfully extracted to /var/mobile/Media/Succession/rfs.dmg" preferredStyle:UIAlertControllerStyleAlert];
                                    UIAlertAction *backToHomePage = [UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                        [[self navigationController] popToRootViewControllerAnimated:TRUE];
                                    }];
                                    [downloadComplete addAction:backToHomePage];
                                    [self presentViewController:downloadComplete animated:TRUE completion:nil];
                                    // Tell the for loop to stop executing now instead of waiting for the i<[extractedFolderContents count] condition to be met.
                                    break;
                                }
                            }
                        } else {
                            UIAlertController *ipswDoesntMatch = [UIAlertController alertControllerWithTitle:@"Provided IPSW does not appear to match this device" message:@"The IPSW you provided does not appear to match this device/iOS version. You may override this warning, but it is strongly reccommended that you do not continue." preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Delete and Exit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                NSFileManager* fm = [[NSFileManager alloc] init];
                                NSDirectoryEnumerator* en = [fm enumeratorAtPath:@"/var/mobile/Media/Succession"];
                                NSError* error = nil;
                                BOOL res;
                                NSString* file;
                                while (file = [en nextObject]) {
                                    res = [fm removeItemAtPath:[@"/var/mobile/Media/Succession" stringByAppendingPathComponent:file] error:&error];
                                    if (!res && error) {
                                        self.activityLabel.text = [NSString stringWithFormat:@"Error deleting files: %@", [error localizedDescription]];
                                    }
                                }
                                exit(0);
                            }];
                            UIAlertAction *overrideAction = [UIAlertAction actionWithTitle:@"Override" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                                NSError *error;
                                self.activityLabel.text = @"Identifying rootfilesystem dmg";
                                // Create an array with the contents of the folder that the ipsw was extracted to.
                                NSArray * extractedFolderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Media/Succession/extracted/" error:&error];
                                // yay, for loops. so how this works: In the first argument of the for loop, I create an integer, "i" (i is for Index), which has starting value of 0. All of the code inside the for loop is executed with i equal to zero. When control reaches the end of what's inside the for loop, it reads the third argument (in this case, "i++". The "i++" means "add one to i", so then the entire for loop is run with i equal to 1. The next time it is executed it runs with i equal to 2, and so on.
                                // You might be wondering, "how do for loops ever stop?" That's where the second argument comes in, every time 1 is added to i, it checks to see if i matches the condition in the second argument. In this case, I have it set so that the for loop will run if i is less than the number of files in the 'extracted' folder. As soon as i is greater than or equal to the number of files in the extracted folder, the loop exits.
                                for (int i=0; i<[extractedFolderContents count]; i++) {
                                    // Gets the name of the file that's currently being checked
                                    NSString *checkingFile = [extractedFolderContents objectAtIndex:i];
                                    // Get the path to that file
                                    NSString *checkingFilePath = [@"/var/mobile/Media/Succession/extracted/" stringByAppendingPathComponent:checkingFile];
                                    // Get the size of the file at that path
                                    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:checkingFilePath error:nil] fileSize];
                                    // if the file size is greater than 1824896633 bytes (1.8 gigabytes), then we can safely assume that it is the root filesystem.
                                    if (fileSize > 1824896633) {
                                        // Again, no one will ever see this, but it's there
                                        self.activityLabel.text = [NSString stringWithFormat:@"Identified rootfilesystem as %@...", checkingFile];
                                        // Move the root filesystem dmg to /var/mobile/Media/Succession/rfs.dmg
                                        [[NSFileManager defaultManager] moveItemAtPath:checkingFilePath toPath:@"/var/mobile/Media/Succession/rfs.dmg" error:&error];
                                        self.activityLabel.text = @"Cleaning up...";
                                        // Delete everything else
                                        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Succession/extracted/" error:&error];
                                        // Let the user know that download is now complete
                                        UIAlertController *downloadComplete = [UIAlertController alertControllerWithTitle:@"Download Complete" message:@"The rootfilesystem was successfully extracted to /var/mobile/Media/Succession/rfs.dmg" preferredStyle:UIAlertControllerStyleAlert];
                                        UIAlertAction *backToHomePage = [UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                            [[self navigationController] popToRootViewControllerAnimated:TRUE];
                                        }];
                                        [downloadComplete addAction:backToHomePage];
                                        [self presentViewController:downloadComplete animated:TRUE completion:nil];
                                        // Tell the for loop to stop executing now instead of waiting for the i<[extractedFolderContents count] condition to be met.
                                        break;
                                    }
                                }
                            }];
                            [ipswDoesntMatch addAction:cancelAction];
                            [ipswDoesntMatch addAction:overrideAction];
                            [self presentViewController:ipswDoesntMatch animated:TRUE completion:nil];
                        }
                    } else {
                        UIAlertController *ipswDoesntMatch = [UIAlertController alertControllerWithTitle:@"Provided IPSW does not appear to match this device" message:@"The IPSW you provided does not appear to match this device/iOS version. You may override this warning, but it is strongly reccommended that you do not continue." preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Delete and Exit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            NSFileManager* fm = [[NSFileManager alloc] init];
                            NSDirectoryEnumerator* en = [fm enumeratorAtPath:@"/var/mobile/Media/Succession"];
                            NSError* error = nil;
                            BOOL res;
                            NSString* file;
                            while (file = [en nextObject]) {
                                res = [fm removeItemAtPath:[@"/var/mobile/Media/Succession" stringByAppendingPathComponent:file] error:&error];
                                if (!res && error) {
                                    self.activityLabel.text = [NSString stringWithFormat:@"Error deleting files: %@", [error localizedDescription]];
                                }
                            }
                            exit(0);
                        }];
                        UIAlertAction *overrideAction = [UIAlertAction actionWithTitle:@"Override" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                            NSError *error;
                            self.activityLabel.text = @"Identifying rootfilesystem dmg";
                            // Create an array with the contents of the folder that the ipsw was extracted to.
                            NSArray * extractedFolderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Media/Succession/extracted/" error:&error];
                            // yay, for loops. so how this works: In the first argument of the for loop, I create an integer, "i" (i is for Index), which has starting value of 0. All of the code inside the for loop is executed with i equal to zero. When control reaches the end of what's inside the for loop, it reads the third argument (in this case, "i++". The "i++" means "add one to i", so then the entire for loop is run with i equal to 1. The next time it is executed it runs with i equal to 2, and so on.
                            // You might be wondering, "how do for loops ever stop?" That's where the second argument comes in, every time 1 is added to i, it checks to see if i matches the condition in the second argument. In this case, I have it set so that the for loop will run if i is less than the number of files in the 'extracted' folder. As soon as i is greater than or equal to the number of files in the extracted folder, the loop exits.
                            for (int i=0; i<[extractedFolderContents count]; i++) {
                                // Gets the name of the file that's currently being checked
                                NSString *checkingFile = [extractedFolderContents objectAtIndex:i];
                                // Get the path to that file
                                NSString *checkingFilePath = [@"/var/mobile/Media/Succession/extracted/" stringByAppendingPathComponent:checkingFile];
                                // Get the size of the file at that path
                                unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:checkingFilePath error:nil] fileSize];
                                // if the file size is greater than 1824896633 bytes (1.8 gigabytes), then we can safely assume that it is the root filesystem.
                                if (fileSize > 1824896633) {
                                    // Again, no one will ever see this, but it's there
                                    self.activityLabel.text = [NSString stringWithFormat:@"Identified rootfilesystem as %@...", checkingFile];
                                    // Move the root filesystem dmg to /var/mobile/Media/Succession/rfs.dmg
                                    [[NSFileManager defaultManager] moveItemAtPath:checkingFilePath toPath:@"/var/mobile/Media/Succession/rfs.dmg" error:&error];
                                    self.activityLabel.text = @"Cleaning up...";
                                    // Delete everything else
                                    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Succession/extracted/" error:&error];
                                    // Let the user know that download is now complete
                                    UIAlertController *downloadComplete = [UIAlertController alertControllerWithTitle:@"Download Complete" message:@"The rootfilesystem was successfully extracted to /var/mobile/Media/Succession/rfs.dmg" preferredStyle:UIAlertControllerStyleAlert];
                                    UIAlertAction *backToHomePage = [UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                        [[self navigationController] popToRootViewControllerAnimated:TRUE];
                                    }];
                                    [downloadComplete addAction:backToHomePage];
                                    [self presentViewController:downloadComplete animated:TRUE completion:nil];
                                    // Tell the for loop to stop executing now instead of waiting for the i<[extractedFolderContents count] condition to be met.
                                    break;
                                }
                            }
                        }];
                        [ipswDoesntMatch addAction:cancelAction];
                        [ipswDoesntMatch addAction:overrideAction];
                        [self presentViewController:ipswDoesntMatch animated:TRUE completion:nil];
                    }
                }
            }
        // I honestly forgot why this is here. I guess it's needed, probably a memory thing.
            [unzipIPSW UnzipCloseFile];
        }
}

- (void) URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    // So, iOS provides A LOT of information to us during the download, the oly thing I'm really interested in is the totalBytesWritten and the totalBytesExpectedToWrite. Here I convert them into float values so that I can do math with them easier. I also convert them to MB, as bytes aren't really user-friendly
    float totalSize = (totalBytesExpectedToWrite/1024)/1024.f;
    float writtenSize = (totalBytesWritten/1024)/1024.f;
    // The if statments were done to fix a bug I was having where the "unzipping" wouldn't appear, even after the download was complete, so I say "ok, if the download is 'close enough', then show the user that it's done." This is dirty. oops.
    if (writtenSize < (totalSize - 0.1)) {
        // I use a mutable attributed string here. It's attributed so that I can change the font to that monospaced font I created earlier in viewDidLoad, and its mutable so that I can apply that font after the string's creation.
        NSMutableAttributedString *activityLabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Downloading IPSW:\n%.2f of %.2f MB", writtenSize, totalSize]];
        // apply the font
        [activityLabelText addAttribute:NSFontAttributeName value:_monospacedNumberSystemFont range:NSMakeRange(0, activityLabelText.string.length)];
        // set the label equal to my attributed string
        [_activityLabel setAttributedText:activityLabelText];
        // set the progressbar equal to the ratio of writtenSize to total file size.
        self.downloadProgressBar.progress = (writtenSize/totalSize);
        [[self downloadProgressBar] setHidden:FALSE];
        [[self unzipActivityIndicator] setHidden:TRUE];
    }
    if (writtenSize > (totalSize - 0.1)) {
        // if the download is "close enough" to being done, show the unzip UI.
        self.activityLabel.text = @"Unzipping...";
        [[self downloadProgressBar] setHidden:TRUE];
        [[self unzipActivityIndicator] setHidden:FALSE];
    }
}


- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
