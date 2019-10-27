//
//RestoreViewController.m
//SuccessionRestore
//
//Created by Sam Gardner on 6/30/18.
//Copyright © 2018 Sam Gardner. All rights reserved.
//

#import "RestoreViewController.h"
#include <sys/sysctl.h>
#import "NSTask.h"


@interface RestoreViewController ()

@end

@implementation RestoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];
    [[self outputLabel] setHidden:TRUE];
    [[self restoreProgressBar] setHidden:TRUE];
    _successionPrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"]];
    [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/mobile/succession.log" error:nil];
    [self logToFile:@"RestoreViewController has loaded!" atLineNumber:__LINE__];
}

- (void) viewDidAppear:(BOOL)animated{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    _deviceModel = [NSString stringWithUTF8String:modelChar];
    free(modelChar);
    if ([_deviceModel containsString:@"iPad"]) {
        [[self startRestoreButton] setTitle:@"Erase iPad" forState:UIControlStateNormal];
    } else if ([_deviceModel containsString:@"iPod"]){
        [[self startRestoreButton] setTitle:@"Erase iPod Touch" forState:UIControlStateNormal];
    } else {
        [[self startRestoreButton] setTitle:@"Erase iPhone" forState:UIControlStateNormal];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
        [[self fileListActivityIndicator] setHidden:TRUE];
    } else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self headerLabel] setText:@"Mounting, please wait..."];
                [[self infoLabel] setHidden:TRUE];
                [[self fileListActivityIndicator] setHidden:FALSE];
                [[self startRestoreButton] setHidden:TRUE];
            });
            [self prepareAttachRestoreDisk];
        });
    }
    if ([_deviceModel isEqualToString:@"iPhone8,1"] || [_deviceModel isEqualToString:@"iPhone8,2"]) {
        char *buildChar = malloc(size);
        sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
        NSString *deviceBuild = [NSString stringWithUTF8String:buildChar];
        if ([deviceBuild hasPrefix:@"13"]) {
            UIAlertController *hacktivationWarning = [UIAlertController alertControllerWithTitle:@"Warning!" message:@"Apple is blocking activations on iOS 9.X on the iPhone 6s and 6s Plus. It is recommended that you enable \"Hacktivate device\" in Succession's settings to force your device to not require activation" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *enableHacktivationAction = [UIAlertAction actionWithTitle:@"Enable Hacktivation" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self->_successionPrefs setObject:@(1) forKey:@"hacktivation"];
                [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
                [self->_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
            }];
            UIAlertAction *ignoreAction = [UIAlertAction actionWithTitle:@"Ignore this warning" style:UIAlertActionStyleDestructive handler:nil];
            [hacktivationWarning addAction:enableHacktivationAction];
            [hacktivationWarning addAction:ignoreAction];
            [self presentViewController:hacktivationWarning animated:TRUE completion:nil];
        }
    }
}

- (IBAction)startRestoreButtonAction:(id)sender {
    [self logToFile:@"startRestoreButtonAction called" atLineNumber:__LINE__];
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

- (void) showRestoreAlert{
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
        [self logToFile:@"Filesystem is not mounted, showing mount alert now" atLineNumber:__LINE__];
        UIAlertController *mountingAlert = [UIAlertController alertControllerWithTitle:@"Mounting filesystem..." message:@"If this alert shows more than twice without rebooting, please contact me, u/Samg_is_a_Ninja on reddit or stgardner4@att.net" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [mountingAlert addAction:okAction];
        [self presentViewController:mountingAlert animated:TRUE completion:^{
            [self logToFile:[NSString stringWithFormat:@"mountingAlert handler called, identified theDiskString as %@", self->_theDiskString] atLineNumber:__LINE__];
            if ([self->_theDiskString containsString:@"disk"]) {
                [self logToFile:[NSString stringWithFormat:@"sending %@ to mountRestoreDisk", self->_theDiskString] atLineNumber:__LINE__];
                [self mountRestoreDisk];
            } else {
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(queue, ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self headerLabel] setText:@"Mounting, please wait..."];
                        [[self infoLabel] setHidden:TRUE];
                        [[self fileListActivityIndicator] setHidden:FALSE];
                    });
                    [self prepareAttachRestoreDisk];
                });
            }
            
        }];
    }
}

