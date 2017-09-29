//
//  ViewController.h
//  SuccessionRestore
//
//  Created by Sam Gardner on 9/27/17.
//  Copyright © 2017 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *deviceModelLabel;
@property (weak, nonatomic) IBOutlet UILabel *iOSVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *iOSBuildLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadDMGButton;
@property (weak, nonatomic) IBOutlet UIButton *prepareToRestoreButton;
@end
