//
//  SpecialThanksTableViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 4/14/19.
//  Copyright © 2019 Sam Gardner. All rights reserved.
//

#import "SpecialThanksTableViewController.h"

@interface SpecialThanksTableViewController ()

@end

@implementation SpecialThanksTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[[self navigationController] navigationBar] setHidden:FALSE];
    self.navigationItem.title = @"Special Thanks";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 8;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"creditsReuseIdentifier" forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;
    [cell.textLabel sizeToFit];
    switch ([indexPath row]) {
        case 0: {
            UIFont *nameFont = [UIFont systemFontOfSize:19];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Samg_is_a_Ninja\n"] attributes: nameFontDict];
            
            UIFont *roleFont = [UIFont systemFontOfSize:15];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Developer" attributes: roleFontDict];
            
            
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            break;
        }
        case 1: {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"xerub\n"] attributes: nameFontDict];
            
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Disk attaching" attributes: roleFontDict];
            
            
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            break;
        }
        case 2:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"pwn20wnd\n"] attributes: nameFontDict];
            
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Rollectra (mountpoint, ents, rsync args)" attributes: roleFontDict];
            
            
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            break;
        }
        case 3:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Cryptiiic\n"] attributes: nameFontDict];
            
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Compile Script" attributes: roleFontDict];
            
            
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            break;
        }
        case 4:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Nobbele\n"] attributes: nameFontDict];
            
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Compile Script" attributes: roleFontDict];
            
            
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            break;
        }
        case 5:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"PsychoTea\n"] attributes: nameFontDict];
            
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Root on kppless jailbreaks" attributes: roleFontDict];
            
            
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            break;
        }
        case 6:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"uroboro\n"] attributes: nameFontDict];
            
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Teaching me literally everything I know" attributes: roleFontDict];
            
            
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            break;
        }
        case 7:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"xerusdesign\n"] attributes: nameFontDict];
            
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Icon Designer" attributes: roleFontDict];
            
            
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            break;
        }
        default:
            break;
    }
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
