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

extern char **environ;
int attach(const char *path, char buf[], size_t sz);

@interface RestoreViewController ()

@end

@implementation RestoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _pathToRoot = @"/";
    _fileManager = [NSFileManager defaultManager];
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
    [[self headerLabel] setText:@"Restoring..."];
    [[self infoLabel] setText:@"DO NOT LEAVE THE APP"];
    char thedisk[11];
    NSString * bootstrap = @"/var/mobile/Media/Succession/rfs.dmg";
    int rv = attach([bootstrap UTF8String], thedisk, sizeof(thedisk));
    NSLog(@"SUCCESSIONTESTING: thedisk: %d, %s\n", rv, thedisk);
    char *dev_path = strdup(thedisk);
    rv = mount("hfs", "/private/var/Succession", MNT_RDONLY, dev_path);
    NSLog(@"SUCCESSIONTESTING: mount: %d\n", rv);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    //[self successionRestore];
    });
}

/*-(void)successionRestore{
#error DO NOT ATTEMPT TO RUN THIS IF YOU DONT HAVE AN EXTRACTED/MOUNTED RFS DMG ON /var/Succession (comment this line to compile)
    //Creating variables
    NSError *error;
    //Gets contents of /var/Succession
    NSArray *contentsOfVarSuccession = [_fileManager contentsOfDirectoryAtPath:@"/private/var/Succession/" error:&error]; NSLog(@"SUCCESSIONTESTING: Line 67, error: %@", [error localizedDescription]);
    //Gets contents of /
    NSArray *contentsOfRoot = [_fileManager contentsOfDirectoryAtPath:@"/" error:&error]; NSLog(@"SUCCESSIONTESTING: Line 69, error: %@", [error localizedDescription]);
    //Copies the array of contents of /, then removes all the items that are also in /var/Succession. This leaves us with the extra files that are present in /, but are not present in /var/Succession
    NSMutableArray *extraFilesInRoot = [NSMutableArray arrayWithArray:contentsOfRoot];
    int a;
    for (a=0; a < [contentsOfVarSuccession count]; a++) {
        [extraFilesInRoot removeObject:[contentsOfVarSuccession objectAtIndex:a]];
    }
    //Removes extra files in /
    int b;
    for (b=0; b < [extraFilesInRoot count]; b++) {
        [_fileManager removeItemAtPath:[extraFilesInRoot objectAtIndex:b] error:&error]; NSLog(@"SUCCESSIONTESTING: Line 79, error: %@", [error localizedDescription]);
    }
    //Copies the contentsOfVarSuccession array and makes it a mutable array (mutable arrays can be modified after being created)
    NSMutableArray *directoriesToRestore = [NSMutableArray arrayWithArray:contentsOfVarSuccession];
    //Removes /Applications and /private from the mutable array since they must be handled differently
    [directoriesToRestore removeObject:@"Applications"];
    [directoriesToRestore removeObject:@"private"];
    //Deletes each "damaged" file/directory in / that is also present in /var/Succession, then immediately replaces it with the "clean" one in /var/Succession
    int c;
    NSString *pathToMountedDMG = @"/private/var/Succession";
    for (c=0; c < [directoriesToRestore count]; c++) {
        NSString *lastPathComponent = [directoriesToRestore objectAtIndex:c];
        NSString *pathToDamagedDirectory = [_pathToRoot stringByAppendingPathComponent:lastPathComponent];
        NSString *pathToCleanDirectory = [pathToMountedDMG stringByAppendingPathComponent:lastPathComponent];
        [_fileManager removeItemAtPath:pathToDamagedDirectory error:&error]; NSLog(@"SUCCESSIONTESTING: Line 93, attempting to restore %@ error: %@", pathToDamagedDirectory, [error localizedDescription]);
        [self->_fileManager moveItemAtPath:pathToCleanDirectory toPath:pathToDamagedDirectory error:nil];
    }
    [self restoreApplications];
    [self restorePrivate];
    //Asynchronously runs the code below.
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self restoreVar];
        int d;
        for (d = 0; d < [extraFilesInRoot count]; d++) {
            NSString * pathToExtraFile = [self->_pathToRoot stringByAppendingPathComponent:[extraFilesInRoot objectAtIndex:d]];
            [self->_fileManager removeItemAtPath:pathToExtraFile error:nil];
        }
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError *error;
            [self->_fileManager createSymbolicLinkAtPath:@"/etc" withDestinationPath:@"/private/etc" error:&error];
            NSLog(@"SUCCESSIONTESTING: Line 109, error: %@", [error localizedDescription]);
            [self->_fileManager createSymbolicLinkAtPath:@"/tmp" withDestinationPath:@"/private/var/tmp" error:&error];
            NSLog(@"SUCCESSIONTESTING: Line 111, error: %@", [error localizedDescription]);
            [self->_fileManager createSymbolicLinkAtPath:@"/var" withDestinationPath:@"/private/var" error:&error];
            NSLog(@"SUCCESSIONTESTING: Line 113, error: %@", [error localizedDescription]);
            [self->_fileManager createSymbolicLinkAtPath:@"/User" withDestinationPath:@"/var/mobile" error:&error];
            NSLog(@"SUCCESSIONTESTING: Line 115, error: %@", [error localizedDescription]);
            [self->_fileManager removeItemAtPath:@"/private/var/Succession" error:&error];
            NSLog(@"SUCCESSIONTESTING: Line 117, error: %@", [error localizedDescription]);
            [self->_fileManager removeItemAtPath:@"/Applications/SuccessionRestore.app" error:&error];
            NSLog(@"SUCCESSIONTESTING: Line 119, error: %@", [error localizedDescription]);
            NSLog(@"SUCCESSIONTESTING: Contents of root: %@", [[self->_fileManager contentsOfDirectoryAtPath:self->_pathToRoot error:nil] componentsJoinedByString:@", "]);
            NSLog(@"SuccessionRestore: Restore succeeded! Thanks for using Succession!");
        });
    });
}
-(void)restoreApplications{
    NSError *error;
    NSArray *contentsOfVarSuccessionApplications = [_fileManager contentsOfDirectoryAtPath:@"/private/var/Succession/Applications" error:&error]; NSLog(@"SUCCESSIONTESTING: Line 126, error: %@", [error localizedDescription]);
    NSArray *contentsOfApplications = [_fileManager contentsOfDirectoryAtPath:@"/Applications" error:&error]; NSLog(@"SUCCESSIONTESTING: Line 127, error: %@", [error localizedDescription]);
    NSMutableArray *extraFilesInApplications = [NSMutableArray arrayWithArray:contentsOfApplications];
    int e;
    for (e=0; e < [contentsOfVarSuccessionApplications count]; e++) {
        [extraFilesInApplications removeObject:[contentsOfVarSuccessionApplications objectAtIndex:e]];
    }
    [extraFilesInApplications removeObject:@"SuccessionRestore.app"];
    int f;
    NSString *pathToApplications = @"/Applications";
    for (f=0; f < [extraFilesInApplications count]; f++) {
        NSString *pathToExtraFile = [pathToApplications stringByAppendingPathComponent:[extraFilesInApplications objectAtIndex:f]];
        [_fileManager removeItemAtPath:pathToExtraFile error:&error]; NSLog(@"SUCCESSIONTESTING: Line 138, error: %@", [error localizedDescription]);
    }
    int g;
    NSString *pathToVarSuccessionApplications = @"/private/var/Succession/Applications/";
    for (g=0; g < [contentsOfVarSuccessionApplications count]; g++) {
        NSString *lastPathComponent = [contentsOfVarSuccessionApplications objectAtIndex:g];
        NSString *pathToDamagedApplication = [pathToApplications stringByAppendingPathComponent:lastPathComponent];
        NSString *pathToCleanApplication = [pathToVarSuccessionApplications stringByAppendingPathComponent:lastPathComponent];
        [_fileManager removeItemAtPath:pathToDamagedApplication error:&error]; NSLog(@"SUCCESSIONTESTING: Line 146, error: %@", [error localizedDescription]);
        [self->_fileManager moveItemAtPath:pathToCleanApplication toPath:pathToDamagedApplication error:nil];
    }
    
}
-(void)restorePrivate{
    NSError *error;
    NSArray *contentsOfPrivate = [_fileManager contentsOfDirectoryAtPath:@"/private" error:&error]; NSLog(@"SUCCESSIONTESTING: Line 153, error: %@", [error localizedDescription]);
    NSArray *contentsOfVarSuccessionPrivate = [_fileManager contentsOfDirectoryAtPath:@"/private/var/Succession/private" error:&error]; NSLog(@"SUCCESSIONTESTING: Line 154, error: %@", [error localizedDescription]);
    NSMutableArray *extraFilesInPrivate = [NSMutableArray arrayWithArray:contentsOfPrivate];
    int h;
    for (h=0; h < [contentsOfVarSuccessionPrivate count]; h++) {
        [extraFilesInPrivate removeObject:[contentsOfVarSuccessionPrivate objectAtIndex:h]];
    }
    int i;
    NSString *pathToPrivate = @"/private";
    for (i=0; i < [extraFilesInPrivate count]; i++) {
        NSString *pathToExtraFile = [pathToPrivate stringByAppendingPathComponent:[extraFilesInPrivate objectAtIndex:i]];
        [_fileManager removeItemAtPath:pathToExtraFile error:&error]; NSLog(@"SUCCESSIONTESTING: Line 164, error: %@", [error localizedDescription]);
    }
    int j;
    NSMutableArray *privateComponentsToBeRestored = [NSMutableArray arrayWithArray:contentsOfVarSuccessionPrivate];
    [privateComponentsToBeRestored removeObject:@"var"];
    NSString *pathToVarSuccessionPrivate = @"/private/var/Succession/private/";
    for (j=0; j < [privateComponentsToBeRestored count]; j++) {
        NSString *lastPathComponent = [privateComponentsToBeRestored objectAtIndex:j];
        NSString *pathToDamagedPrivateComponent = [pathToPrivate stringByAppendingPathComponent:lastPathComponent];
        NSString *pathToCleanPrivateComponent = [pathToVarSuccessionPrivate stringByAppendingPathComponent:lastPathComponent];
        [_fileManager removeItemAtPath:pathToDamagedPrivateComponent error:&error]; NSLog(@"SUCCESSIONTESTING: Line 174, error: %@", [error localizedDescription]);
            [self->_fileManager moveItemAtPath:pathToCleanPrivateComponent toPath:pathToDamagedPrivateComponent error:&error]; NSLog(@"SUCCESSIONTESTING: Line 175, error: %@", [error localizedDescription]);
    }
}
-(void)restoreVar{
    NSError *error;
    NSArray *contentsOfPrivateVar = [_fileManager contentsOfDirectoryAtPath:@"/private/var" error:&error]; NSLog(@"SUCCESSIONTESTING: Line 180, error: %@", [error localizedDescription]);
    NSArray *contentsOfVarSuccessionPrivateVar = [_fileManager contentsOfDirectoryAtPath:@"/private/var/Succession/private/var" error:&error]; NSLog(@"SUCCESSIONTESTING: Line 181, error: %@", [error localizedDescription]);
    NSMutableArray *extraFilesInPrivateVar = [NSMutableArray arrayWithArray:contentsOfPrivateVar];
    int k;
    for (k=0; k < [contentsOfVarSuccessionPrivateVar count]; k++) {
        [extraFilesInPrivateVar removeObject:[contentsOfVarSuccessionPrivateVar objectAtIndex:k]];
    }
    int l;
    NSString *pathToPrivateVar = @"/private/var";
    for (l=0; l < [extraFilesInPrivateVar count]; l++) {
        NSString *pathToExtraFile = [pathToPrivateVar stringByAppendingPathComponent:[extraFilesInPrivateVar objectAtIndex:l]];
        [_fileManager removeItemAtPath:pathToExtraFile error:&error]; NSLog(@"SUCCESSIONTESTING: Line 191, error: %@", [error localizedDescription]);
    }
    int m;
    NSMutableArray *privateVarComponentsToBeRestored = [NSMutableArray arrayWithArray:contentsOfVarSuccessionPrivateVar];
    [privateVarComponentsToBeRestored removeObject:@"Succession"];
    NSString *pathToVarSuccessionPrivateVar = @"/private/var/Succession/private/var/";
    for (m=0; m < [privateVarComponentsToBeRestored count]; m++) {
        NSString *lastPathComponent = [privateVarComponentsToBeRestored objectAtIndex:m];
        NSString *pathToDamagedPrivateVarComponent = [pathToPrivateVar stringByAppendingPathComponent:lastPathComponent];
        NSString *pathToCleanPrivateVarComponent = [pathToVarSuccessionPrivateVar stringByAppendingPathComponent:lastPathComponent];
        [_fileManager removeItemAtPath:pathToDamagedPrivateVarComponent error:&error]; NSLog(@"SUCCESSIONTESTING: Line 201, attempting to restore: %@ error: %@", pathToDamagedPrivateVarComponent, [error localizedDescription]);
        [self->_fileManager moveItemAtPath:pathToCleanPrivateVarComponent toPath:pathToDamagedPrivateVarComponent error:nil];
    }
}*/
@end
