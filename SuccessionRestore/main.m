//
//  main.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 9/27/17.
//  Copyright © 2017 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        if (!(setuid(0) == 0 && setgid(0) == 0))
        {
            NSLog(@"Failed to gain root privileges, aborting...");
            exit(EXIT_FAILURE);
        } else {
            NSLog(@"Root obtained! Thanks to Ivano Bilenchi aka the iCleaner guy for posting on his blog about how to make apps run as root");
        }
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
