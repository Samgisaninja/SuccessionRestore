//
//  SpecialThanksViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 12/9/18.
//  Copyright © 2018 Sam Gardner. All rights reserved.
//

#import "SpecialThanksViewController.h"

@interface SpecialThanksViewController ()

@end

@implementation SpecialThanksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationItem] setTitle:@"Special Thanks"];
}

- (IBAction)backButtonAction:(id)sender {
    [[self navigationController] popToRootViewControllerAnimated:TRUE];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
