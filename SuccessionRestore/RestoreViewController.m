//
//  RestoreViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 6/30/18.
//  Re-created 11/28/19.
//  Copyright © 2019 Sam Gardner. All rights reserved.
//

#import "RestoreViewController.h"
#include <sys/sysctl.h>
#import "NSTask.h"

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
        [[self eraseButton] setEnabled:FALSE];
        [[self outputLabel] setHidden:TRUE];
        [[self progressIndicator] setHidden:TRUE];
        [[self restoreProgressBar] setHidden:TRUE];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    // If the disk isn't mounted, attach and mount
    if (![self isMounted]) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [self attachDiskImage];
        });
    }
}

- (IBAction)tappedRestoreButton:(id)sender {
    
}

-(BOOL)isMounted{
    // if this file doesnt exist, the disk isnt mounted, and the chances of someone creating it "just for fun" is astronomically low
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
        return TRUE;
    } else {
        return FALSE;
    }
}

-(void)attachDiskImage{
    [self logToFile:@"attachDiskImage called!" atLineNumber:__LINE__];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSString stringWithFormat:@"%@", [[NSBundle mainBundle] bundlePath]] stringByAppendingPathComponent:@"hdik"]]) {
        [self logToFile:@"using hdik to attach disk image" atLineNumber:__LINE__];
        NSTask *hdikTask = [[NSTask alloc] init];
        [hdikTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik"]];
        NSArray *hdikArgs = [NSArray arrayWithObjects:@"/private/var/mobile/Media/Succession/rfs.dmg", nil];
        [hdikTask setArguments:hdikArgs];
        [self logToFile:[NSString stringWithFormat:@"hdik %@", [hdikArgs componentsJoinedByString:@" "]] atLineNumber:__LINE__];
        NSPipe *stdOutPipe = [NSPipe pipe];
        NSFileHandle *outPipeRead = [stdOutPipe fileHandleForReading];
        [hdikTask setStandardOutput:stdOutPipe];
        hdikTask.terminationHandler = ^{
            NSData *outData = [outPipeRead readDataToEndOfFile];
            NSString *outString = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
            [self logToFile:[NSString stringWithFormat:@"hdik completed with\n%@",outString] atLineNumber:__LINE__];
            NSArray *outLines = [outString componentsSeparatedByString:[NSString stringWithFormat:@"\n"]];
            [self logToFile:[outLines componentsJoinedByString:@",\n"] atLineNumber:__LINE__];
            if ([outLines count] > 1) {
                for (NSString *line in outLines) {
                    [self logToFile:[NSString stringWithFormat:@"current line is %@", line]  atLineNumber:__LINE__];
                    if ([line containsString:@"s2"]) {
                        [self logToFile:[NSString stringWithFormat:@"found attached diskname in %@", line] atLineNumber:__LINE__];
                        NSArray *lineWords = [line componentsSeparatedByString:@" "];
                        for (NSString *word in lineWords) {
                            if ([word hasPrefix:@"/dev/disk"]) {
                                NSString *diskname = [word stringByReplacingOccurrencesOfString:@"/dev/" withString:@""];
                                [self logToFile:[NSString stringWithFormat:@"found attached diskname %@", diskname] atLineNumber:__LINE__];
                                self->_theDiskString = [NSMutableString stringWithString:word];
                                [self logToFile:[NSString stringWithFormat:@"sending %@ to mountRestoreDisk", self->_theDiskString] atLineNumber:__LINE__];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[self eraseButton] setTitle:self->_theDiskString forState:UIControlStateNormal];
                                });
                                //[self mountRestoreDisk];
                            }
                        }
                    }
                }
            } else {
                self->_theDiskString = [outLines firstObject];
            }
        };
        [hdikTask launch];
        [hdikTask waitUntilExit];
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik-arm64"]] || [[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik-arm64e"]] || [[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik-armv7"]]) {
        [self errorAlert:@"Succession has not been configured. Please reinstall Succession using Cydia or Zebra. If you installed Succession manually, please extract Succession's postinst script and run it"];
    } else {
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/sbin/attach"]) {
            
        } else {
            UIAlertController *needsAttach = [UIAlertController alertControllerWithTitle:@"Succession requires additional components to be installed" message:@"Please add http://pmbonneau.com/cydia to your sources and install 'attach' to continue." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                exit(0);
            }];
            UIAlertAction *addRepoAction = [UIAlertAction actionWithTitle:@"Add repo to cydia" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (@available(iOS 10.0, *)) {
                    NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://cydia.saurik.com/api/share#?source=http://pmbonneau.com/cydia"] options:URLOptions completionHandler:nil];
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://cydia.saurik.com/api/share#?source=http://pmbonneau.com/cydia"]];
                }
                exit(0);
            }];
            NSString *sources = [NSString stringWithContentsOfFile:@"/etc/apt/sources.list.d/cydia.list" encoding:NSUTF8StringEncoding error:nil];
            if (![sources containsString:@"pmbonneau.com/cydia"]) {
                [needsAttach addAction:addRepoAction];
            }
            [needsAttach addAction:exitAction];
            [self presentViewController:needsAttach animated:TRUE completion:nil];
        }
    }
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
