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
    _successionPrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"]];
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
        [[self subtitleLabel] setText:@""];
        [[self eraseButton] setTitle:@"Please Wait..." forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [[self eraseButton] setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
        } else {
            [[self eraseButton] setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
        }
        [[self eraseButton] setEnabled:FALSE];
        [[self outputLabel] setHidden:TRUE];
        [[self progressIndicator] setHidden:FALSE];
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
                        [self logToFile:[NSString stringWithFormat:@"found attached diskpath in %@", line] atLineNumber:__LINE__];
                        NSArray *lineWords = [line componentsSeparatedByString:@" "];
                        for (NSString *word in lineWords) {
                            if ([word hasPrefix:@"/dev/disk"]) {
                                [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", word] atLineNumber:__LINE__];
                                [self prepareMountAttachedDisk:word];
                                break;
                            }
                        }
                    }
                }
            } else {
                NSString *diskPath = [outLines firstObject];
                [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", diskPath] atLineNumber:__LINE__];
                [self prepareMountAttachedDisk:diskPath];
            }
        };
        [hdikTask launch];
        [hdikTask waitUntilExit];
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik-arm64"]] || [[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik-arm64e"]] || [[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik-armv7"]]) {
        [self errorAlert:@"Succession has not been configured. Please reinstall Succession using Cydia or Zebra. If you installed Succession manually, please extract Succession's postinst script and run it" atLineNumber:__LINE__];
    } else {
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/sbin/attach"]) {
            [self logToFile:@"Using comex attach for attach" atLineNumber:__LINE__];
            NSTask *attachTask = [[NSTask alloc] init];
            [attachTask setLaunchPath:@"/usr/sbin/attach"];
            NSPipe *stdOutPipe = [NSPipe pipe];
            NSFileHandle *outPipeRead = [stdOutPipe fileHandleForReading];
            attachTask.terminationHandler = ^{
                NSData *outData = [outPipeRead readDataToEndOfFile];
                NSString *outString = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
                [self logToFile:[NSString stringWithFormat:@"attach output is: %@", outString] atLineNumber:__LINE__];
                NSArray *outLines = [outString componentsSeparatedByString:[NSString stringWithFormat:@"\n"]];
                [self logToFile:[NSString stringWithFormat:@"%@\n\n%lu", [outLines componentsJoinedByString:@", "], (unsigned long)[outLines count]] atLineNumber:__LINE__];
                if ([outLines count] != 2) {
                    for (NSString *line in outLines) {
                        [self logToFile:[NSString stringWithFormat:@"current line is %@", line]  atLineNumber:__LINE__];
                        if ([line containsString:@"s3"]) {
                            [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", line] atLineNumber:__LINE__];
                            NSString *theDiskString = [NSMutableString stringWithString:line];
                            [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", theDiskString] atLineNumber:__LINE__];
                            [self prepareMountAttachedDisk:theDiskString];
                            break;
                        }
                    }
                } else {
                    NSString *theDiskString = [outLines firstObject];
                    [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", theDiskString] atLineNumber:__LINE__];
                    [self prepareMountAttachedDisk:theDiskString];
                }
            };
            [attachTask launch];
            [attachTask waitUntilExit];
            
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

-(void)prepareMountAttachedDisk:(NSString *)diskPath{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self titleLabel] setText:@"Identifying filesystem type..."];
    });
    NSError *error;
    NSString *fstabString = [NSString stringWithContentsOfFile:@"/private/etc/fstab" encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        if ([fstabString containsString:@"apfs"]) {
            [self logToFile:@"Identified filesystem as APFS!" atLineNumber:__LINE__];
            [self mountAttachedDisk:diskPath ofType:@"apfs"];
        } else if ([fstabString containsString:@"hfs"]){
            [self logToFile:@"Identified filesystem as HFS!" atLineNumber:__LINE__];
            [self mountAttachedDisk:diskPath ofType:@"hfs"];
        } else {
            [self errorAlert:[NSString stringWithFormat:@"Failed to identify filesystem, read fstab successfully, but fstab did not contain filesystem type: %@", fstabString] atLineNumber:__LINE__];
        }
    } else {
        [self errorAlert:[NSString stringWithFormat:@"Failed to read fstab: %@", [error localizedDescription]] atLineNumber:__LINE__];
    }
}

-(void)mountAttachedDisk:(NSString *)diskPath ofType:(NSString *)filesystemType{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self titleLabel] setText:@"Mounting Filesystem..."];
        [[self subtitleLabel] setText:@"This should take less than 10 seconds."];
    });
    NSTask *mountTask = [[NSTask alloc] init];
    [mountTask setLaunchPath:@"/sbin/mount"];
    NSArray *mountArgs = [NSArray arrayWithObjects:@"-t", filesystemType, @"-o", @"ro", diskPath, @"/private/var/MobileSoftwareUpdate/mnt1", nil];
    [mountTask setArguments:mountArgs];
    NSPipe *stdOutPipe = [NSPipe pipe];
    NSFileHandle *stdOutFileRead = [stdOutPipe fileHandleForReading];
    mountTask.terminationHandler = ^{
        NSData *outData = [stdOutFileRead readDataToEndOfFile];
        NSString *outString = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
        [self logToFile:[NSString stringWithFormat:@"mounting complete! %@", outString] atLineNumber:__LINE__];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self titleLabel] setText:@"WARNING!!!"];
            [[self subtitleLabel] setText:@"Running this tool will immediately delete all data from your device. Please make a backup of any data that you want to keep. This will also return your device to the setup screen.  A valid SIM card may be needed for activation on iPhones and cellular iPads."];
            [[self eraseButton] setTitle:[NSString stringWithFormat:@"Erase %@", self->_deviceType] forState:UIControlStateNormal];
            [[self eraseButton] setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            [[self eraseButton] setEnabled:TRUE];
            [[self outputLabel] setHidden:TRUE];
            [[self progressIndicator] setHidden:TRUE];
            [[self restoreProgressBar] setHidden:TRUE];
        });
    };
    [mountTask launch];
    [mountTask waitUntilExit];
}