- (void) beginRestore {
    [self logToFile:@"beginRestore called!" atLineNumber:__LINE__];
    if ([[self->_successionPrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)]) {
        NSTask *deletePreviousBackupSnapTask = [[NSTask alloc] init];
        [deletePreviousBackupSnapTask setLaunchPath:@"/usr/bin/snappy"];
        NSArray *deletePreviousBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-d", @"succession-prerestore", nil];
        [deletePreviousBackupSnapTask setArguments:deletePreviousBackupSnapTaskArgs];
        [self logToFile:@"user elected to create succession-prerestore snapshot, deleting already present succession-prerestore" atLineNumber:__LINE__];
        [deletePreviousBackupSnapTask launch];
        NSTask *createBackupSnapTask = [[NSTask alloc] init];
        [createBackupSnapTask setLaunchPath:@"/usr/bin/snappy"];
        NSArray *createBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-c", @"succession-prerestore", nil];
        [createBackupSnapTask setArguments:createBackupSnapTaskArgs];
        [self logToFile:@"creating new succession-prerestore" atLineNumber:__LINE__];
        [createBackupSnapTask launch];
    }
    [self successionRestore];
}

- (void) prepareAttachRestoreDisk{
    [self logToFile:@"prepareAttachRestoreDisk called!" atLineNumber:__LINE__];
    NSError *err;
    NSString *fstab = [NSString stringWithContentsOfFile:@"/etc/fstab" encoding:NSUTF8StringEncoding error:&err];
    if (!err) {
        [self logToFile:[NSString stringWithFormat:@"Read fstab! %@", fstab] atLineNumber:__LINE__];
        if ([fstab containsString:@"hfs"]) {
            _filesystemType = @"hfs";
            [self logToFile:[NSString stringWithFormat:@"Identified filesystem type as HFS! %@", _filesystemType] atLineNumber:__LINE__];
            [self attachRestoreDisk];
        } else if ([fstab containsString:@"apfs"]) {
            _filesystemType = @"apfs";
            [self logToFile:[NSString stringWithFormat:@"Identified filesystem type as APFS! %@", _filesystemType] atLineNumber:__LINE__];
            [self attachRestoreDisk];
        } else {
            [self errorAlert:[NSString stringWithFormat:@"Unable to determine APFS or HFS:\n%@", fstab]];
        }
    } else {
        [self errorAlert:[NSString stringWithFormat:@"Failed to read fstab: %@", [err localizedDescription]]];
    }
}

