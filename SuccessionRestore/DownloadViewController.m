//
//  DownloadViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 2/3/18.
//  Copyright © 2018 Sam Gardner. All rights reserved.
//

#import "DownloadViewController.h"
#include <sys/sysctl.h>
#import "Objective-Zip/Objective-Zip/Objective-Zip.h"
#import "Objective-Zip/Objective-Zip/OZZipReadStream.h"
#import "HomePageViewController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "NSTask.h"

@interface DownloadViewController ()

@end

@implementation DownloadViewController
@synthesize deviceBuild;
@synthesize deviceModel;
@synthesize deviceVersion;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Load preferences
    _successionPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"];
    // Set up UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self downloadProgressBar] setHidden:TRUE];
        self.activityLabel.text = @"";
        [[self unzipActivityIndicator] setHidden:TRUE];
        
    });
    // This creates a font that is 'monospaced', (each character is the same width). This font is later used for the download progress label, since that label is rapidly updated, monospacing the font makes it readable.
    UIFont *systemFont = [UIFont systemFontOfSize:17];
    UIFontDescriptor *monospacedNumberFontDescriptor = [systemFont.fontDescriptor fontDescriptorByAddingAttributes: @{UIFontDescriptorFeatureSettingsAttribute: @[@{UIFontFeatureTypeIdentifierKey: @6, UIFontFeatureSelectorIdentifierKey: @0}]}];
    _monospacedNumberSystemFont = [UIFont fontWithDescriptor:monospacedNumberFontDescriptor size:0];
    NSArray *successionFolderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Media/Succession/" error:nil];
    // Check to see if the user has provided their own IPSW, and if so, offer to extract it instead of downloading one
    if ([[NSFileManager defaultManager] fileExistsAtPath:[_successionPrefs objectForKey:@"custom_ipsw_path"]]) {
        UIAlertController *ipswDetected = [UIAlertController alertControllerWithTitle:@"IPSW file detected!" message:[NSString stringWithFormat:@"You can either use the IPSW file you provided at %@ or you can download a clean one.", [_successionPrefs objectForKey:@"custom_ipsw_path"]] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *useProvidedIPSW = [UIAlertAction actionWithTitle:@"Use provided IPSW" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // If the user taps 'Use provided IPSW, this code is run. I do not understand why 'weakself' is necessary, I believe uroboro suggested I use it because of some memory issue(?) Anyways...
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            
            dispatch_async(queue, ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self unzipActivityIndicator] setHidden:FALSE];
                    self.activityLabel.text = @"Unzipping...";
                    [self->_startDownloadButton setEnabled:FALSE];
                    [self->_startDownloadButton setTitle:@"Working, please do not leave the app..." forState:UIControlStateNormal];
                    [self->_startDownloadButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
                });
                if (kCFCoreFoundationVersionNumber < 1300) {
                    self->_needsDecryption = TRUE;
                    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/dmg"]) {
                        // Before we continue, let's make sure there's a key available for the device we're looking for.
                        NSString *rootfsKey = [self getRFSKey];
                        if (![rootfsKey isEqualToString:@"Failed."]){
                            [self postDownload];
                        }
                    } else {
                        UIAlertController *needsXPwn = [UIAlertController alertControllerWithTitle:@"Succession requires additional components to be installed" message:@"Please install xpwn from the saurik/Telesphoreo repo." preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                            exit(0);
                        }];
                        [needsXPwn addAction:exitAction];
                        [self presentViewController:needsXPwn animated:TRUE completion:nil];
                    }
                } else {
                    self->_needsDecryption = FALSE;
                    [self postDownload];
                }
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
                UIAlertController *possibleIPSWMatchAlert = [UIAlertController alertControllerWithTitle:@"IPSW File Detected" message:[NSString stringWithFormat:@"I found an IPSW file, %@, would you like to move this IPSW to %@ and use it to restore?", file, [_successionPrefs objectForKey:@"custom_ipsw_path"]] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *moveIPSW = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Use %@", file] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSString *successionFolder = @"/var/mobile/Media/Succession/";
                    [[NSFileManager defaultManager] moveItemAtPath:[successionFolder stringByAppendingPathComponent:file] toPath:[self->_successionPrefs objectForKey:@"custom_ipsw_path"] error:nil];
                    [[self navigationController] popToRootViewControllerAnimated:TRUE];
                }];
                UIAlertAction *downloadIPSW = [UIAlertAction actionWithTitle:@"Download IPSW from Apple" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    // Sets up UI for downloading and executes the code under -(void)startDownload. The "self->" is there to shut up an Xcode warning, if Xcode warns you about this in your project, you should probably add it.
                    [self->_startDownloadButton setEnabled:FALSE];
                    [self->_startDownloadButton setTitle:@"Working, please do not leave the app..." forState:UIControlStateNormal];
                    [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];
                    [self->_startDownloadButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
                    [self prepareDownload];
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
    [self prepareDownload];
}

-(void)prepareDownload{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.activityLabel.text = @"Preparing download...";
    });
    // If the iOS version is older than iOS 10, the root filesystem DMG is encrypted. Let's make sure we can do that.
    if (kCFCoreFoundationVersionNumber < 1300) {
        _needsDecryption = TRUE;
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/dmg"]) {
            // Before we continue, let's make sure there's a key available for the device we're looking for.
            NSString *rootfsKey = [self getRFSKey];
            if (![rootfsKey isEqualToString:@"Failed."]){
                [self startDownload];
            }
        } else {
            UIAlertController *needsXPwn = [UIAlertController alertControllerWithTitle:@"Succession requires additional components to be installed" message:@"Please install xpwn from the saurik/Telesphoreo repo." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                exit(0);
            }];
            [needsXPwn addAction:exitAction];
            [self presentViewController:needsXPwn animated:TRUE completion:nil];
        }
    } else {
        _needsDecryption = FALSE;
        [self startDownload];
    }
}

