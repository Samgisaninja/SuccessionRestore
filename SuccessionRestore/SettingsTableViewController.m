//
//  SettingsTableViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 4/12/19.
//  Copyright © 2019 Sam Gardner. All rights reserved.
//

#import "SettingsTableViewController.h"

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _successionPrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"]];
    [[[self navigationController] navigationBar] setHidden:FALSE];
    self.navigationItem.title = @"Settings";
}

-(void)viewDidAppear:(BOOL)animated{
    [[[self navigationController] navigationBar] setHidden:FALSE];
    self.navigationItem.title = @"Settings";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 11;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    switch ([indexPath row]) {
        case 0: {
            cell.textLabel.text = @"Special Thanks";
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel sizeToFit];
            break;
        }
        case 1: {
            cell.textLabel.text = @"Use test mode";
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel sizeToFit];
            UISwitch *dryRunSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = dryRunSwitch;
            [dryRunSwitch setOn:[[_successionPrefs objectForKey:@"dry-run"] boolValue] animated:FALSE];
            [dryRunSwitch addTarget:self action:@selector(dryRunSwitchChanged) forControlEvents:UIControlEventValueChanged];
            break;
        }
        case 2: {
            cell.textLabel.text = @"Only restore system data (similar to 'restore rootfs')";
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel sizeToFit];
            UISwitch *updateInstallSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = updateInstallSwitch;
            [updateInstallSwitch setOn:[[_successionPrefs objectForKey:@"update-install"] boolValue] animated:NO];
            [updateInstallSwitch addTarget:self action:@selector(updateInstallSwitchChanged) forControlEvents:UIControlEventValueChanged];
            break;
        }
        case 3: {
            cell.textLabel.text = @"Log output to /var/mobile/succession.log";
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel sizeToFit];
            UISwitch *logOutputSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = logOutputSwitch;
            [logOutputSwitch setOn:[[_successionPrefs objectForKey:@"log-file"] boolValue] animated:NO];
            [logOutputSwitch addTarget:self action:@selector(logFileSwitchChanged) forControlEvents:UIControlEventValueChanged];
            break;
        }
        case 4: {
            cell.textLabel.text = @"Delete extraneous files during restore instead of after (for devices low on storage space)";
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel sizeToFit];
            UISwitch *deleteDuringSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = deleteDuringSwitch;
            [deleteDuringSwitch setOn:[[_successionPrefs objectForKey:@"delete-during"] boolValue] animated:NO];
            [deleteDuringSwitch addTarget:self action:@selector(deleteDuringSwitchChanged) forControlEvents:UIControlEventValueChanged];
            break;
        }
        case 5: {
            cell.textLabel.text = @"Create APFS snapshot 'orig-fs' after restore (requires snappy from Bingner's repo and iOS 10.3 or higher)";
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel sizeToFit];
            UISwitch *createAPFSorigfsSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = createAPFSorigfsSwitch;
            [createAPFSorigfsSwitch setOn:[[_successionPrefs objectForKey:@"create_APFS_orig-fs"] boolValue] animated:FALSE];
            [createAPFSorigfsSwitch addTarget:self action:@selector(createAPFSorigfsSwitchChanged) forControlEvents:UIControlEventValueChanged];
            break;
        }
        case 6: {
            cell.textLabel.text = @"Create APFS snapshot 'succession-prerestore' before restore for use with SnapBack to 'undo restore' (requires snappy from Bingner's repo and iOS 10.3 or higher)";
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel sizeToFit];
            UISwitch *createAPFSsuccessionprerestoreSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = createAPFSsuccessionprerestoreSwitch;
            [createAPFSsuccessionprerestoreSwitch setOn:[[_successionPrefs objectForKey:@"create_APFS_succession-prerestore"] boolValue] animated:FALSE];
            [createAPFSsuccessionprerestoreSwitch addTarget:self action:@selector(createAPFSsuccessionprerestoreSwitchChanged) forControlEvents:UIControlEventValueChanged];
            break;
        }
        case 7: {
            cell.textLabel.text = @"Use custom rsync path";
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel sizeToFit];
            break;
        }
        case 8: {
            cell.textLabel.text = @"Use custom IPSW path";
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel sizeToFit];
            break;
        }
        case 9: {
            cell.textLabel.text = @"Reset all settings to defaults";
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel sizeToFit];
            cell.accessoryView = nil;
            break;
        }
        case 10: {
            cell.textLabel.text = [NSString stringWithFormat:@"Succession version %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel sizeToFit];
            cell.accessoryView = nil;
            break;
        }
        default:
            break;
    }

    return cell;
}