- (void) attachRestoreDisk {
    [self logToFile:@"attachRestoreDisk called!" atLineNumber:__LINE__];
    NSTask *attachTask = [[NSTask alloc] init];
    NSArray *attachArgs = [NSArray arrayWithObjects:@"/private/var/mobile/Media/Succession/rfs.dmg", nil];
    [attachTask setArguments:attachArgs];
    NSPipe *stdOutPipe = [NSPipe pipe];
    NSFileHandle *outPipeRead = [stdOutPipe fileHandleForReading];
    [attachTask setStandardOutput:stdOutPipe];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik"]]) {
        [self logToFile:@"Using hdik for attach" atLineNumber:__LINE__];
        [attachTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik"]];
        [attachTask launch];
        [attachTask waitUntilExit];
        NSData *outData = [outPipeRead readDataToEndOfFile];
        NSString *outString = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
        [self logToFile:[NSString stringWithFormat:@"hdik output is: %@", outString] atLineNumber:__LINE__];
        if ([outString containsString:@"disk"]) {
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
                                [self mountRestoreDisk];
                            }
                        }
                    }
                }
            } else {
                self->_theDiskString = [outLines firstObject];
            }
            
        } else {
            // I guess just try again?
            [self attachRestoreDisk];
        }
        
    } else {
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/sbin/attach"]) {
            [self logToFile:@"Using comex attach for attach" atLineNumber:__LINE__];
            [attachTask setLaunchPath:@"/usr/sbin/attach"];
            [attachTask launch];
            [attachTask waitUntilExit];
            NSData *outData = [outPipeRead readDataToEndOfFile];
            NSString *outString = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
            [self logToFile:[NSString stringWithFormat:@"attach output is: %@", outString] atLineNumber:__LINE__];
            NSArray *outLines = [outString componentsSeparatedByString:[NSString stringWithFormat:@"\n"]];
            [self logToFile:[NSString stringWithFormat:@"%@\n\n%lu", [outLines componentsJoinedByString:@", "], (unsigned long)[outLines count]] atLineNumber:__LINE__];
            if ([outLines count] != 2) {
                for (NSString *line in outLines) {
                    [self logToFile:[NSString stringWithFormat:@"current line is %@", line]  atLineNumber:__LINE__];
                    if ([line containsString:@"s3"]) {
                        [self logToFile:[NSString stringWithFormat:@"found attached diskname %@", line] atLineNumber:__LINE__];
                        self->_theDiskString = [NSMutableString stringWithString:line];
                        [self logToFile:[NSString stringWithFormat:@"sending %@ to mountRestoreDisk", self->_theDiskString] atLineNumber:__LINE__];
                        [self mountRestoreDisk];
                    }
                }
            } else {
                self->_theDiskString = [outLines firstObject];
            }
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

-(void) mountRestoreDisk{
    [self logToFile:@"mountRestoreDisk called!" atLineNumber:__LINE__];
    if ([_theDiskString hasSuffix:@"s2s1s2s1"]) {
        [self logToFile:[NSString stringWithFormat:@"theDiskString %@ has been double-apended, correcting", _theDiskString] atLineNumber:__LINE__];
        _theDiskString = [NSMutableString stringWithString:[_theDiskString stringByReplacingOccurrencesOfString:@"s2s1s2s1" withString:@""]];
        _theDiskString = [NSMutableString stringWithString:[_theDiskString stringByAppendingString:@"s2s1"]];
        [self logToFile:[NSString stringWithFormat:@"corrected theDiskString is now %@", _theDiskString] atLineNumber:__LINE__];
    }
    if (![_theDiskString hasPrefix:@"/dev/"]) {
        [self logToFile:[NSString stringWithFormat:@"creating pathname /dev/%@ from %@", _theDiskString, _theDiskString] atLineNumber:__LINE__];
        _theDiskString = [NSMutableString stringWithFormat:@"/dev/%@", _theDiskString];
    }
    if ([self isMountPointPresent]) {
        [self logToFile:[NSString stringWithFormat:@"mountpoint is present! mounting %@ type disk %@ to mountpoint", _filesystemType, _theDiskString] atLineNumber:__LINE__];
        NSArray *mountArgs = [NSArray arrayWithObjects:@"-o", @"ro", _theDiskString, @"/private/var/MobileSoftwareUpdate/mnt1", nil];
        NSTask *mountTask = [[NSTask alloc] init];
        if ([_filesystemType isEqualToString:@"hfs"]) {
            [mountTask setLaunchPath:@"/sbin/mount_hfs"];
        } else if ([_filesystemType isEqualToString:@"apfs"]) {
            [mountTask setLaunchPath:@"/sbin/mount_apfs"];
        } else {
            [self errorAlert:@"Failed to identify binary for mountTask"];
        }
        [mountTask setArguments:mountArgs];
        NSPipe *outputPipe = [NSPipe pipe];
        [mountTask setStandardOutput:outputPipe];
        NSFileHandle *stdoutHandle = [outputPipe fileHandleForReading];
        [mountTask launch];
        [mountTask waitUntilExit];
        NSString *stringRead = [[NSString alloc] initWithData:[stdoutHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
        [self logToFile:[NSString stringWithFormat:@"mount output: %@", stringRead] atLineNumber:__LINE__];
        if ([stringRead containsString:@"error"]) {
            [self errorAlert:[NSString stringWithFormat:@"Failed to mount DMG:\n%@", stringRead]];
        } else {
            [self logToFile:@"Verifying successful mount" atLineNumber:__LINE__];
            if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
                [self logToFile:@"Mounted successfully, updating UI" atLineNumber:__LINE__];
                [self logToFile:@"mounting complete!" atLineNumber:__LINE__];
                [[self headerLabel] setText:@"WARNING!!!"];
                [[self infoLabel] setHidden:FALSE];
                [[self fileListActivityIndicator] setHidden:TRUE];
                [[self startRestoreButton] setHidden:FALSE];
            }
            
        }
    }
}

-(BOOL)isMountPointPresent{
    [self logToFile:@"isMountPointPresent called!" atLineNumber:__LINE__];
    NSError *err;
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1" isDirectory:&isDir]) {
        [self logToFile:@"mountpoint is present" atLineNumber:__LINE__];
        if (isDir) {
            [self logToFile:@"mountpoint is present and is dir, we're done here" atLineNumber:__LINE__];
            return TRUE;
        } else {
            [self logToFile:@"file is present at mountpoint, deleting..." atLineNumber:__LINE__];
            [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/MobileSoftwareUpdate/mnt1" error:&err];
            [self logToFile:@"file deleted, creating empty dir..." atLineNumber:__LINE__];
            [[NSFileManager defaultManager] createDirectoryAtPath:@"/private/var/MobileSoftwareUpdate/mnt1" withIntermediateDirectories:TRUE attributes:nil error:&err];
            [self logToFile:@"dir created, verifying..." atLineNumber:__LINE__];
            if (!err) {
                [self logToFile:@"mountpoint verified, returning TRUE for isMountPointPresent" atLineNumber:__LINE__];
                return TRUE;
            } else {
                [self errorAlert:[NSString stringWithFormat:@"Failed to create /private/var/MobileSoftwareUpdate/mnt1:\n%@", [err localizedDescription]]];
                return FALSE;
            }
        }
    } else {
        [self logToFile:@"no file or dir at mountpoint, creating an empty dir..." atLineNumber:__LINE__];
        [self logToFile:@"MobileSoftwareUpdate mountpoint not present, proceeding with dirty tricks" atLineNumber:__LINE__];
        [[NSFileManager defaultManager] copyItemAtPath:@"/private/var/MobileSoftwareUpdate/" toPath:@"/private/var/COPY/" error:&err];
        [[NSFileManager defaultManager] createDirectoryAtPath:@"/private/var/COPY/mnt1" withIntermediateDirectories:TRUE attributes:nil error:&err];
        [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/MobileSoftwareUpdate/" error:&err];
        [[NSFileManager defaultManager] moveItemAtPath:@"/private/var/COPY/" toPath:@"/private/var/MobileSoftwareUpdate/" error:&err];
        if (!err) {
            [self logToFile:@"dirty tricks succeeded, returning TRUE for isMountPointPresent" atLineNumber:__LINE__];
            return TRUE;
        } else {
            [self errorAlert:[NSString stringWithFormat:@"Dirty trick failed with error: %@", [err localizedDescription]]];
            return FALSE;
        }
    }
}
-(void)successionRestore{
    [self logToFile:@"successionRestore called!" atLineNumber:__LINE__];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[[NSString stringWithFormat:@"/private/var/MobileSoftwareUpdate/mnt1"] stringByAppendingPathComponent:@"sbin"] stringByAppendingPathComponent:@"launchd"]]) {
        [self logToFile:@"verified filesystem is mounted" atLineNumber:__LINE__];
        NSMutableArray *rsyncMutableArgs = [NSMutableArray arrayWithObjects:@"-vaxcH",
                                            @"--delete",
                                            @"--progress",
                                            @"--ignore-errors",
                                            @"--force",
                                            @"--exclude=/Developer",
                                            @"--exclude=/System/Library/Caches/com.apple.kernelcaches/kernelcache",
                                            @"--exclude=/System/Library/Caches/apticket.der",
                                            @"--exclude=System/Library/Caches/com.apple.factorydata/",
                                            @"--exclude=/usr/standalone/firmware/sep-firmware.img4",
                                            @"--exclude=/usr/local/standalone/firmware/Baseband",
                                            @"--exclude=/private/var/MobileSoftwareUpdate/mnt1/",
                                            @"--exclude=/private/etc/fstab",
                                            @"--exclude=/etc/fstab",
                                            @"--exclude=/usr/standalone/firmware/FUD/",
                                            @"--exclude=/usr/standalone/firmware/Savage/",
                                            @"--exclude=/System/Library/Pearl",
                                            @"--exclude=/usr/standalone/firmware/Yonkers/",
                                            @"--exclude=/private/var/containers/",
                                            @"--exclude=/var/containers/",
                                            @"--exclude=/private/var/keybags/",
                                            @"--exclude=/var/keybags/",
                                            @"--exclude=/applelogo",
                                            @"--exclude=/devicetree",
                                            @"--exclude=/kernelcache",
                                            @"--exclude=/ramdisk",
                                            @"--exclude=/usr/libexec/xpcproxy",
                                            @"--exclude=/Library/Caches/xpcproxy",
                                            @"--exclude=/tmp/xpcproxy",
                                            @"--exclude=/var/tmp/xpcproxy",
                                            @"/private/var/MobileSoftwareUpdate/mnt1/.",
                                            @"/", nil];
        if (![_filesystemType isEqualToString:@"apfs"]) {
            [self logToFile:@"non-APFS detected, excluding dyld-shared-cache to prevent running out of storage" atLineNumber:__LINE__];
            [rsyncMutableArgs addObject:@"--exclude=/System/Library/Caches/com.apple.dyld/"];
        }
        if ([[_successionPrefs objectForKey:@"dry-run"] isEqual:@(1)]) {
            [self logToFile:@"test mode is enabled, performing dry run rsync" atLineNumber:__LINE__];
            [rsyncMutableArgs addObject:@"--dry-run"];
        }
        if ([[_successionPrefs objectForKey:@"update-install"] isEqual:@(1)]) {
            [self logToFile:@"update install mode enabled, excluding user data and uicache" atLineNumber:__LINE__];
            [rsyncMutableArgs addObject:@"--exclude=/var"];
            [rsyncMutableArgs addObject:@"--exclude=/private/var/"];
            [rsyncMutableArgs addObject:@"--exclude=/usr/bin/uicache"];
        }
        if ([[_successionPrefs objectForKey:@"create_APFS_orig-fs"] isEqual:@(1)]) {
            [self logToFile:@"user elected to create new orig-fs after restore, excluding snappy" atLineNumber:__LINE__];
            [rsyncMutableArgs addObject:@"--exclude=/usr/bin/snappy"];
        }
        [self logToFile:[NSString stringWithFormat:@"rsync %@", [rsyncMutableArgs componentsJoinedByString:@" "]] atLineNumber:__LINE__];
        NSArray *rsyncArgs = [NSArray arrayWithArray:rsyncMutableArgs];
        NSTask *rsyncTask = [[NSTask alloc] init];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[_successionPrefs objectForKey:@"custom_rsync_path"]]) {
            [self logToFile:[NSString stringWithFormat:@"found rsync at path: %@", [_successionPrefs objectForKey:@"custom_rsync_path"]] atLineNumber:__LINE__];
            [rsyncTask setLaunchPath:[_successionPrefs objectForKey:@"custom_rsync_path"]];
        } else {
            [self logToFile:[NSString stringWithFormat:@"couldnt find rsync at path %@, checking /usr/bin/rsync to see if user accidentally changed preferences", [_successionPrefs objectForKey:@"custom_rsync_path"]] atLineNumber:__LINE__];
            if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/rsync"]) {
                UIAlertController *rsyncNotFound = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Unable to find rsync at custom path %@", [_successionPrefs objectForKey:@"custom_rsync_path"]]message:@"/usr/bin/rsync will be used" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
                [rsyncNotFound addAction:useDefualtPathAction];
                [self presentViewController:rsyncNotFound animated:TRUE completion:nil];
                [self logToFile:@"found rsync at default path, using /usr/bin/rsync" atLineNumber:__LINE__];
                [rsyncTask setLaunchPath:@"/usr/bin/rsync"];
            } else {
                [self logToFile:@"unable to find rysnc at user-specified path or custom path, asking to reinstall rsync" atLineNumber:__LINE__];
                [self errorAlert:[NSString stringWithFormat:@"Unable to find rsync at custom path %@\nPlease check your custom path in Succession's settings or install rsync from Cydia", [_successionPrefs objectForKey:@"custom_rsync_path"]]];
            }
        }
        [rsyncTask setArguments:rsyncArgs];
        NSPipe *outputPipe = [NSPipe pipe];
        [rsyncTask setStandardOutput:outputPipe];
        NSFileHandle *stdoutHandle = [outputPipe fileHandleForReading];
        [stdoutHandle waitForDataInBackgroundAndNotify];
        id observer;
        observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification
                                                                     object:stdoutHandle queue:nil
                                                                 usingBlock:^(NSNotification *note)
                    {
            
            NSData *dataRead = [stdoutHandle availableData];
            NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
            [self logToFile:stringRead atLineNumber:__LINE__];
            [[self infoLabel] setText:@"Restoring, please wait..."];
            [[self headerLabel] setText:@"Progress bar may freeze for long periods of time, it's still working, leave it alone until your device reboots."];
            [[self headerLabel] setHidden:FALSE];
            if ([stringRead containsString:@"cannot delete non-empty directory"] && [stringRead containsString:@"Applications/"]) {
                [self errorAlert:@"Succession has failed due to an issue with rsync. I don't know what caused this, sorry. You can follow the discussion of this issue at https://github.com/SuccessionRestore/issues/44"];
                [rsyncTask terminate];
            }
            NSArray *stringWords = [stringRead componentsSeparatedByString:@" "];
            for (NSString *word in stringWords) {
                if ([word hasPrefix:@"Applications/"] || [word hasPrefix:@"bin/"] || [word containsString:@"dev/"] || [word hasPrefix:@"Library/"] || [word containsString:@"private/"]|| [word containsString:@"sbin/"] || [word hasPrefix:@"System/"] || [word hasPrefix:@"usr/"]) {
                    [[self fileListActivityIndicator] setHidden:TRUE];
                    [[self restoreProgressBar] setHidden:FALSE];
                    [[self outputLabel] setHidden:FALSE];
                    if ([stringRead containsString:@"deleting"]) {
                        [[self outputLabel] setText:[NSString stringWithFormat:@"Deleting from %@", word]];
                    } else {
                       [[self outputLabel] setText:[NSString stringWithFormat:@"Restoring %@", word]];
                    }
                }
            }
            if ([stringRead hasPrefix:@"Applications/"]) {
                [[self restoreProgressBar] setProgress:0];
            }
            if ([stringRead hasPrefix:@"Library/"]) {
                [[self restoreProgressBar] setProgress:0.33];
            }
            if ([stringRead hasPrefix:@"System/"]) {
                [[self restoreProgressBar] setProgress:0.67];
            }
            if ([stringRead hasPrefix:@"usr/"]) {
                [[self restoreProgressBar] setProgress:0.9];
            }
            if ([stringRead containsString:@"speedup is"] && [stringRead containsString:@"bytes"] && [stringRead containsString:@"sent"] && [stringRead containsString:@"received"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self logToFile:@"restore has completed!" atLineNumber:__LINE__];
                    [[self outputLabel] setHidden:TRUE];
                    [[self headerLabel] setText:@"Restore complete"];
                    [[self fileListActivityIndicator] setHidden:TRUE];
                    [[self restoreProgressBar] setHidden:FALSE];
                    [[self restoreProgressBar] setProgress:1.0];
                    [[NSNotificationCenter defaultCenter] removeObserver:observer];
                    if ([[self->_successionPrefs objectForKey:@"dry-run"] isEqual:@(1)]) {
                        [self logToFile:@"Test mode used, exiting..." atLineNumber:__LINE__];
                        UIAlertController *restoreCompleteController = [UIAlertController alertControllerWithTitle:@"Dry run complete!" message:@"YAY!" preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                            exit(0);
                        }];
                        [restoreCompleteController addAction:exitAction];
                        [self presentViewController:restoreCompleteController animated:TRUE completion:nil];
                    } else {
                        if ([[self->_successionPrefs objectForKey:@"hacktivation"] isEqual:@(1)]) {
                            [self logToFile:@"User chose to hacktivate device, deleting setup.app now" atLineNumber:__LINE__];
                            [[NSFileManager defaultManager] removeItemAtPath:@"/Applications/Setup.app/" error:nil];
                        }
                        if ([[self->_successionPrefs objectForKey:@"create_APFS_orig-fs"] isEqual:@(1)]) {
                            [self logToFile:@"user elected to replace orig-fs, deleting old orig-fs now" atLineNumber:__LINE__];
                            NSTask *deleteOrigFS = [[NSTask alloc] init];
                            [deleteOrigFS setLaunchPath:@"/usr/bin/snappy"];
                            NSArray *deleteOrigFSArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-d", @"orig-fs", nil];
                            [deleteOrigFS setArguments:deleteOrigFSArgs];
                            [deleteOrigFS launch];
                            [self logToFile:@"user elected to replace orig-fs, creating new orig-fs now" atLineNumber:__LINE__];
                            NSTask *createNewOrigFS = [[NSTask alloc] init];
                            [createNewOrigFS setLaunchPath:@"/usr/bin/snappy"];
                            NSArray *createNewOrigFSArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-c", @"orig-fs", nil];
                            [createNewOrigFS setArguments:createNewOrigFSArgs];
                            [createNewOrigFS launch];
                            [createNewOrigFS waitUntilExit];
                            [self logToFile:@"renaming newly created orig-fs to system snapshot name" atLineNumber:__LINE__];
                            NSTask *renameOrigFS = [[NSTask alloc] init];
                            [renameOrigFS setLaunchPath:@"/usr/bin/snappy"];
                            NSArray *renameOrigFSArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-r", @"orig-fs", @"-x", nil];
                            [renameOrigFS setArguments:renameOrigFSArgs];
                            [renameOrigFS launch];
                            [self logToFile:@"ok, we're done with snappy, deleting now" atLineNumber:__LINE__];
                            NSError *err;
                            [[NSFileManager defaultManager] removeItemAtPath:@"/usr/bin/snappy" error:&err];
                            if (err) {
                                [self logToFile:[NSString stringWithFormat:@"non-fatal error, not showing alert. unable to delete snappy: %@", [err localizedDescription]] atLineNumber:__LINE__];
                            }
                        }
                        [self logToFile:@"showing restore complete alert" atLineNumber:__LINE__];
                        UIAlertController *restoreCompleteController = [UIAlertController alertControllerWithTitle:@"Restore Succeeded!" message:@"Rebuilding icon cache, please wait..." preferredStyle:UIAlertControllerStyleAlert];
                        [self presentViewController:restoreCompleteController animated:TRUE completion:^{
                            if ([[self->_successionPrefs objectForKey:@"update-install"] isEqual:@(1)]) {
                                [self logToFile:@"Update install was used, rebuilding uicache" atLineNumber:__LINE__];
                                if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/uicache"]) {
                                    NSTask *uicacheTask = [[NSTask alloc] init];
                                    NSArray *uicacheElectraArgs = [NSArray arrayWithObjects:@"--all", nil];
                                    [uicacheTask setLaunchPath:@"/usr/bin/uicache"];
                                    [uicacheTask setArguments:uicacheElectraArgs];
                                    [uicacheTask launch];
                                    [uicacheTask waitUntilExit];
                                    [self logToFile:@"uicache complete, deleting it..." atLineNumber:__LINE__];
                                    NSError *err;
                                    [[NSFileManager defaultManager] removeItemAtPath:@"/usr/bin/uicache" error:&err];
                                    if (err) {
                                        [self logToFile:[NSString stringWithFormat:@"non-fatal error, not showing alert. unable to delete uicache: %@", [err localizedDescription]] atLineNumber:__LINE__];
                                    }
                                    reboot(0x400);
                                } else {
                                    [self logToFile:@"/usr/bin/uicache doesnt exist, oops. rebooting..." atLineNumber:__LINE__];
                                    reboot(0x400);
                                }
                            } else if ([[self->_successionPrefs objectForKey:@"dry-run"] isEqual:@(1)]){
                                [self logToFile:@"That was a test mode restore, but somehow the first check for this didnt get detected... anways, the app will just hang now..." atLineNumber:__LINE__];
                            } else {
                                extern int SBDataReset(mach_port_t, int);
                                extern mach_port_t SBSSpringBoardServerPort(void);
                                [self logToFile:[NSString stringWithFormat:@"That was a normal restore. go, mobile_obliteration! %u", SBSSpringBoardServerPort()] atLineNumber:__LINE__];
                                SBDataReset(SBSSpringBoardServerPort(), 5);
                            }
                        }];
                    }
                });
            }
            [stdoutHandle waitForDataInBackgroundAndNotify];
        }];
        [self logToFile:@"Updating UI to prepare for restore" atLineNumber:__LINE__];
        [[self infoLabel] setText:@"Working, do not leave the app..."];
        [[self headerLabel] setText:@""];
        [[self startRestoreButton] setTitle:@"Restore in progress..." forState:UIControlStateNormal];
        [[self startRestoreButton] setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [[self startRestoreButton] setEnabled:FALSE];
        [[self fileListActivityIndicator] setHidden:FALSE];
        if ([rsyncTask launchPath]) {
            [self logToFile:@"rsyncTask has a valid launchPath" atLineNumber:__LINE__];
            if ([[_successionPrefs objectForKey:@"create_APFS_orig-fs"] isEqual:@(1)] && [[_successionPrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)]) {
                [self logToFile:@"Both orig-fs and succession-prerestore are selected, these options confilct, aborting restore..." atLineNumber:__LINE__];
                UIAlertController *tooMuchAPFSAlert = [UIAlertController alertControllerWithTitle:@"Conflicting options enabled" message:@"You cannot have 'create backup snapshot' and 'create new orig-fs' enabled simultaneously, please go to Succession's settings page and disable one of the two." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self logToFile:@"restore aborted" atLineNumber:__LINE__];
                    [[self navigationController] popToRootViewControllerAnimated:TRUE];
                }];
                [tooMuchAPFSAlert addAction:dismissAction];
                [self presentViewController:tooMuchAPFSAlert animated:TRUE completion:nil];
            } else {
                [rsyncTask launch];
            }
        } else {
            [self errorAlert:@"Unable to apply launchPath to rsyncTask. Please (re)install rsync from Cydia."];
        }
    } else {
        [self errorAlert:@"Mountpoint does not contain rootfilesystem, please restart the app and try again."];
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