-(void)startDownload {
    // Removes all files in /var/mobile/Media/Succession to delete any mess from previous uses
    NSString *workingDir = @"/var/mobile/Media/Succession/";
    NSArray *itemsToDelete = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workingDir error:nil];
    for (NSString *item in itemsToDelete) {
        [[NSFileManager defaultManager] removeItemAtPath:[workingDir stringByAppendingString:item] error:nil];
    }
    // Deletes partial downloads in Succession's sandbox folder
    NSString *tmpDir = NSTemporaryDirectory();
    NSArray *tmpToDelete = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tmpDir error:nil];
    for (NSString *item in tmpToDelete) {
        if ([item containsString:@"CFNetworkDownload"]) {
            [[NSFileManager defaultManager] removeItemAtPath:[tmpDir stringByAppendingString:item] error:nil];
        }
    }
    // Creates /var/mobile/Media/Succession in case dpkg didn't do so, or if the user deleted it
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Succession/" withIntermediateDirectories:TRUE attributes:nil error:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.activityLabel.text = @"Finding IPSW...";
    });
    if ([[[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ReleaseType"] isEqualToString:@"Beta"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self downloadProgressBar] setHidden:FALSE];
        });
        
        NSURL * betaDownloadLink = [NSURL URLWithString:@"https://raw.githubusercontent.com/Samgisaninja/SuccessionRestore/master/beta.plist"];
        // update the UI, but unless the user has a really really slow device, they probably won't ever see this:
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self activityLabel] setText:@"Getting beta plist..."];
        });
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self downloadProgressBar] setHidden:FALSE];
        });
        
        // the request is made, and the string received from ipsw.me is passed to an NSData object called 'data' in the completion handler. Note that the request is created below, but it is not actually run until [getDownloadLinkTask resume];
        NSURLSessionDataTask *getDownloadLinkTask = [[NSURLSession sharedSession] dataTaskWithURL:ipswAPIURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // so now we have a direct link to where apple is hosting the IPSW for the user's device/firmware, but it's in a rather useless NSData object, so let's convet that to an NSString
            NSString * downloadLinkString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            // update the UI, but unless the user has a really really slow device, they probably won't ever see this:
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self activityLabel] setText:[NSString stringWithFormat:@"Found IPSW at %@", downloadLinkString]];
            });
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

