//
//  RestoreViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 6/30/18.
//  Copyright © 2018 Sam Gardner. All rights reserved.
//

#import "RestoreViewController.h"
#include <spawn.h>
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
    [[self fileListActivityIndicator] setHidden:TRUE];
    [[self restoreProgressBar] setHidden:TRUE];
    _successionPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
        [[self startRestoreButton] setTitle:@"Erase iPhone" forState:UIControlStateNormal];
    } else {
        [[self headerLabel] setText:@""];
        [[self startRestoreButton] setTitle:@"This will only take a second, hang tight..." forState:UIControlStateNormal];
        [[self startRestoreButton] setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [[self startRestoreButton] setEnabled:FALSE];
        [[self fileListActivityIndicator] setHidden:FALSE];
        [[self fileListActivityIndicator] startAnimating];
        [self attachRestoreDisk];
    }
}

- (IBAction)startRestoreButtonAction:(id)sender {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
        UIAlertController *areYouSureAlert = [UIAlertController alertControllerWithTitle:@"Are you sure you would like to begin restoring" message:@"You will not be able to leave the app during the process" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *beginRestore = [UIAlertAction actionWithTitle:@"Begin restore" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [[UIDevice currentDevice] setBatteryMonitoringEnabled:TRUE];
            if ([[UIDevice currentDevice] batteryLevel] > 0.5) {
                [self successionRestore];
            } else {
                UIAlertController *lowBatteryWarning = [UIAlertController alertControllerWithTitle:@"Low Battery" message:@"It is recommended you have at least 50% battery charge before beginning restore" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelRestoreAction = [UIAlertAction actionWithTitle:@"Abort restore" style:UIAlertActionStyleDefault handler:nil];
                UIAlertAction *startRestoreAction = [UIAlertAction actionWithTitle:@"Restore anyways" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
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
        UIAlertController *attachingAlert = [UIAlertController alertControllerWithTitle:@"Mounting filesystem..." message:@"This step might fail, if it does, you may need to reboot to get this to work." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self attachRestoreDisk];
        }];
        [attachingAlert addAction:okAction];
        [self presentViewController:attachingAlert animated:TRUE completion:nil];
    }
}

- (void) attachRestoreDisk {
    NSArray *origDevContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/" error:nil];
    [self->_startRestoreButton setUserInteractionEnabled:FALSE];
    [_startRestoreButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/" withIntermediateDirectories:TRUE attributes:nil error:nil];
    char thedisk[11];
    NSString *bootstrap = @"/var/mobile/Media/Succession/rfs.dmg";
    if (kCFCoreFoundationVersionNumber > 1349.56 && [self is64bitHardware]) {
        _filesystemType = @"apfs";
    } else {
        _filesystemType = @"hfs";
    }
    attach([bootstrap UTF8String], thedisk, sizeof(thedisk));
    NSMutableArray *changedDevContents = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/" error:nil]];
    [changedDevContents removeObjectsInArray:origDevContents];
    for (NSString * object in changedDevContents) {
        if ([object hasSuffix:@"s2s1"] && ![object containsString:@"rdisk"]) {
            _attachedDMGDiskName = [NSString stringWithFormat:@"/dev/%@", object];
            [[self infoLabel] setText:[NSString stringWithFormat:@"Attached to %@", _attachedDMGDiskName]];
            [self mountRestoreDisk:_attachedDMGDiskName];
        } else if ([object hasSuffix:@"s2"] && ![object containsString:@"rdisk"]) {
            _attachedDMGDiskName = [NSString stringWithFormat:@"/dev/%@", object];
            [[self infoLabel] setText:[NSString stringWithFormat:@"Attached to %@", _attachedDMGDiskName]];
            [self mountRestoreDisk:_attachedDMGDiskName];
        }
    }
    if (_attachedDMGDiskName == nil) {
        [self errorAlert:@"Unable to find attached DMG"];
    }
}

-(void) mountRestoreDisk:(NSString *)attachedDMGDiskName{
    NSArray *mountArgs = [NSArray arrayWithObjects:@"-t", _filesystemType, @"-o", @"ro", attachedDMGDiskName, @"/var/MobileSoftwareUpdate/mnt1", nil];
    [[self infoLabel] setText:@"Mounting DMG, please wait..."];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/sbin/mount";
    task.arguments = mountArgs;
    task.terminationHandler = ^(NSTask *task){
        [[self headerLabel] setText:@"WARNING!"];
        [[self infoLabel] setText:[NSString stringWithFormat:@"Running this tool will immediately delete all data from your device.\nPlease make a backup of any data that you want to keep. This will also return your device to the setup screen.\nA valid SIM card may be needed for activation on iPhones."]];
        [[self startRestoreButton] setTitle:@"Erase iPhone" forState:UIControlStateNormal];
        [[self startRestoreButton] setEnabled:TRUE];
        [[self startRestoreButton] setUserInteractionEnabled:TRUE];
        [[self startRestoreButton] setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [[self fileListActivityIndicator] setHidden:TRUE];
    };
    [task launch];
}

-(void)successionRestore{
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
        NSMutableArray *rsyncMutableArgs = [NSMutableArray arrayWithObjects:@"-vaxcH",
                                            @"--delete-after",
                                            @"--progress",
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
                                            @"/var/MobileSoftwareUpdate/mnt1/.",
                                            @"/", nil];
        if (![_filesystemType isEqualToString:@"apfs"]) {
            [rsyncMutableArgs addObject:@"--exclude=/System/Library/Caches/com.apple.dyld/"];
        }
        if ([[_successionPrefs objectForKey:@"dry-run"] isEqual:@(1)]) {
            [rsyncMutableArgs addObject:@"--dry-run"];
        }
        if ([[_successionPrefs objectForKey:@"update-install"] isEqual:@(1)]) {
            [rsyncMutableArgs addObject:@"--exclude=/var"];
            [rsyncMutableArgs addObject:@"--exclude=/private/var/"];
        }
        if ([[_successionPrefs objectForKey:@"log-file"] isEqual:@(1)]) {
            [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/mobile/succession.log" error:nil];
            NSString *cmdString = [NSString stringWithFormat:@"rsync %@", [rsyncMutableArgs componentsJoinedByString:@" "]];
            [cmdString writeToFile:@"/private/var/mobile/succession.log" atomically:TRUE encoding:NSUTF8StringEncoding error:nil];
        }
        NSArray *rsyncArgs = [NSArray arrayWithArray:rsyncMutableArgs];
        NSTask *rsyncTask = [[NSTask alloc] init];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[_successionPrefs objectForKey:@"custom_rsync_path"]]) {
            [rsyncTask setLaunchPath:[_successionPrefs objectForKey:@"custom_rsync_path"]];
        } else {
            if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/rsync"]) {
                UIAlertController *rsyncNotFound = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Unable to find rsync at custom path %@", [_successionPrefs objectForKey:@"custom_rsync_path"]]  message:@"/usr/bin/rsync will be used" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
                [rsyncNotFound addAction:useDefualtPathAction];
                [self presentViewController:rsyncNotFound animated:TRUE completion:nil];
                [rsyncTask setLaunchPath:@"/usr/bin/rsync"];
            } else {
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
            if ([[self->_successionPrefs objectForKey:@"log-file"] isEqual:@(1)]) {
                if (![[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/mobile/succession.log"]) {
                    [[NSFileManager defaultManager] createFileAtPath:@"/private/var/mobile/succession.log" contents:nil attributes:nil];
                }
                NSFileHandle *logFileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/private/var/mobile/succession.log"];
                [logFileHandle seekToEndOfFile];
                [logFileHandle writeData:[stringRead dataUsingEncoding:NSUTF8StringEncoding]];
                [logFileHandle closeFile];
            }
            [[self infoLabel] setText:@"Restoring, please wait..."];
            if ([stringRead containsString:@"00 files..."]) {
                [[self outputLabel] setHidden:FALSE];
                [[self outputLabel] setText:stringRead];
                [[self fileListActivityIndicator] setHidden:FALSE];
                [[self restoreProgressBar] setHidden:TRUE];
            }
            if ([stringRead hasPrefix:@"Applications/"]) {
                [[self outputLabel] setHidden:FALSE];
                [[self outputLabel] setText:[NSString stringWithFormat:@"%@\nRebuliding Applications...", stringRead]];
                [[self fileListActivityIndicator] setHidden:TRUE];
                [[self restoreProgressBar] setHidden:FALSE];
                [[self restoreProgressBar] setProgress:0];
            }
            if ([stringRead hasPrefix:@"Library/"]) {
                [[self outputLabel] setHidden:FALSE];
                [[self outputLabel] setText:[NSString stringWithFormat:@"%@\nRebuliding Library...", stringRead]];
                [[self fileListActivityIndicator] setHidden:TRUE];
                [[self restoreProgressBar] setHidden:FALSE];
                [[self restoreProgressBar] setProgress:0.33];
            }
            if ([stringRead hasPrefix:@"System/"]) {
                [[self outputLabel] setHidden:FALSE];
                [[self outputLabel] setText:[NSString stringWithFormat:@"%@\nRebuliding System...", stringRead]];
                [[self fileListActivityIndicator] setHidden:TRUE];
                [[self restoreProgressBar] setHidden:FALSE];
                [[self restoreProgressBar] setProgress:0.67];
            }
            if ([stringRead hasPrefix:@"usr/"]) {
                [[self outputLabel] setHidden:FALSE];
                [[self outputLabel] setText:[NSString stringWithFormat:@"%@\nRebuliding usr...", stringRead]];
                [[self fileListActivityIndicator] setHidden:TRUE];
                [[self restoreProgressBar] setHidden:FALSE];
                [[self restoreProgressBar] setProgress:0.9];
            }
            if ([stringRead containsString:@"speedup is"]) {
                [[self outputLabel] setHidden:TRUE];
                [[self headerLabel] setText:@"Restore complete"];
                [[self fileListActivityIndicator] setHidden:TRUE];
                [[self restoreProgressBar] setHidden:FALSE];
                [[self restoreProgressBar] setProgress:1.0];
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
                if ([[self->_successionPrefs objectForKey:@"dry-run"] isEqual:@(1)]) {
                    UIAlertController *restoreCompleteController = [UIAlertController alertControllerWithTitle:@"Dry run complete!" message:@"YAY!" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        exit(0);
                    }];
                    [restoreCompleteController addAction:exitAction];
                    [self presentViewController:restoreCompleteController animated:TRUE completion:nil];
                } else {
                    UIAlertController *restoreCompleteController = [UIAlertController alertControllerWithTitle:@"Restore Succeeded!" message:@"Rebooting now..." preferredStyle:UIAlertControllerStyleAlert];
                    [self presentViewController:restoreCompleteController animated:TRUE completion:^{
                        if ([[self->_successionPrefs objectForKey:@"update-install"] isEqual:@(1)]) {
                            reboot(0x400);
                        } else if ([[self->_successionPrefs objectForKey:@"dry-run"] isEqual:@(1)]){}
                        else {
                            extern int SBDataReset(mach_port_t, int);
                            extern mach_port_t SBSSpringBoardServerPort(void);
                            SBDataReset(SBSSpringBoardServerPort(), 5);
                        }
                        
                    }];
                }
                
            }
            [stdoutHandle waitForDataInBackgroundAndNotify];
        }];
        [[self infoLabel] setText:@"Working, do not leave the app..."];
        [[self headerLabel] setText:@""];
        [[self startRestoreButton] setTitle:@"Restore in progress..." forState:UIControlStateNormal];
        [[self startRestoreButton] setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [[self startRestoreButton] setEnabled:FALSE];
        [[self fileListActivityIndicator] setHidden:FALSE];
        if ([rsyncTask launchPath]) {
            [rsyncTask launch];
        }
    } else {
        [self errorAlert:@"Mountpoint does not contain rootfilesystem, please restart the app and try again."];
    }

}


-(void)errorAlert:(NSString *)message{
    UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }];
    [errorAlertController addAction:exitAction];
    [self presentViewController:errorAlertController animated:TRUE completion:nil];
}


- (BOOL) is64bitHardware
{
#if __LP64__
    // The app has been compiled for 64-bit intel and runs as 64-bit intel
    return YES;
#endif
    
    // Use some static variables to avoid performing the tasks several times.
    static BOOL sHardwareChecked = NO;
    static BOOL sIs64bitHardware = NO;
    
    if(!sHardwareChecked)
    {
        sHardwareChecked = YES;
        // The app runs on a real iOS device: ask the kernel for the host info.
        struct host_basic_info host_basic_info;
        unsigned int count;
        kern_return_t returnValue = host_info(mach_host_self(), HOST_BASIC_INFO, (host_info_t)(&host_basic_info), &count);
        if(returnValue != KERN_SUCCESS)
        {
            sIs64bitHardware = NO;
        }
        
        sIs64bitHardware = (host_basic_info.cpu_type == CPU_TYPE_ARM64);
    }
    
    return sIs64bitHardware;
}
@end
