//
//  RestoreViewController.h
//  SuccessionRestore
//
//  Created by Sam Gardner on 6/30/18.
//  Copyright © 2018 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RestoreViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *headerLabel;
@property (strong, nonatomic) IBOutlet UILabel *infoLabel;
@property (strong, nonatomic) IBOutlet UILabel *outputLabel;
@property (strong, nonatomic) IBOutlet UIButton *startRestoreButton;
@property (strong, nonatomic) NSString *filesystemType;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *fileListActivityIndicator;
@property (strong, nonatomic) IBOutlet UIProgressView *restoreProgressBar;
@property (strong, nonatomic) NSMutableDictionary *successionPrefs;
@property (strong, nonatomic) NSMutableString *theDiskString;
@end
