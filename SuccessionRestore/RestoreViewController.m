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
    char path[4096];
    char *pt = realpath(path, NULL);
    NSLog(@"SUCCESSIONTESTING: pt == %s", pt);
    NSLog(@"SUCCESSIONTESTING: pt == %s", pt);
    NSLog(@"SUCCESSIONTESTING: pt == %s", pt);
    NSString *execpath = [[NSString stringWithUTF8String:pt] stringByDeletingLastPathComponent];
    NSLog(@"SUCCESSIONTESTING: execpath == %@", execpath);
    NSLog(@"SUCCESSIONTESTING: execpath == %@", execpath);
    NSLog(@"SUCCESSIONTESTING: execpath == %@", execpath);
    NSString *bootstrap = [execpath stringByAppendingPathComponent:@"bootstrap.dmg"];
    NSLog(@"SUCCESSIONTESTING: bootstrap == %@", bootstrap);
    NSLog(@"SUCCESSIONTESTING: bootstrap == %@", bootstrap);
    NSLog(@"SUCCESSIONTESTING: bootstrap == %@", bootstrap);
    int rv = attach([bootstrap UTF8String], thedisk, sizeof(thedisk));
    printf("thedisk: %d, %s\n", rv, thedisk);
    if (rv) {
        NSLog(@"SUCCESSIONTESTING: LINE 61");
    }
    
    memset(&args, 0, sizeof(args));
    args.fspec = thedisk;
    args.hfs_mask = 0777;
    //args.hfs_encoding = -1;
    //args.flags = HFSFSMNT_EXTENDED_ARGS;
    //struct timeval tv = { 0, 0 };
    //gettimeofday((struct timeval *)&tv, &args.hfs_timezone);
    rv = mount("hfs", "/Developer", MNT_RDONLY, &args);
    printf("mount: %d\n", rv);
    if (rv) {
        NSLog(@"SUCCESSIONTESTING: LINE 74");
    }
    
    
}

@end