-(NSString *)getRFSKey{
    // Let's fetch the rootfilesystem decryption key from theiphonewiki. TheiPhoneWiki's URLs are annoyingly machine unfriendly, formatted as https://www.theiphonewiki.com/wiki/<iOS_Codename>_<Buildnumber>_(<Machine ID>)
    // The hard part here is the version codename. Muirey03 suggested to me that it might be possible to obtain the codename from MobileGestalt, but every time I tried to call it, Succession would crash. So, hardcoding! Hooray for lack of future-proofing! (or in this case, past-proofing? idk.)
    NSDictionary *codenameForVersion = @{
        @"7.0" : @"Innsbruck",
        @"7.0.1" : @"Innsbruck",
        @"7.0.2" : @"Innsbruck",
        @"7.0.3" : @"InnsbruckTaos",
        @"7.0.4" : @"InnsbruckTaos",
        @"7.0.5" : @"InnsbruckTaos",
        @"7.0.6" : @"InnsbruckTaos",
        @"7.1" : @"Sochi",
        @"7.1.1" : @"SUSochi",
        @"7.1.2" : @"Sochi",
        @"8.0" : @"Okemo",
        @"8.0.1" : @"Okemo",
        @"8.0.2" : @"Okemo",
        @"8.1" : @"OkemoTaos",
        @"8.1.1" : @"SUOkemoTaos",
        @"8.1.2" : @"SUOkemoTaos",
        @"8.1.3" : @"SUOkemoTaosTwo",
        @"8.2" : @"OkemoZurs",
        @"8.3" : @"Stowe",
        @"8.4" : @"Copper",
        @"8.4.1" : @"Donner",
        @"9.0" : @"Monarch",
        @"9.0.1" : @"Monarch",
        @"9.0.2" : @"Monarch",
        @"9.1" : @"Boulder",
        @"9.2" : @"Castlerock",
        @"9.2.1" : @"Dillon",
        @"9.3" : @"Eagle",
        @"9.3.1" : @"Eagle",
        @"9.3.2" : @"Frisco",
        @"9.3.3" : @"Genoa",
        @"9.3.4" : @"Genoa",
        @"9.3.5" : @"Genoa",
        @"9.3.6" : @"Genoa"
    };
    // Hopefully that's accurate, if it isnt... welp.
    // SO! back to what we were doing, let's figure out what codename goes with this iOS version.
    // First let's check to make sure there isn't some edge case where I don't have the codename for the user's iOS version, getting the value for a nonexistent key results in a crash.
    if ([[codenameForVersion allKeys] containsObject:deviceVersion]) {
        // yay, I have the codename for the user's iOS version. Let's make it useful.
        NSString *codename = [codenameForVersion objectForKey:deviceVersion];
        // Now, the easiest way I could think of to obtain the decryption keys was to download the HTML page of theiphonewiki, convert it to a string, and parse, like so:
        NSURL *keyPageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://theiphonewiki.com/wiki/%@_%@_(%@)", codename, deviceBuild, deviceModel]];
        // Get the data of the page at keyPageURL
        NSData *keyPageData = [NSData dataWithContentsOfURL:keyPageURL];
        // Convert the data to a string
        NSString *keyPageString = [NSString stringWithUTF8String:[keyPageData bytes]];
        // Now let's check to see if theiphonewiki actually has the key we need
        if ([keyPageString containsString:@"<code id=\"keypage-rootfs-key\">"]) {
            // yay! it does. Lets parse now.
            // separate the into an array to isolate the rfs key
            NSArray *keyPageStringSeparated = [keyPageString componentsSeparatedByString:@"<code id=\"keypage-rootfs-key\">"];
            // get all the text after "keypage-rootfs-key>"
            NSString *theFunPartOfKeyPageString = [keyPageStringSeparated objectAtIndex:1];
            // trim it down further
            NSArray *theFunPartSeparated = [theFunPartOfKeyPageString componentsSeparatedByString:@"</code>"];
            [self logToFile:[theFunPartSeparated firstObject] atLineNumber:__LINE__];
            return [theFunPartSeparated firstObject];
        } else {
            // oof. key isnt available. :rip:
            [self logToFile:[NSString stringWithFormat:@"Key for %@ %@ not available.", deviceModel, deviceBuild] atLineNumber:__LINE__];
            UIAlertController *deviceNotSupported = [UIAlertController alertControllerWithTitle:@"Device not supported." message:@"The filesystem for your iOS version is encrypted, and a decryption key is not publicly available. If you are a researcher with a private key, please decrypt the DMG yourself using xpwn and place it in /var/mobile/Media/Succession/rfs.dmg (oh, and could you also pretty please post it to theiphonewiki)." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                exit(0);
            }];
            [deviceNotSupported addAction:exitAction];
            [self presentViewController:deviceNotSupported animated:TRUE completion:nil];
            return @"Failed.";
        }
        
    } else {
        // If the iOS version isn't in the dict above, then :rip:
        [self errorAlert:[NSString stringWithFormat:@"Couldn't get codename for your iOS %@\nPlease email me stgardner4@att.net or dm me on reddit u/Samg_is_a_Ninja", deviceBuild]];
        return @"Failed.";
    }
}

