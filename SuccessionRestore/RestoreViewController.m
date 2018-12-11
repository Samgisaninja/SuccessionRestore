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
    // Do any additional setup after loading the view.
    [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];
}

- (IBAction)startRestoreButtonAction:(id)sender {
    UIAlertController *areYouSureAlert = [UIAlertController alertControllerWithTitle:@"Are you sure you would like to begin restoring" message:@"You will not be able to leave the app during the process" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *beginRestore = [UIAlertAction actionWithTitle:@"Begin restore" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self prepareForRestore];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [areYouSureAlert addAction:beginRestore];
    [areYouSureAlert addAction:cancelAction];
    [self presentViewController:areYouSureAlert animated:TRUE completion:nil];
}

- (void)prepareForRestore {
    [[self headerLabel] setText:@"Restoring, do not leave the app..."];
    [[self infoLabel] setText:@"Mounting rootfilesystem"];
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/" withIntermediateDirectories:TRUE attributes:nil error:nil];
    char thedisk[11];
    NSString *bootstrap = @"/var/mobile/Media/Succession/rfs.dmg";
    if (kCFCoreFoundationVersionNumber < 1349.56) {
        _filesystemType = @"hfs";
    } else if (kCFCoreFoundationVersionNumber > 1349.56){
        _filesystemType = @"apfs";
    }
    int rv = attach([bootstrap UTF8String], thedisk, sizeof(thedisk));
    NSArray *mountArgs = [NSArray arrayWithObjects:@"-t", _filesystemType, @"-o", @"ro", [NSString stringWithFormat:@"%ss2s1", thedisk], @"/var/MobileSoftwareUpdate/mnt1", nil];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[self infoLabel] setText:@"Mounting DMG"];
        if (rv == 0) {
            NSPipe *pipe = [NSPipe pipe];
            NSFileHandle *outputFile = pipe.fileHandleForReading;
            NSTask *task = [[NSTask alloc] init];
            task.launchPath = @"/sbin/mount";
            task.arguments = mountArgs;
            task.standardOutput = pipe;
            task.terminationHandler = ^(NSTask *task){
                [self successionRestore];
                NSData *outputData = [outputFile readDataToEndOfFile];
                [outputFile closeFile];
                NSString *outputString = [[NSString alloc] initWithData: outputData encoding: NSUTF8StringEncoding];
                [[self infoLabel] setText:outputString];
            };
            [task launch];
        } else {
            [self errorAlert:@"Failed to attach DMG"];
        }
    });
}

-(void)successionRestore{
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/MobileSoftwareUpdate/mnt1/sbin/launchd"]) {
        NSArray *rsyncArgs = [NSArray arrayWithObjects:@"--vaxcH", @"--delete-after", @"exclude=/Developer", @"/var/MobileSoftwareUpdate/mnt1/.", @"/var/mobile/Media/Succession/", nil];
        [[self infoLabel] setText:@"Starting rsync"];
        NSPipe *pipe = [NSPipe pipe];
        NSFileHandle *outputFile = pipe.fileHandleForReading;
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/rsync";
        task.arguments = rsyncArgs;
        task.standardOutput = pipe;
        [task launch];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:)  name: NSFileHandleReadCompletionNotification object:outputFile];
    } else {
        [self errorAlert:@"Mountpoint does not contain rootfilesystem"];
    }
    
}

-(void)errorAlert:(NSString *)message{
    UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }];
    [errorAlertController addAction:exitAction];
    [self presentViewController:errorAlertController animated:TRUE completion:nil];
}

-(void)receivedData:(NSNotification *)notification{
    NSData *outputData = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *outputString = [[NSString alloc] initWithData: outputData encoding: NSUTF8StringEncoding];
    [[self infoLabel] setText:outputString];
}
@end