-(void)dryRunSwitchChanged{
    if ([[_successionPrefs objectForKey:@"dry-run"] isEqual:@(0)]) {
        [_successionPrefs setObject:@(1) forKey:@"dry-run"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    } else {
        [_successionPrefs setObject:@(0) forKey:@"dry-run"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
}

-(void)updateInstallSwitchChanged{
    if ([[_successionPrefs objectForKey:@"update-install"] isEqual:@(0)]) {
        [_successionPrefs setObject:@(1) forKey:@"update-install"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    } else {
        [_successionPrefs setObject:@(0) forKey:@"update-install"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
}

-(void)logFileSwitchChanged{
    if ([[_successionPrefs objectForKey:@"log-file"] isEqual:@(0)]) {
        [_successionPrefs setObject:@(1) forKey:@"log-file"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    } else {
        [_successionPrefs setObject:@(0) forKey:@"log-file"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
}

-(void)deleteDuringSwitchChanged{
    if ([[_successionPrefs objectForKey:@"delete-during"] isEqual:@(0)]) {
        [_successionPrefs setObject:@(1) forKey:@"delete-during"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    } else {
        [_successionPrefs setObject:@(0) forKey:@"delete-during"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
}

-(void)createAPFSorigfsSwitchChanged{
    if ([[_successionPrefs objectForKey:@"create_APFS_orig-fs"] isEqual:@(0)]) {
        [_successionPrefs setObject:@(1) forKey:@"create_APFS_orig-fs"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    } else {
        [_successionPrefs setObject:@(0) forKey:@"create_APFS_orig-fs"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
}

-(void)createAPFSsuccessionprerestoreSwitchChanged{
    if ([[_successionPrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(0)]) {
        [_successionPrefs setObject:@(1) forKey:@"create_APFS_succession-prerestore"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    } else {
        [_successionPrefs setObject:@(0) forKey:@"create_APFS_succession-prerestore"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
        [_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch ([indexPath row]) {
        case 0:
            [self performSegueWithIdentifier:@"goToSpecialThanksTableViewController" sender:self];
            break;
        case 7: {
            UIAlertController *rsyncPathAlert = [UIAlertController alertControllerWithTitle:@"Enter path to rsync binary" message:@"Leave blank for default" preferredStyle:UIAlertControllerStyleAlert];
            [rsyncPathAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"rsync"];
            }];
            UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if ([[[[rsyncPathAlert textFields] firstObject] text] isEqualToString:@""]) {
                    [self->_successionPrefs setObject:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"rsync"] forKey:@"custom_rsync_path"];
                    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
                    [self->_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
                } else {
                    [self->_successionPrefs setObject:[[[rsyncPathAlert textFields] firstObject] text] forKey:@"custom_rsync_path"];
                    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
                    [self->_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
                }
                
            }];
            [rsyncPathAlert addAction:continueAction];
            [self presentViewController:rsyncPathAlert animated:TRUE completion:nil];
            break;
            }
        case 8: {
            UIAlertController *ipswPathAlert = [UIAlertController alertControllerWithTitle:@"Enter path to IPSW" message:@"Leave blank for default" preferredStyle:UIAlertControllerStyleAlert];
            [ipswPathAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"/var/mobile/Media/Succession/ipsw.ipsw";
            }];
            UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if ([[[[ipswPathAlert textFields] firstObject] text] isEqualToString:@""]) {
                    [self->_successionPrefs setObject:@"/var/mobile/Media/Succession/ipsw.ipsw" forKey:@"custom_ipsw_path"];
                    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
                    [self->_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
                } else {
                    [self->_successionPrefs setObject:[[[ipswPathAlert textFields] firstObject] text] forKey:@"custom_ipsw_path"];
                    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
                    [self->_successionPrefs writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" atomically:TRUE];
                }
                
            }];
            [ipswPathAlert addAction:continueAction];
            [self presentViewController:ipswPathAlert animated:TRUE completion:nil];
            break;
            }
        case 9: {
            UIAlertController *resetPrefsAlert = [UIAlertController alertControllerWithTitle:@"Reset all preferences?" message:@"Succession will restart" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist" error:nil];
                exit(0);
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
            [resetPrefsAlert addAction:confirmAction];
            [resetPrefsAlert addAction:cancelAction];
            [self presentViewController:resetPrefsAlert animated:TRUE completion:nil];
            break;
          }
        default:
            break;
    }
}

@end