- (void) URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    // So, iOS provides A LOT of information to us during the download, the oly thing I'm really interested in is the totalBytesWritten and the totalBytesExpectedToWrite. Here I convert them into float values so that I can do math with them easier. I also convert them to MB, as bytes aren't really user-friendly
    float totalSize = (totalBytesExpectedToWrite/1024)/1024.f;
    float writtenSize = (totalBytesWritten/1024)/1024.f;
    // The if statments were done to fix a bug I was having where the "unzipping" wouldn't appear, even after the download was complete, so I say "ok, if the download is 'close enough', then show the user that it's done." This is dirty. oops.
    if (writtenSize < (totalSize - 0.1)) {
        // I use a mutable attributed string here. It's attributed so that I can change the font to that monospaced font I created earlier in viewDidLoad, and its mutable so that I can apply that font after the string's creation.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableAttributedString *activityLabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Downloading IPSW:\n%.2f of %.2f MB", writtenSize, totalSize]];
            // apply the font
            [activityLabelText addAttribute:NSFontAttributeName value:self->_monospacedNumberSystemFont range:NSMakeRange(0, activityLabelText.string.length)];
            // set the label equal to my attributed string
            [self->_activityLabel setAttributedText:activityLabelText];
        });
        // set the progressbar equal to the ratio of writtenSize to total file size.
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloadProgressBar.progress = (writtenSize/totalSize);
            [[self downloadProgressBar] setHidden:FALSE];
            [[self unzipActivityIndicator] setHidden:TRUE];
        });
    }
    if (writtenSize > (totalSize - 0.1)) {
        // if the download is "close enough" to being done, show the unzip UI.
        dispatch_async(dispatch_get_main_queue(), ^{
            self.activityLabel.text = @"Unzipping...";
            [[self downloadProgressBar] setHidden:TRUE];
            [[self unzipActivityIndicator] setHidden:FALSE];
        });
    }
}

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    // so this method gets executed when "a download finished, and it's located at the NSString returned by [location path]". This presents the problem of, "well, was it a beta version, and it just downloaded the beta information plist from my github, or did it just finish downloading an IPSW?". The filename and extension are not preserved, so the best way I could think of to determine which was to check if the file was big (IPSW) or small (plist).
    NSString *downloadTaskURL = [[[downloadTask currentRequest] URL] absoluteString];
    if ([downloadTaskURL containsString:@".plist"]) {
        // Create a dictionary with the contents of the downloaded plist
        NSDictionary *betaLinks = [NSDictionary dictionaryWithContentsOfFile:[location path]];
        // If the beta plist contains the device's build number...
        if ([betaLinks objectForKey:deviceBuild]) {
            // and the build number has the device's hardware...
            if ([[betaLinks objectForKey:deviceBuild] objectForKey:deviceModel]) {
                // then get the matching link.
                NSString *downloadLinkString = [NSString stringWithFormat:@"%@", [[betaLinks objectForKey:deviceBuild] objectForKey:deviceModel]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self activityLabel] setText:[NSString stringWithFormat:@"Found IPSW at %@", downloadLinkString]];
                });
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self downloadProgressBar] setHidden:TRUE];
            [[self activityLabel] setText:@"Retrieving Download..."];
            [[self unzipActivityIndicator] setHidden:FALSE];
        });
        NSError * error;
        // NSFileManager lets us do pretty much anything with files, and also, if there's an error, error information will be stored in the NSError object I created above.
        [[NSFileManager defaultManager] moveItemAtPath:[location path] toPath:[_successionPrefs objectForKey:@"custom_ipsw_path"] error:&error];
        // I've never come across an error with this, but it's better to have error handling than to... not. Assuming there's no error, continue on to -(void)postDownload
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self activityLabel] setText:[NSString stringWithFormat:@"Error moving downloaded ipsw: %@", [error localizedDescription]]];
            });
        } else {
            [self postDownload];
        }
    }
}

