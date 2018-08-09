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
@property (strong, nonatomic) IBOutlet UIButton *startRestoreButton;
@property (strong, nonatomic) NSFileManager *fileManager;
@property (strong, nonatomic) NSString *pathToRoot;
@end