- (IBAction)tappedRestoreButton:(id)sender {
    [self logToFile:@"tappedRestoreButton called" atLineNumber:__LINE__];
    if ([[_successionPrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)] || [[_successionPrefs objectForKey:@"create_APFS_orig-fs"] isEqual:@(1)]) {
        [self logToFile:@"snappy operations enabled" atLineNumber:__LINE__];
        if (kCFCoreFoundationVersionNumber > 1349.56) {
            [self logToFile:@"ios version compatible with snappy" atLineNumber:__LINE__];
            if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/snappy"]) {
                [self logToFile:@"snappy not installed, asking to install it" atLineNumber:__LINE__];
                UIAlertController *needSnappy = [UIAlertController alertControllerWithTitle:@"Snappy required" message:@"Your current preferences indicate you would like to perform operations with APFS snapshots, but you do not have snappy installed. Please install snappy from https://repo.bingner.com" preferredStyle:UIAlertControllerStyleAlert];
                NSString *sources = [NSString stringWithContentsOfFile:@"/etc/apt/sources.list.d/cydia.list" encoding:NSUTF8StringEncoding error:nil];
                if (![sources containsString:@"bingner.com"]) {
                    UIAlertAction *addRepo = [UIAlertAction actionWithTitle:@"Add repository to cydia" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        if (@available(iOS 10.0, *)) {
                            NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://cydia.saurik.com/api/share#?source=https://repo.bingner.com/"] options:URLOptions completionHandler:nil];
                        } else {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://cydia.saurik.com/api/share#?source=https://repo.bingner.com/"]];
                        }
                        [self logToFile:@"user adding source for snappy" atLineNumber:__LINE__];
                    }];
                    [needSnappy addAction:addRepo];
                }
                UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
                [needSnappy addAction:dismissAction];
                [self presentViewController:needSnappy animated:TRUE completion:nil];
            } else {
                [self logToFile:@"snappy requested and already installed" atLineNumber:__LINE__];
                [self showRestoreAlert];
            }
        } else {
            [self logToFile:@"apfs snapshot operations enabled, but iOS version not compatible with snappy" atLineNumber:__LINE__];
            UIAlertController *snapshotsNotSupported = [UIAlertController alertControllerWithTitle:@"APFS operations not supported" message:@"You must be running iOS 10.3 or higher to use APFS features." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismis" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self logToFile:@"user disabled snappy options" atLineNumber:__LINE__];
                [self->_successionPrefs setObject:@(0) forKey:@"create_APFS_orig-fs"];
                [self->_successionPrefs setObject:@(0) forKey:@"create_APFS_succession-prerestore"];
                [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
                [self->_successionPrefs writeToFile:@"/private/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
                [[self navigationController] popToRootViewControllerAnimated:TRUE];
            }];
            [snapshotsNotSupported addAction:dismissAction];
            [self presentViewController:snapshotsNotSupported animated:TRUE completion:nil];
        }
    } else {
        [self logToFile:@"no apfs snapshot operations requested" atLineNumber:__LINE__];
        [self showRestoreAlert];
    }
}

