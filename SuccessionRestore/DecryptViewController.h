//
//  DecryptViewController.h
//  SuccessionRestore
//
//  Created by Sam Gardner on 8/30/19.
//  Copyright © 2019 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DecryptViewController : UIViewController

@property (strong, nonatomic) NSDictionary *successionPrefs;
@property (strong, nonatomic) NSString *deviceModel;
@property (strong, nonatomic) NSString *deviceBuild;
@property (strong, nonatomic) NSString *deviceVersion;
@property (strong, nonatomic) IBOutlet UILabel *activityLabel;
@end
