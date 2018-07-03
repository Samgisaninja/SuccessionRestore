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
    char jl[10] = "/tmp/test";
    long dmg = HFSOpen("/var/mobile/Media/Succesion/rfs.dmg", 27);
    NSLog(@"SUCCESSIONTESTING: DMG == %ld", dmg);
    if (dmg >= 0) {
        long len = HFSReadFile(dmg, "/Applications/MobileSafari.app/AppIcon29x29@2x.png", gLoadAddr, 0, 0);
        printf("hdik = %ld\n", len);
        if (len > 0) {
            int fd = creat(jl, 0755);
            if (fd >= 0) {
                write(fd, gLoadAddr, len);
                close(fd);
            }
        }
        HFSClose(dmg);
    }
    
    
}

@end
