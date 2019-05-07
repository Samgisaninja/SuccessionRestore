//
//  SettingsTableViewController.h
//  SuccessionRestore
//
//  Created by Sam Gardner on 4/12/19.
//  Copyright © 2019 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableDictionary *successionPrefs;
@property (nonatomic, strong) UISwitch *createAPFSsuccessionprerestoreSwitch;
@property (nonatomic, strong) UISwitch *createAPFSorigfsSwitch;

@end
