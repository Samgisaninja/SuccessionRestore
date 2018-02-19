//
//  DownloadViewController.h
//  SuccessionRestore
//
//  Created by Sam Gardner on 2/3/18.
//  Copyright © 2018 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadViewController : UIViewController

@property (strong, nonatomic) NSString *deviceModel;
@property (strong, nonatomic) NSString *deviceBuild;
@property (strong, nonatomic) NSString *deviceVersion;
@property (strong, nonatomic) NSString *downloadLink;

@end