- (void)showRestoreAlert{
    [self logToFile:@"showRestoreAlert called!" atLineNumber:__LINE__];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[[NSString stringWithFormat:@"/private/var/MobileSoftwareUpdate/mnt1"] stringByAppendingPathComponent:@"sbin"] stringByAppendingPathComponent:@"launchd"]]) {
        [self logToFile:@"filesystem is mounted, asking user to confirm they are ready to restore" atLineNumber:__LINE__];
        if ([_deviceModel containsString:@"iPad"]) {
            _areYouSureAlert = [UIAlertController alertControllerWithTitle:@"Are you sure you would like to begin restoring" message:@"You will not be able to leave the app during the process" preferredStyle:UIAlertControllerStyleAlert];
        } else {
            _areYouSureAlert = [UIAlertController alertControllerWithTitle:@"Are you sure you would like to begin restoring" message:@"You will not be able to leave the app during the process" preferredStyle:UIAlertControllerStyleActionSheet];
        }
        UIAlertAction *beginRestore = [UIAlertAction actionWithTitle:@"Begin restore" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self logToFile:@"user wants to begin restore now, checking battery level" atLineNumber:__LINE__];
            [[UIDevice currentDevice] setBatteryMonitoringEnabled:TRUE];
            if ([[UIDevice currentDevice] batteryLevel] > 0.5) {
                if (@available(iOS 9.0, *)) {
                    if ([[NSProcessInfo processInfo] isLowPowerModeEnabled]) {
                        UIAlertController *disableLowPowerMode = [UIAlertController alertControllerWithTitle:@"Low Power Mode enabled" message:@"Low Power Mode causes your device to auto-lock after 30 seconds, please go to settings and turn that off." preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"I've turned it off, start restoring" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [self beginRestore];
                        }];
                        [disableLowPowerMode addAction:okAction];
                        [self presentViewController:disableLowPowerMode animated:TRUE completion:nil];
                    } else {
                        [self logToFile:[NSString stringWithFormat:@"battery level is %f which is greater than 50%%, ready to go", [[UIDevice currentDevice] batteryLevel]] atLineNumber:__LINE__];
                        [self beginRestore];
                    }
                } else {
                    [self logToFile:[NSString stringWithFormat:@"battery level is %f which is greater than 50%%, ready to go", [[UIDevice currentDevice] batteryLevel]] atLineNumber:__LINE__];
                    [self beginRestore];
                }
            } else {
                [self logToFile:[NSString stringWithFormat:@"battery is %f which is less than 50%%, warning user", [[UIDevice currentDevice] batteryLevel]] atLineNumber:__LINE__];
                UIAlertController *lowBatteryWarning = [UIAlertController alertControllerWithTitle:@"Low Battery" message:@"It is recommended you have at least 50% battery charge before beginning restore" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelRestoreAction = [UIAlertAction actionWithTitle:@"Abort restore" style:UIAlertActionStyleDefault handler:nil];
                UIAlertAction *startRestoreAction = [UIAlertAction actionWithTitle:@"Restore anyways" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    if (@available(iOS 9.0, *)) {
                        if ([[NSProcessInfo processInfo] isLowPowerModeEnabled]) {
                            UIAlertController *disableLowPowerMode = [UIAlertController alertControllerWithTitle:@"Low Power Mode enabled" message:@"Low Power Mode causes your device to auto-lock after 30 seconds, please go to settings and turn that off." preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"I've turned it off, start restoring" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                [self beginRestore];
                            }];
                            [disableLowPowerMode addAction:okAction];
                            [self presentViewController:disableLowPowerMode animated:TRUE completion:nil];
                        } else {
                            [self logToFile:@"user chose to override battery warning, restoring now" atLineNumber:__LINE__];
                            [self beginRestore];
                        }
                    } else {
                        [self logToFile:@"user chose to override battery warning, restoring now" atLineNumber:__LINE__];
                        [self beginRestore];
                    }
                }];
                [lowBatteryWarning addAction:cancelRestoreAction];
                [lowBatteryWarning addAction:startRestoreAction];
                [self presentViewController:lowBatteryWarning animated:TRUE completion:nil];
            }
            [[UIDevice currentDevice] setBatteryMonitoringEnabled:FALSE];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [_areYouSureAlert addAction:beginRestore];
        [_areYouSureAlert addAction:cancelAction];
        [self presentViewController:_areYouSureAlert animated:TRUE completion:nil];
    } else {
        
    }
}







-(void)errorAlert:(NSString *)message atLineNumber:(int)lineNum{
    [self logToFile:[NSString stringWithFormat:@"ERROR! %@", message] atLineNumber:lineNum];
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
