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
    self.navigationItem.title = @"Credits";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 12;
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
            [[cell imageView] setImage:[UIImage imageNamed:@"samgisaninja"]];
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
            [[cell imageView] setImage:[UIImage imageNamed:@"xerub"]];
            break;
        }
        case 2: {
                UIFont *nameFont = [UIFont systemFontOfSize:17];
                NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
                NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"MidnightChips\n"] attributes: nameFontDict];
                UIFont *roleFont = [UIFont systemFontOfSize:13];;
                NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
                NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"APFS Snapshot Operations (SnapBack)" attributes: roleFontDict];
                [nameString appendAttributedString:roleString];
                [[cell textLabel] setAttributedText:nameString];
                [[cell imageView] setImage:[UIImage imageNamed:@"Midnightchip"]];
                break;
            }
        case 3: {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"sbingner\n"] attributes: nameFontDict];
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"snappy" attributes: roleFontDict];
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            [[cell imageView] setImage:[UIImage imageNamed:@"sbingner"]];
            break;
            }
        case 4:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"pwn20wnd\n"] attributes: nameFontDict];
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Rollectra (mountpoint, ents, rsync args)" attributes: roleFontDict];
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            [[cell imageView] setImage:[UIImage imageNamed:@"pwn20wnd"]];
            break;
        }
        case 5:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Cryptiiiic\n"] attributes: nameFontDict];
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Compile Script" attributes: roleFontDict];
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            [[cell imageView] setImage:[UIImage imageNamed:@"cryptiiiic"]];
            break;
        }
        case 6:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Nobbele\n"] attributes: nameFontDict];
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Compile Script" attributes: roleFontDict];
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            [[cell imageView] setImage:[UIImage imageNamed:@"4pplecracker"]];
            break;
        }
        case 7:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"PsychoTea\n"] attributes: nameFontDict];
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Root on kppless jailbreaks" attributes: roleFontDict];[nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            [[cell imageView] setImage:[UIImage imageNamed:@"PsychoTea"]];
            break;
        }
        case 8:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"uroboro\n"] attributes: nameFontDict];UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Teaching me literally everything I know" attributes: roleFontDict];
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            UIImage *pfpImage = [UIImage imageNamed:@"uroboro"];
            CGSize newSize = CGSizeMake(50, 50);
            UIGraphicsBeginImageContext(newSize);
            [pfpImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
            UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [[cell imageView] setImage:newImage];
            break;
        }
        case 9:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"xerusdesign\n"] attributes: nameFontDict];
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Icon Designer" attributes: roleFontDict];
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            [[cell imageView] setImage:[UIImage imageNamed:@"xerusdesign"]];
            break;
        }
        case 10:
        {
            UIFont *nameFont = [UIFont systemFontOfSize:17];
            NSDictionary *nameFontDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
            NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Swaggo\n"] attributes: nameFontDict];
            UIFont *roleFont = [UIFont systemFontOfSize:13];;
            NSDictionary *roleFontDict = [NSDictionary dictionaryWithObject: roleFont forKey:NSFontAttributeName];
            NSMutableAttributedString *roleString = [[NSMutableAttributedString alloc] initWithString:@"Mascot ;P" attributes: roleFontDict];
            [nameString appendAttributedString:roleString];
            [[cell textLabel] setAttributedText:nameString];
            [[cell imageView] setImage:[UIImage imageNamed:@"swaggo"]];
            break;
        }
        case 11:
        {
            [[cell textLabel] setText:@"rsync used under gpl3"];
            [[cell imageView] setImage:nil];
            break;
        }
        default:
            break;
    }
    
    return cell;
}


+ (UIImage*)resizeImageWithImage:(UIImage*)image toSize:(CGSize)newSize
{
    // Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
    
    // draw in new context, with the new size
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the context
    UIGraphicsEndImageContext();
    
    return newImage;
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