- (void) postDownload {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self unzipActivityIndicator] setHidden:FALSE];
        [[self activityLabel] setText:@"Verifying IPSW..."];
        
    });
    [[NSFileManager defaultManager] moveItemAtPath:[_successionPrefs objectForKey:@"custom_ipsw_path"] toPath:@"/var/mobile/Media/Succession/ipsw.ipsw" error:nil];
    OZZipFile *zip= [[OZZipFile alloc] initWithFileName:@"/var/mobile/Media/Succession/ipsw.ipsw" mode:OZZipFileModeUnzip];
    NSMutableData *buffer = [[NSMutableData alloc] initWithLength:1024];
    NSArray *zipContentList= [zip listFileInZipInfos];
    for (OZFileInZipInfo *fileInZipInfo in zipContentList) {
        if ([[fileInZipInfo name] isEqualToString:@"BuildManifest.plist"]) {
            // Create file
            NSString *filePath = [NSString stringWithFormat:@"/var/mobile/Media/Succession/%@", fileInZipInfo.name];
            [[NSFileManager defaultManager] createFileAtPath:filePath contents:[NSData data] attributes:nil];
            NSFileHandle *file= [NSFileHandle fileHandleForWritingAtPath:filePath];
            [zip locateFileInZip:fileInZipInfo.name];
            OZZipReadStream *readStream= [zip readCurrentFileInZip];
            [buffer setLength:1024];
            int totalBytesRead= 0;
            do {
                int bytesRead= [readStream readDataWithBuffer:buffer];
                if (bytesRead > 0) {
                    [buffer setLength:bytesRead];
                    [file writeData:buffer];
                    [self logToFile:[NSString stringWithFormat:@"Writing %@, %d of %llu bytes...", [fileInZipInfo name], totalBytesRead, [fileInZipInfo length]] atLineNumber:__LINE__];
                    totalBytesRead += bytesRead;
                    
                } else
                    break;
            } while (YES);
            [file closeFile];
            [readStream finishedReading];
        }
    }
    [zip close];
    NSDictionary *IPSWBuildManifest = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Media/Succession/BuildManifest.plist"];
    if ([[IPSWBuildManifest objectForKey:@"ProductBuildVersion"] isEqualToString:deviceBuild]) {
        [self logToFile:[NSString stringWithFormat:@"Build number in BuildManifest %@ matches deviceBuild %@", [IPSWBuildManifest objectForKey:@"ProductBuildVersion"], deviceBuild] atLineNumber:__LINE__];
        if ([[IPSWBuildManifest objectForKey:@"SupportedProductTypes"] containsObject:deviceModel]) {
            [self logToFile:[NSString stringWithFormat:@"Product Type in BuildManifest %@ matches deviceBuild %@", [IPSWBuildManifest objectForKey:@"SupportedProductTypes"], deviceModel] atLineNumber:__LINE__];
            [self logToFile:@"Successfully verified IPSW" atLineNumber:__LINE__];
            [self extractDMG];
        } else {
            UIAlertController *ipswDoesntMatch = [UIAlertController alertControllerWithTitle:@"Provided IPSW does not appear to match this device" message:@"The IPSW you provided does not appear to match this device/iOS version. You may override this warning, but you will most likely bootloop." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Delete and Exit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSFileManager* fm = [[NSFileManager alloc] init];
                NSDirectoryEnumerator* en = [fm enumeratorAtPath:@"/var/mobile/Media/Succession"];
                NSError* error = nil;
                BOOL res;
                NSString* file;
                while (file = [en nextObject]) {
                    res = [fm removeItemAtPath:[@"/var/mobile/Media/Succession" stringByAppendingPathComponent:file] error:&error];
                    if (!res && error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[self activityLabel] setText:[NSString stringWithFormat:@"Error deleting files: %@", [error localizedDescription]]];
                        });
                    }
                }
                exit(0);
            }];
            UIAlertAction *overrideAction = [UIAlertAction actionWithTitle:@"Override" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self logToFile:@"User chose to override mismatch, continuing" atLineNumber:__LINE__];
                [self extractDMG];
            }];
            [ipswDoesntMatch addAction:overrideAction];
            [ipswDoesntMatch addAction:cancelAction];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:ipswDoesntMatch animated:TRUE completion:nil];
            });
        }
    } else {
        UIAlertController *ipswDoesntMatch = [UIAlertController alertControllerWithTitle:@"Provided IPSW does not appear to match this device" message:@"The IPSW you provided does not appear to match this device/iOS version. You may override this warning, but you will most likely bootloop." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Delete and Exit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSFileManager* fm = [[NSFileManager alloc] init];
            NSDirectoryEnumerator* en = [fm enumeratorAtPath:@"/var/mobile/Media/Succession"];
            NSError* error = nil;
            BOOL res;
            NSString* file;
            while (file = [en nextObject]) {
                res = [fm removeItemAtPath:[@"/var/mobile/Media/Succession" stringByAppendingPathComponent:file] error:&error];
                if (!res && error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self activityLabel] setText:[NSString stringWithFormat:@"Error deleting files: %@", [error localizedDescription]]];
                    });
                }
            }
            exit(0);
        }];
        UIAlertAction *overrideAction = [UIAlertAction actionWithTitle:@"Override" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self logToFile:@"User chose to override mismatch, continuing" atLineNumber:__LINE__];
            [self extractDMG];
        }];
        [ipswDoesntMatch addAction:overrideAction];
        [ipswDoesntMatch addAction:cancelAction];
        [self presentViewController:ipswDoesntMatch animated:TRUE completion:nil];
    }
}

