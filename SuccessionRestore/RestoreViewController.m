//
//  RestoreViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 6/30/18.
//  Copyright © 2018 Sam Gardner. All rights reserved.
//

#import "RestoreViewController.h"
#include <spawn.h>
#include <sys/sysctl.h>
#import "libjb.h"
#import "unjail.h"
#import "NSTask.h"

int attach(const char *path, char buf[], size_t sz);

@interface RestoreViewController ()

@end

@implementation RestoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];
    [[self outputLabel] setHidden:TRUE];
    [[self restoreProgressBar] setHidden:TRUE];
    _successionPrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"]];
    [self prepareAttachRestoreDisk];
    [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/mobile/succession.log" error:nil];
    [self logToFile:@"RestoreViewController has loaded!" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
}

- (void) viewDidAppear:(BOOL)animated{
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
        [[self fileListActivityIndicator] setHidden:TRUE];
        [[self startRestoreButton] setTitle:@"Erase iPhone" forState:UIControlStateNormal];
    }
    if ([[[[NSFileManager defaultManager] attributesOfFileSystemForPath:@"/" error:nil] objectForKey:NSFileSystemFreeSize] unsignedLongLongValue] < 2147483648) {
        if (![[_successionPrefs objectForKey:@"delete-during"] isEqual:@(1)]) {
            UIAlertController *lowStorageAlert = [UIAlertController alertControllerWithTitle:@"Low storage space detected!" message:[NSString stringWithFormat:@"It is reccommended that you use low-storage mode to prevent the device from running out of storage while Succesion is running\nNote that if Succession exits while it is running, it is more likely to fail destructively, so... don't exit Succession, and you might want to run it from safe mode."] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *useLowStorageModeAction = [UIAlertAction actionWithTitle:@"Use low storage mode" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self->_successionPrefs setObject:@(1) forKey:@"delete-during"];
                [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
                [self->_successionPrefs writeToFile:@"/private/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
            }];
            UIAlertAction *useDefaultSettingsAction = [UIAlertAction actionWithTitle:@"Perform restore normally" style:UIAlertActionStyleCancel handler:nil];
            [lowStorageAlert addAction:useLowStorageModeAction];
            [lowStorageAlert addAction:useDefaultSettingsAction];
            [self presentViewController:lowStorageAlert animated:TRUE completion:nil];
        }
    }
}

- (IBAction)startRestoreButtonAction:(id)sender {
    [self logToFile:@"startRestoreButtonAction called" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
    if ([[_successionPrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)] || [[_successionPrefs objectForKey:@"create_APFS_orig-fs"] isEqual:@(1)]) {
        [self logToFile:@"snappy operations enabled" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
        if (kCFCoreFoundationVersionNumber > 1349.56) {
            [self logToFile:@"ios version compatible with snappy" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/snappy"]) {
                [self logToFile:@"snappy not installed, asking to install it" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                UIAlertController *needSnappy = [UIAlertController alertControllerWithTitle:@"Snappy required" message:@"Your current preferences indicate you would like to perform operations with APFS snapshots, but you do not have snappy installed. Please install snappy from https://repo.bingner.com" preferredStyle:UIAlertControllerStyleAlert];
                NSString *sources = [NSString stringWithContentsOfFile:@"/etc/apt/sources.list.d/cydia.list" encoding:NSUTF8StringEncoding error:nil];
                if (![sources containsString:@"bingner.com"]) {
                    UIAlertAction *addRepo = [UIAlertAction actionWithTitle:@"Add repository to cydia" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://cydia.saurik.com/api/share#?source=https://repo.bingner.com/"] options:URLOptions completionHandler:nil];
                        [self logToFile:@"user adding source for snappy" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                    }];
                    [needSnappy addAction:addRepo];
                }
                UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
                [needSnappy addAction:dismissAction];
                [self presentViewController:needSnappy animated:TRUE completion:nil];
            } else {
                [self logToFile:@"snappy requested and already installed" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
                    [self logToFile:@"filesystem is mounted, asking user to confirm they are ready to restore" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                    UIAlertController *areYouSureAlert = [UIAlertController alertControllerWithTitle:@"Are you sure you would like to begin restoring" message:@"You will not be able to leave the app during the process" preferredStyle:UIAlertControllerStyleActionSheet];
                    UIAlertAction *beginRestore = [UIAlertAction actionWithTitle:@"Begin restore" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        [self logToFile:@"user wants to begin restore now, checking battery level" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                        [[UIDevice currentDevice] setBatteryMonitoringEnabled:TRUE];
                        if ([[UIDevice currentDevice] batteryLevel] > 0.5) {
                            [self logToFile:[NSString stringWithFormat:@"battery level is %f which is greater than 50%%, ready to go", [[UIDevice currentDevice] batteryLevel]] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                            if ([[self->_successionPrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)]) {
                                NSTask *deletePreviousBackupSnapTask = [[NSTask alloc] init];
                                [deletePreviousBackupSnapTask setLaunchPath:@"/usr/bin/snappy"];
                                NSArray *deletePreviousBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-d", @"succession-prerestore", nil];
                                [deletePreviousBackupSnapTask setArguments:deletePreviousBackupSnapTaskArgs];
                                [self logToFile:@"user elected to create succession-prerestore snapshot, deleting already present succession-prerestore" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                [deletePreviousBackupSnapTask launch];
                                NSTask *createBackupSnapTask = [[NSTask alloc] init];
                                [createBackupSnapTask setLaunchPath:@"/usr/bin/snappy"];
                                NSArray *createBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-c", @"succession-prerestore", nil];
                                [createBackupSnapTask setArguments:createBackupSnapTaskArgs];
                                [self logToFile:@"creating new succession-prerestore" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                [createBackupSnapTask launch];
                            }
                            [self successionRestore];
                        } else {
                            [self logToFile:[NSString stringWithFormat:@"battery is %f which is less than 50%%, warning user", [[UIDevice currentDevice] batteryLevel]] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                            UIAlertController *lowBatteryWarning = [UIAlertController alertControllerWithTitle:@"Low Battery" message:@"It is recommended you have at least 50% battery charge before beginning restore" preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *cancelRestoreAction = [UIAlertAction actionWithTitle:@"Abort restore" style:UIAlertActionStyleDefault handler:nil];
                            UIAlertAction *startRestoreAction = [UIAlertAction actionWithTitle:@"Restore anyways" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                                [self logToFile:@"user chose to override battery warning, restoring now" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                if ([[self->_successionPrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)]) {
                                    NSTask *deletePreviousBackupSnapTask = [[NSTask alloc] init];
                                    [deletePreviousBackupSnapTask setLaunchPath:@"/usr/bin/snappy"];
                                    NSArray *deletePreviousBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-d", @"succession-prerestore", nil];
                                    [deletePreviousBackupSnapTask setArguments:deletePreviousBackupSnapTaskArgs];
                                    [self logToFile:@"user elected to create succession-prerestore snapshot, deleting already present succession-prerestore" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                    [deletePreviousBackupSnapTask launch];
                                    NSTask *createBackupSnapTask = [[NSTask alloc] init];
                                    [createBackupSnapTask setLaunchPath:@"/usr/bin/snappy"];
                                    NSArray *createBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-c", @"succession-prerestore", nil];
                                    [createBackupSnapTask setArguments:createBackupSnapTaskArgs];
                                    [self logToFile:@"creating new succession-prerestore" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                    [createBackupSnapTask launch];
                                }
                                [self successionRestore];
                            }];
                            [lowBatteryWarning addAction:cancelRestoreAction];
                            [lowBatteryWarning addAction:startRestoreAction];
                            [self presentViewController:lowBatteryWarning animated:TRUE completion:nil];
                        }
                        [[UIDevice currentDevice] setBatteryMonitoringEnabled:FALSE];
                    }];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                    [areYouSureAlert addAction:beginRestore];
                    [areYouSureAlert addAction:cancelAction];
                    [self presentViewController:areYouSureAlert animated:TRUE completion:nil];
                } else {
                    [self logToFile:@"Filesystem is not mounted, showing mount alert now" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                    UIAlertController *mountingAlert = [UIAlertController alertControllerWithTitle:@"Mounting filesystem..." message:@"Tap OK to continue." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                    [mountingAlert addAction:okAction];
                    [self presentViewController:mountingAlert animated:TRUE completion:^{
                        [self logToFile:[NSString stringWithFormat:@"mountingAlert handler called, identified theDiskString as %@", self->_theDiskString] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                        if ([[NSFileManager defaultManager] fileExistsAtPath:[self->_theDiskString stringByAppendingString:@"s2s1"]]) {
                            self->_theDiskString = [NSMutableString stringWithString:[self->_theDiskString stringByAppendingString:@"s2s1"]];
                            [self logToFile:[NSString stringWithFormat:@"sending %@ to mountRestoreDisk", self->_theDiskString] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                            [self mountRestoreDisk];
                        } else if ([[NSFileManager defaultManager] fileExistsAtPath:[self->_theDiskString stringByAppendingString:@"s2"]]){
                            self->_theDiskString = [NSMutableString stringWithString:[self->_theDiskString stringByAppendingString:@"s2"]];
                            [self logToFile:[NSString stringWithFormat:@"sending %@ to mountRestoreDisk", self->_theDiskString] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                            [self mountRestoreDisk];
                        } else {
                            [self errorAlert:[NSString stringWithFormat:@"unable to identify theDisk, neither %@ or %@ existed", [self->_theDiskString stringByAppendingString:@"s2s1"], [self->_theDiskString stringByAppendingString:@"s2"]]];
                        }
                    }];
                }
            }
        } else {
            [self logToFile:@"apfs snapshot operations enabled, but iOS version not compatible with snappy" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            UIAlertController *snapshotsNotSupported = [UIAlertController alertControllerWithTitle:@"APFS operations not supported" message:@"You must be running iOS 10.3 or higher to use APFS features." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismis" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self logToFile:@"user disabled snappy options" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
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
        [self logToFile:@"no apfs snapshot operations requested" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
            [self logToFile:@"filesystem is mounted, asking user to confirm they are ready to restore" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            UIAlertController *areYouSureAlert = [UIAlertController alertControllerWithTitle:@"Are you sure you would like to begin restoring" message:@"You will not be able to leave the app during the process" preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *beginRestore = [UIAlertAction actionWithTitle:@"Begin restore" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self logToFile:@"user wants to begin restore now, checking battery level" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                [[UIDevice currentDevice] setBatteryMonitoringEnabled:TRUE];
                if ([[UIDevice currentDevice] batteryLevel] > 0.5) {
                    [self logToFile:[NSString stringWithFormat:@"battery level is %f which is greater than 50%%, ready to go", [[UIDevice currentDevice] batteryLevel]] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                    if ([[self->_successionPrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)]) {
                        NSTask *deletePreviousBackupSnapTask = [[NSTask alloc] init];
                        [deletePreviousBackupSnapTask setLaunchPath:@"/usr/bin/snappy"];
                        NSArray *deletePreviousBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-d", @"succession-prerestore", nil];
                        [deletePreviousBackupSnapTask setArguments:deletePreviousBackupSnapTaskArgs];
                        [self logToFile:@"user elected to create succession-prerestore snapshot, deleting already present succession-prerestore" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                        [deletePreviousBackupSnapTask launch];
                        NSTask *createBackupSnapTask = [[NSTask alloc] init];
                        [createBackupSnapTask setLaunchPath:@"/usr/bin/snappy"];
                        NSArray *createBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-c", @"succession-prerestore", nil];
                        [createBackupSnapTask setArguments:createBackupSnapTaskArgs];
                        [self logToFile:@"creating new succession-prerestore" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                        [createBackupSnapTask launch];
                    }
                    [self successionRestore];
                } else {
                    [self logToFile:[NSString stringWithFormat:@"battery is %f which is less than 50%%, warning user", [[UIDevice currentDevice] batteryLevel]] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                    UIAlertController *lowBatteryWarning = [UIAlertController alertControllerWithTitle:@"Low Battery" message:@"It is recommended you have at least 50% battery charge before beginning restore" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelRestoreAction = [UIAlertAction actionWithTitle:@"Abort restore" style:UIAlertActionStyleDefault handler:nil];
                    UIAlertAction *startRestoreAction = [UIAlertAction actionWithTitle:@"Restore anyways" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        [self logToFile:@"user chose to override battery warning, restoring now" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                        if ([[self->_successionPrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)]) {
                            NSTask *deletePreviousBackupSnapTask = [[NSTask alloc] init];
                            [deletePreviousBackupSnapTask setLaunchPath:@"/usr/bin/snappy"];
                            NSArray *deletePreviousBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-d", @"succession-prerestore", nil];
                            [deletePreviousBackupSnapTask setArguments:deletePreviousBackupSnapTaskArgs];
                            [self logToFile:@"user elected to create succession-prerestore snapshot, deleting already present succession-prerestore" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                            [deletePreviousBackupSnapTask launch];
                            NSTask *createBackupSnapTask = [[NSTask alloc] init];
                            [createBackupSnapTask setLaunchPath:@"/usr/bin/snappy"];
                            NSArray *createBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-c", @"succession-prerestore", nil];
                            [createBackupSnapTask setArguments:createBackupSnapTaskArgs];
                            [self logToFile:@"creating new succession-prerestore" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                            [createBackupSnapTask launch];
                        }
                        [self successionRestore];
                    }];
                    [lowBatteryWarning addAction:cancelRestoreAction];
                    [lowBatteryWarning addAction:startRestoreAction];
                    [self presentViewController:lowBatteryWarning animated:TRUE completion:nil];
                }
                [[UIDevice currentDevice] setBatteryMonitoringEnabled:FALSE];
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [areYouSureAlert addAction:beginRestore];
            [areYouSureAlert addAction:cancelAction];
            [self presentViewController:areYouSureAlert animated:TRUE completion:nil];
        } else {
            [self logToFile:@"Filesystem is not mounted, showing mount alert now" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            UIAlertController *mountingAlert = [UIAlertController alertControllerWithTitle:@"Mounting filesystem..." message:@"Tap OK to continue." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [mountingAlert addAction:okAction];
            [self presentViewController:mountingAlert animated:TRUE completion:^{
                [self logToFile:[NSString stringWithFormat:@"mountingAlert handler called, identified theDiskString as %@", self->_theDiskString] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:[self->_theDiskString stringByAppendingString:@"s2s1"]]) {
                    self->_theDiskString = [NSMutableString stringWithString:[self->_theDiskString stringByAppendingString:@"s2s1"]];
                    [self logToFile:[NSString stringWithFormat:@"sending %@ to mountRestoreDisk", self->_theDiskString] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                    [self mountRestoreDisk];
                } else if ([[NSFileManager defaultManager] fileExistsAtPath:[self->_theDiskString stringByAppendingString:@"s2"]]){
                    self->_theDiskString = [NSMutableString stringWithString:[self->_theDiskString stringByAppendingString:@"s2"]];
                    [self logToFile:[NSString stringWithFormat:@"sending %@ to mountRestoreDisk", self->_theDiskString] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                    [self mountRestoreDisk];
                } else {
                    [self errorAlert:[NSString stringWithFormat:@"unable to identify theDisk, neither %@ or %@ existed", [self->_theDiskString stringByAppendingString:@"s2s1"], [self->_theDiskString stringByAppendingString:@"s2"]]];
                }
            }];
        }
    }
}

- (void) prepareAttachRestoreDisk{
    [self logToFile:@"prepareAttachRestoreDisk called!" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
    NSError *err;
    NSString *fstab = [NSString stringWithContentsOfFile:@"/etc/fstab" encoding:NSUTF8StringEncoding error:&err];
    if (!err) {
        [self logToFile:[NSString stringWithFormat:@"Read fstab! %@", fstab] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
        if ([fstab containsString:@"hfs"]) {
            _filesystemType = @"hfs";
            [self logToFile:[NSString stringWithFormat:@"Identified filesystem type as HFS! %@", _filesystemType] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            [self attachRestoreDisk];
        } else if ([fstab containsString:@"apfs"]) {
            _filesystemType = @"apfs";
            [self logToFile:[NSString stringWithFormat:@"Identified filesystem type as APFS! %@", _filesystemType] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            [self attachRestoreDisk];
        } else {
            [self errorAlert:[NSString stringWithFormat:@"Unable to determine APFS or HFS:\n%@", fstab]];
        }
    } else {
        [self errorAlert:[NSString stringWithFormat:@"Failed to read fstab: %@", [err localizedDescription]]];
    }
}

- (void) attachRestoreDisk {
    [self logToFile:@"attachRestoreDisk called!" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
    char theDisk[11];
    NSString *pathToDMG = @"/private/var/mobile/Media/Succession/rfs.dmg";
    attach([pathToDMG UTF8String], theDisk, sizeof(theDisk));
    _theDiskString = [NSMutableString stringWithString:[NSString stringWithFormat:@"%s", theDisk]];
    [self logToFile:[NSString stringWithFormat:@"attached to %s aka %@", theDisk, _theDiskString] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
}

-(void) mountRestoreDisk{
    [self logToFile:@"mountRestoreDisk called!" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
    if ([self isMountPointPresent]) {
        [self logToFile:[NSString stringWithFormat:@"mountpoint is present! mounting %@ type disk %@ to mountpoint", _filesystemType, _theDiskString] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
        NSArray *mountArgs = [NSArray arrayWithObjects:@"-t", _filesystemType, @"-o", @"ro", _theDiskString, @"/private/var/MobileSoftwareUpdate/mnt1", nil];
        NSTask *mountTask = [[NSTask alloc] init];
        mountTask.launchPath = @"/sbin/mount";
        mountTask.arguments = mountArgs;
        [mountTask launch];
        [self logToFile:@"mounting complete!" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
    }
}

-(BOOL)isMountPointPresent{
    [self logToFile:@"isMountPointPresent called!" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
    NSError *err;
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1" isDirectory:&isDir]) {
        [self logToFile:@"mountpoint is present" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
        if (isDir) {
            [self logToFile:@"mountpoint is present and is dir, we're done here" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            return TRUE;
        } else {
            [self logToFile:@"file is present at mountpoint, deleting..." atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/MobileSoftwareUpdate/mnt1" error:&err];
            [self logToFile:@"file deleted, creating empty dir..." atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            [[NSFileManager defaultManager] createDirectoryAtPath:@"/private/var/MobileSoftwareUpdate/mnt1" withIntermediateDirectories:TRUE attributes:nil error:&err];
            [self logToFile:@"dir created, verifying..." atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            if (!err) {
                [self logToFile:@"mountpoint verified, returning TRUE for isMountPointPresent" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                return TRUE;
            } else {
                [self errorAlert:[err localizedDescription]];
                return FALSE;
            }
        }
    } else {
        [self logToFile:@"no file or dir at mountpoint, creating an empty dir..." atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
        [[NSFileManager defaultManager] createDirectoryAtPath:@"/private/var/MobileSoftwareUpdate/mnt1" withIntermediateDirectories:TRUE attributes:nil error:&err];
        [self logToFile:@"dir created, verifying..." atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
        if (!err) {
            [self logToFile:@"mountpoint verified, returning TRUE for isMountPointPresent" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            return TRUE;
        } else {
            [self errorAlert:[err localizedDescription]];
            return FALSE;
        }
    }
}
-(void)successionRestore{
    [self logToFile:@"successionRestore called!" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
        [self logToFile:@"verified filesystem is mounted" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
        NSMutableArray *rsyncMutableArgs = [NSMutableArray arrayWithObjects:@"-vaxcH",
                                            @"--delete-after",
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
                                            @"--exclude=/var/MobileSoftwareUpdate/mnt1",
                                            @"--exclude=/private/etc/fstab",
                                            @"--exclude=/etc/fstab",
                                            @"--exclude=/usr/standalone/firmware/FUD/",
                                            @"--exclude=/usr/standalone/firmware/Savage/",
                                            @"--exclude=/System/Library/Pearl",
                                            @"--exclude=/usr/standalone/firmware/Yonkers/",
                                            @"/private/var/MobileSoftwareUpdate/mnt1/.",
                                            @"/", nil];
        if (![_filesystemType isEqualToString:@"apfs"]) {
            [self logToFile:@"non-APFS detected, excluding dyld-shared-cache to prevent running out of storage" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            [rsyncMutableArgs addObject:@"--exclude=/System/Library/Caches/com.apple.dyld/"];
        }
        if ([[_successionPrefs objectForKey:@"dry-run"] isEqual:@(1)]) {
            [self logToFile:@"test mode is enabled, performing dry run rsync" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            [rsyncMutableArgs addObject:@"--dry-run"];
        }
        if ([[_successionPrefs objectForKey:@"update-install"] isEqual:@(1)]) {
            [self logToFile:@"update install mode enabled, excluding user data and uicache" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            [rsyncMutableArgs addObject:@"--exclude=/var"];
            [rsyncMutableArgs addObject:@"--exclude=/private/var/"];
            [rsyncMutableArgs addObject:@"--exclude=/usr/bin/uicache"];
        }
        if ([[_successionPrefs objectForKey:@"delete-during"] isEqual:@(1)]) {
            [self logToFile:@"delete-during enabled" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            [rsyncMutableArgs removeObject:@"--delete-after"];
            [rsyncMutableArgs addObject:@"--delete"];
        }
        if ([[_successionPrefs objectForKey:@"create_APFS_orig-fs"] isEqual:@(1)]) {
            [self logToFile:@"user elected to create new orig-fs after restore, excluding snappy" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            [rsyncMutableArgs addObject:@"--exclude=/usr/bin/snappy"];
        }
        [self logToFile:[NSString stringWithFormat:@"rsync %@", [rsyncMutableArgs componentsJoinedByString:@" "]] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
        NSArray *rsyncArgs = [NSArray arrayWithArray:rsyncMutableArgs];
        NSTask *rsyncTask = [[NSTask alloc] init];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[_successionPrefs objectForKey:@"custom_rsync_path"]]) {
            [self logToFile:[NSString stringWithFormat:@"found rsync at path: %@", [_successionPrefs objectForKey:@"custom_rsync_path"]] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            [rsyncTask setLaunchPath:[_successionPrefs objectForKey:@"custom_rsync_path"]];
        } else {
            [self logToFile:[NSString stringWithFormat:@"couldnt find rsync at path %@, checking /usr/bin/rsync to see if user accidentally changed preferences", [_successionPrefs objectForKey:@"custom_rsync_path"]] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/rsync"]) {
                UIAlertController *rsyncNotFound = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Unable to find rsync at custom path %@", [_successionPrefs objectForKey:@"custom_rsync_path"]]  message:@"/usr/bin/rsync will be used" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
                [rsyncNotFound addAction:useDefualtPathAction];
                [self presentViewController:rsyncNotFound animated:TRUE completion:nil];
                [self logToFile:@"found rsync at default path, using /usr/bin/rsync" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                [rsyncTask setLaunchPath:@"/usr/bin/rsync"];
            } else {
                [self logToFile:@"unable to find rysnc at user-specified path or custom path, asking to reinstall rsync" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
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
            [self logToFile:stringRead atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            [[self infoLabel] setText:@"Restoring, please wait..."];
            [[self headerLabel] setText:@"Progress bar may freeze for long periods of time, it's still working, leave it alone until your device reboots."];
            [[self headerLabel] setHighlighted:FALSE];
            if ([stringRead containsString:@"00 files..."]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self outputLabel] setHidden:FALSE];
                    [[self outputLabel] setText:stringRead];
                    [[self fileListActivityIndicator] setHidden:FALSE];
                    [[self restoreProgressBar] setHidden:TRUE];
                });
            }
            if ([stringRead hasPrefix:@"Applications/"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self outputLabel] setHidden:FALSE];
                    [[self outputLabel] setText:[NSString stringWithFormat:@"%@\nRebuilding Applications...", stringRead]];
                    [[self fileListActivityIndicator] setHidden:TRUE];
                    [[self restoreProgressBar] setHidden:FALSE];
                    [[self restoreProgressBar] setProgress:0];
                });
            }
            if ([stringRead hasPrefix:@"Library/"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self outputLabel] setHidden:FALSE];
                    [[self outputLabel] setText:[NSString stringWithFormat:@"%@\nRebuilding Library...", stringRead]];
                    [[self fileListActivityIndicator] setHidden:TRUE];
                    [[self restoreProgressBar] setHidden:FALSE];
                    [[self restoreProgressBar] setProgress:0.33];
                });
            }
            if ([stringRead hasPrefix:@"System/"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self outputLabel] setHidden:FALSE];
                    [[self outputLabel] setText:[NSString stringWithFormat:@"%@\nRebuilding System...", stringRead]];
                    [[self fileListActivityIndicator] setHidden:TRUE];
                    [[self restoreProgressBar] setHidden:FALSE];
                    [[self restoreProgressBar] setProgress:0.67];
                });
            }
            if ([stringRead hasPrefix:@"usr/"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self outputLabel] setHidden:FALSE];
                    [[self outputLabel] setText:[NSString stringWithFormat:@"%@\nRebuilding usr...", stringRead]];
                    [[self fileListActivityIndicator] setHidden:TRUE];
                    [[self restoreProgressBar] setHidden:FALSE];
                    [[self restoreProgressBar] setProgress:0.9];
                });
            }
            if ([stringRead containsString:@"speedup is"] && [stringRead containsString:@"bytes"] && [stringRead containsString:@"sent"] && [stringRead containsString:@"received"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self logToFile:@"restore has completed!" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                    [[self outputLabel] setHidden:TRUE];
                    [[self headerLabel] setText:@"Restore complete"];
                    [[self fileListActivityIndicator] setHidden:TRUE];
                    [[self restoreProgressBar] setHidden:FALSE];
                    [[self restoreProgressBar] setProgress:1.0];
                    [[NSNotificationCenter defaultCenter] removeObserver:observer];
                    if ([[self->_successionPrefs objectForKey:@"dry-run"] isEqual:@(1)]) {
                        [self logToFile:@"Test mode used, exiting..." atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                        UIAlertController *restoreCompleteController = [UIAlertController alertControllerWithTitle:@"Dry run complete!" message:@"YAY!" preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        exit(0);
                        }];
                        [restoreCompleteController addAction:exitAction];
                        [self presentViewController:restoreCompleteController animated:TRUE completion:nil];
                    } else {
                        if ([[self->_successionPrefs objectForKey:@"create_APFS_orig-fs"] isEqual:@(1)]) {
                            [self logToFile:@"user elected to replace orig-fs, deleting old orig-fs now" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                            NSTask *deleteOrigFS = [[NSTask alloc] init];
                            [deleteOrigFS setLaunchPath:@"/usr/bin/snappy"];
                            NSArray *deleteOrigFSArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-d", @"orig-fs", nil];
                            [deleteOrigFS setArguments:deleteOrigFSArgs];
                            [deleteOrigFS launch];
                            [self logToFile:@"user elected to replace orig-fs, creating new orig-fs now" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                            NSTask *createNewOrigFS = [[NSTask alloc] init];
                            [createNewOrigFS setLaunchPath:@"/usr/bin/snappy"];
                            NSArray *createNewOrigFSArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-c", @"orig-fs", nil];
                            [createNewOrigFS setArguments:createNewOrigFSArgs];
                            createNewOrigFS.terminationHandler = ^{
                                [self logToFile:@"renaming newly created orig-fs to system snapshot name" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                NSTask *renameOrigFS = [[NSTask alloc] init];
                                [renameOrigFS setLaunchPath:@"/usr/bin/snappy"];
                                NSArray *renameOrigFSArgs = [[NSArray alloc] initWithObjects:@"-f", @"/", @"-r", @"orig-fs", @"-x", nil];
                                [renameOrigFS setArguments:renameOrigFSArgs];
                                [renameOrigFS launch];
                                [self logToFile:@"ok, we're done with snappy, deleting now" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                NSError *err;
                                [[NSFileManager defaultManager] removeItemAtPath:@"/usr/bin/snappy" error:&err];
                                if (err) {
                                    [self logToFile:[NSString stringWithFormat:@"non-fatal error, not showing alert. unable to delete snappy: %@", [err localizedDescription]] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                }
                            };
                            [createNewOrigFS launch];
                        }
                        [self logToFile:@"showing restore complete alert" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                        UIAlertController *restoreCompleteController = [UIAlertController alertControllerWithTitle:@"Restore Succeeded!" message:@"Rebuilding icon cache, please wait..." preferredStyle:UIAlertControllerStyleAlert];
                        [self presentViewController:restoreCompleteController animated:TRUE completion:^{
                            if ([[self->_successionPrefs objectForKey:@"update-install"] isEqual:@(1)]) {
                                [self logToFile:@"Update install was used, rebuilding uicache" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/uicache"]) {
                                    NSTask *uicacheTask = [[NSTask alloc] init];
                                    NSArray *uicacheElectraArgs = [NSArray arrayWithObjects:@"--all", nil];
                                    [uicacheTask setLaunchPath:@"/usr/bin/uicache"];
                                    [uicacheTask setArguments:uicacheElectraArgs];
                                    [uicacheTask launch];
                                    uicacheTask.terminationHandler = ^(NSTask *task){
                                        [self logToFile:@"uicache complete, deleting it..." atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                        NSError *err;
                                        [[NSFileManager defaultManager] removeItemAtPath:@"/usr/bin/uicache" error:&err];
                                        if (err) {
                                            [self logToFile:[NSString stringWithFormat:@"non-fatal error, not showing alert. unable to delete uicache: %@", [err localizedDescription]] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                        }
                                        reboot(0x400);
                                    };
                                } else {
                                    [self logToFile:@"/usr/bin/uicache doesnt exist, oops. rebooting..." atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                    reboot(0x400);
                                }
                            } else if ([[self->_successionPrefs objectForKey:@"dry-run"] isEqual:@(1)]){
                                [self logToFile:@"That was a test mode restore, but somehow the first check for this didnt get detected... anways, the app will just hang now..." atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                            } else {
                                extern int SBDataReset(mach_port_t, int);
                                extern mach_port_t SBSSpringBoardServerPort(void);
                                [self logToFile:[NSString stringWithFormat:@"That was a normal restore. go, mobile_obliteration! %u", SBSSpringBoardServerPort()] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                                SBDataReset(SBSSpringBoardServerPort(), 5);
                            }
                    }];
                }
            });
            }
            [stdoutHandle waitForDataInBackgroundAndNotify];
        }];
        [self logToFile:@"Updating UI to prepare for restore" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
        [[self infoLabel] setText:@"Working, do not leave the app..."];
        [[self headerLabel] setText:@""];
        [[self startRestoreButton] setTitle:@"Restore in progress..." forState:UIControlStateNormal];
        [[self startRestoreButton] setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [[self startRestoreButton] setEnabled:FALSE];
        [[self fileListActivityIndicator] setHidden:FALSE];
        if ([rsyncTask launchPath]) {
            [self logToFile:@"rsyncTask has a valid launchPath" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
            if ([[_successionPrefs objectForKey:@"create_APFS_orig-fs"] isEqual:@(1)] && [[_successionPrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)]) {
                [self logToFile:@"Both orig-fs and succession-prerestore are selected, these options confilct, aborting restore..." atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
                UIAlertController *tooMuchAPFSAlert = [UIAlertController alertControllerWithTitle:@"Conflicting options enabled" message:@"You cannot have 'create backup snapshot' and 'create new orig-fs' enabled simultaneously, please go to Succession's settings page and disable one of the two." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self logToFile:@"restore aborted" atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
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
    [self logToFile:[NSString stringWithFormat:@"ERROR! %@", message] atLineNumber:[NSString stringWithFormat:@"%d", __LINE__]];
    UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }];
    [errorAlertController addAction:exitAction];
    [self presentViewController:errorAlertController animated:TRUE completion:nil];
}

- (void)logToFile:(NSString *)message atLineNumber:(NSString *)lineNum {
    if ([[_successionPrefs objectForKey:@"log-file"] isEqual:@(1)]) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/mobile/succession.log"]) {
            [[NSFileManager defaultManager] createFileAtPath:@"/private/var/mobile/succession.log" contents:nil attributes:nil];
        }
        NSString *stringToLog = [NSString stringWithFormat:@"[SUCCESSIONLOG %@: %@] Line %@: %@\n", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [NSDate date], lineNum, message];
        NSLog(@"%@", stringToLog);
        NSFileHandle *logFileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/private/var/mobile/succession.log"];
        [logFileHandle seekToEndOfFile];
        [logFileHandle writeData:[stringToLog dataUsingEncoding:NSUTF8StringEncoding]];
        [logFileHandle closeFile];
    }
}

@end
