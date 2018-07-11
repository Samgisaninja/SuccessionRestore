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
}

- (IBAction)startRestoreButtonAction:(id)sender {
    UIAlertController *areYouSureAlert = [UIAlertController alertControllerWithTitle:@"Are you sure you would like to begin restoring" message:@"You will not be able to leave the app during the process" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *beginRestore = [UIAlertAction actionWithTitle:@"Begin restore" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self successionRestore];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [areYouSureAlert addAction:beginRestore];
    [areYouSureAlert addAction:cancelAction];
    [self presentViewController:areYouSureAlert animated:TRUE completion:nil];
}

- (void)successionRestore {
    [[self headerLabel] setText:@"Restoring..."];
    [[self infoLabel] setText:@"DO NOT LEAVE THE APP"];
    char thedisk[11];
    NSString * bootstrap = @"/var/mobile/Media/Succession/rfs.dmg";
    int rv = attach([bootstrap UTF8String], thedisk, sizeof(thedisk));
    NSLog(@"SUCCESSIONTESTING: thedisk: %d, %s\n", rv, thedisk);
    memset(&args, 0, sizeof(args));
    args.fspec = thedisk;
    args.hfs_mask = 0777;
    //args.hfs_encoding = -1;
    //args.flags = HFSFSMNT_EXTENDED_ARGS;
    //struct timeval tv = { 0, 0 };
    //gettimeofday((struct timeval *)&tv, &args.hfs_timezone);
    rv = mount("hfs", "/mnt/Succession", MNT_RDONLY, &args);
    NSLog(@"SUCCESSIONTESTING: mount: %d\n", rv);
    
}

@end