-(void) extractDMG {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self unzipActivityIndicator] setHidden:FALSE];
        [[self activityLabel] setText:@"Identifying rfs in compressed IPSW..."];
    });
    OZZipFile *unzipIPSW;
    if (sizeof(void *) == 4) {
        unzipIPSW = [[OZZipFile alloc] initWithFileName:@"/var/mobile/Media/Succession/ipsw.ipsw" mode:OZZipFileModeUnzip legacy32BitMode:TRUE];
    } else {
        unzipIPSW = [[OZZipFile alloc] initWithFileName:@"/var/mobile/Media/Succession/ipsw.ipsw" mode:OZZipFileModeUnzip legacy32BitMode:TRUE];
    }
    [unzipIPSW locateFileInZip:@"BuildManifest.plist"];
    NSMutableDictionary *namesAndSizes = [[NSMutableDictionary alloc] init];
    NSArray *infos = [unzipIPSW listFileInZipInfos];
    NSMutableArray *fileSizes = [[NSMutableArray alloc] init];
    for (OZFileInZipInfo *info in infos) {
        if ([info.name hasSuffix:@".dmg"]) {
            [self logToFile:[NSString stringWithFormat:@"%@ is a DMG of size %llu!", [info name], [info length]] atLineNumber:__LINE__];
            [namesAndSizes setObject:[info name] forKey:[NSNumber numberWithUnsignedLongLong:[info length]]];
            [fileSizes addObject:[NSNumber numberWithUnsignedLongLong:[info length]]];
        }
    }
    NSNumber *largestFileSize = [fileSizes valueForKeyPath:@"@max.self"];
    [self logToFile:[NSString stringWithFormat:@"Largest file size is %@", largestFileSize] atLineNumber:__LINE__];
    NSString *largestFileName = [namesAndSizes objectForKey:largestFileSize];
    [unzipIPSW locateFileInZip:largestFileName];
    [self logToFile:[NSString stringWithFormat:@"Name of largest file is %@", largestFileName] atLineNumber:__LINE__];
    
    unsigned long long dmgLengthULL = (unsigned long long)[[namesAndSizes allKeysForObject:largestFileName] firstObject];
    float dmgLength = (float)dmgLengthULL;
    OZZipReadStream *read = [unzipIPSW readCurrentFileInZip];
    NSMutableData *data = [[NSMutableData alloc] initWithLength:32768];
    [[NSFileManager defaultManager] createFileAtPath:@"/var/mobile/Media/Succession/rfs.dmg" contents:nil attributes:nil];
    float unzipProgress = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self unzipActivityIndicator] setHidden:TRUE];
        [[self downloadProgressBar] setHidden:FALSE];
        [[self activityLabel] setText:[NSString stringWithFormat:@"Extracting %@ from IPSW", largestFileName]];
    });
    do {
        
        // Reset buffer length
        [data setLength:32768];
        
        // Read bytes and check for end of file
        int bytesRead= (int)[read readDataWithBuffer:data];
        if (bytesRead <= 0)
            break;
        [data setLength:bytesRead];
        unzipProgress = unzipProgress + bytesRead;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self downloadProgressBar] setProgress:(unzipProgress/dmgLength)];
        });
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/var/mobile/Media/Succession/rfs.dmg"];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
        [self logToFile:[NSString stringWithFormat:@"Extracting DMG, %d bytes extracted, %f of %f total", bytesRead, unzipProgress, dmgLength] atLineNumber:__LINE__];
    } while (YES);
    [read finishedReading];
    [unzipIPSW close];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self unzipActivityIndicator] setHidden:FALSE];
        [[self downloadProgressBar] setHidden:TRUE];
        [[self activityLabel] setText:[NSString stringWithFormat:@"Cleaning up..."]];
    });
    // Delete everything else
    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Succession/ipsw.ipsw" error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Succession/BuildManifest.plist" error:nil];
    [self logToFile:@"extraction complete" atLineNumber:__LINE__];
    // If the DMG needs decryption, decrypt it now.
    // Let the user know that download is now complete
    NSString *message;
    if (_needsDecryption) {
        [[NSFileManager defaultManager] moveItemAtPath:@"/var/mobile/Media/Succession/rfs.dmg" toPath:@"/var/mobile/Media/Succession/encrypted.dmg" error:nil];
        message = @"The rootfilesystem was successfully extracted, but it needs to be decrypted. Please go back to the home page and tap \"Decrypt DMG\"";
    } else {
        message = @"The rootfilesystem was successfully extracted to /var/mobile/Media/Succession/rfs.dmg";
    }
    UIAlertController *downloadComplete = [UIAlertController alertControllerWithTitle:@"Download Complete" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *backToHomePage = [UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[self navigationController] popToRootViewControllerAnimated:TRUE];
    }];
    [downloadComplete addAction:backToHomePage];
    [self presentViewController:downloadComplete animated:TRUE completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)errorAlert:(NSString *)message{
    [self logToFile:[NSString stringWithFormat:@"ERROR! %@", message] atLineNumber:__LINE__];
    UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }];
    [errorAlertController addAction:exitAction];
    [self presentViewController:errorAlertController animated:TRUE completion:nil];
}

- (void)logToFile:(NSString *)message atLineNumber:(int)lineNum {
    if ([[self->_successionPrefs objectForKey:@"log-file"] isEqual:@(1)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/mobile/succession.log"]) {
                [[NSFileManager defaultManager] createFileAtPath:@"/private/var/mobile/succession.log" contents:nil attributes:nil];
            }
            NSString *stringToLog = [NSString stringWithFormat:@"[SUCCESSIONLOG %@: %@] Line %@: %@\n", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [NSDate date], [NSString stringWithFormat:@"%d", lineNum], message];
            NSLog(@"%@", stringToLog);
            NSFileHandle *logFileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/private/var/mobile/succession.log"];
            [logFileHandle seekToEndOfFile];
            [logFileHandle writeData:[stringToLog dataUsingEncoding:NSUTF8StringEncoding]];
            [logFileHandle closeFile];
        });
    }
}

@end
