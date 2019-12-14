//
//  RestoreViewController.h
//  SuccessionRestore
//
//  Created by Sam Gardner on 11/28/19.
//  Copyright © 2019 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RestoreViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *restoreProgressBar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressIndicator;
@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (weak, nonatomic) IBOutlet UIButton *eraseButton;
@property (strong, nonatomic) NSMutableDictionary *successionPrefs;
@property (strong, nonatomic) NSString *deviceModel;
@property (strong, nonatomic) NSString *deviceType;
@property (strong, nonatomic) UIAlertController *areYouSureAlert;
@end

