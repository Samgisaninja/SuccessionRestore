//
//  DecryptViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 8/30/19.
//  Copyright © 2019 Sam Gardner. All rights reserved.
//

#import "DecryptViewController.h"
#include <sys/sysctl.h>
#import "NSTask.h"

@interface DecryptViewController ()

@end

@implementation DecryptViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _successionPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.samgisaninja.SuccessionRestore.plist"];
    // Create a size_t and set it to the size used to allocate modelChar
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    //Gets iOS device model (ex iPhone9,1 == iPhone 7 GSM).
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    _deviceModel = [NSString stringWithUTF8String:modelChar];
    free(modelChar);
    
    //Gets iOS version and changes label.
    _deviceVersion = [[UIDevice currentDevice] systemVersion];
    
    // Set size to the size used to allocate buildChar
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    
    //Gets iOS device build number (ex 10.1.1 == 14B100 or 14B150) and changes label.
    //Thanks, Apple, for releasing two versions of 10.1.1, you really like making things hard on us.
    char *buildChar = malloc(size);
    sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
    _deviceBuild = [NSString stringWithUTF8String:buildChar];
    free(buildChar);
        NSTask *decryptDMGTask = [[NSTask alloc] init];
        [decryptDMGTask setArguments:[NSArray arrayWithObjects:@"dmg", @"extract", @"/var/mobile/Media/Succession/encrypted.dmg", @"/var/mobile/Media/Succession/rfs.dmg", @"-k", [self getRFSKey], nil]];
        NSPipe *outputPipe = [NSPipe pipe];
        [decryptDMGTask setStandardOutput:outputPipe];
        NSFileHandle *stdoutHandle = [outputPipe fileHandleForReading];
        [stdoutHandle waitForDataInBackgroundAndNotify];
        id observer;
        observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification
                                                                     object:stdoutHandle queue:nil
                                                                 usingBlock:^(NSNotification *note)
                    {
                        
                        NSData *dataRead = [stdoutHandle availableData];
                        NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
                        [self logToFile:stringRead atLineNumber:__LINE__];
                        [[self activityLabel] setText:stringRead];
                        [stdoutHandle waitForDataInBackgroundAndNotify];
                    }];
    [decryptDMGTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
    [self logToFile:@"launchpath set" atLineNumber:__LINE__];
    decryptDMGTask.terminationHandler = ^{
        // Let the user know that download is now complete
        UIAlertController *downloadComplete = [UIAlertController alertControllerWithTitle:@"Decrypt Complete" message:@"The rootfilesystem was successfully decrypted" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *backToHomePage = [UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[self navigationController] popToRootViewControllerAnimated:TRUE];
        }];
        [downloadComplete addAction:backToHomePage];
        [self presentViewController:downloadComplete animated:TRUE completion:nil];
    };
    [self logToFile:@"Launching dmg task..." atLineNumber:__LINE__];
    [decryptDMGTask launch];
}

-(NSString *)getRFSKey{
    // Let's fetch the rootfilesystem decryption key from theiphonewiki. TheiPhoneWiki's URLs are annoyingly machine unfriendly, formatted as https://www.theiphonewiki.com/wiki/<iOS_Codename>_<Buildnumber>_(<Machine ID>)
    // The hard part here is the version codename. Muirey03 suggested to me that it might be possible to obtain the codename from MobileGestalt, but every time I tried to call it, Succession would crash. So, hardcoding! Hooray for lack of future-proofing! (or in this case, past-proofing? idk.)
    NSDictionary *codenameForVersion = @{
                                         @"7.0" : @"Innsbruck",
                                         @"7.0.1" : @"Innsbruck",
                                         @"7.0.2" : @"Innsbruck",
                                         @"7.0.3" : @"InnsbruckTaos",
                                         @"7.0.4" : @"InnsbruckTaos",
                                         @"7.0.5" : @"InnsbruckTaos",
                                         @"7.0.6" : @"InnsbruckTaos",
                                         @"7.1" : @"Sochi",
                                         @"7.1.1" : @"SUSochi",
                                         @"7.1.2" : @"Sochi",
                                         @"8.0" : @"Okemo",
                                         @"8.0.1" : @"Okemo",
                                         @"8.0.2" : @"Okemo",
                                         @"8.1" : @"OkemoTaos",
                                         @"8.1.1" : @"SUOkemoTaos",
                                         @"8.1.2" : @"SUOkemoTaos",
                                         @"8.1.3" : @"SUOkemoTaosTwo",
                                         @"8.2" : @"OkemoZurs",
                                         @"8.3" : @"Stowe",
                                         @"8.4" : @"Copper",
                                         @"8.4.1" : @"Donner",
                                         @"9.0" : @"Monarch",
                                         @"9.0.1" : @"Monarch",
                                         @"9.0.2" : @"Monarch",
                                         @"9.1" : @"Boulder",
                                         @"9.2" : @"Castlerock",
                                         @"9.2.1" : @"Dillon",
                                         @"9.3" : @"Eagle",
                                         @"9.3.1" : @"Eagle",
                                         @"9.3.2" : @"Frisco",
                                         @"9.3.3" : @"Genoa",
                                         @"9.3.4" : @"Genoa",
                                         @"9.3.5" : @"Genoa",
                                         @"9.3.6" : @"Genoa"
                                         };
    // Hopefully that's accurate, if it isnt... welp.
    // SO! back to what we were doing, let's figure out what codename goes with this iOS version.
    // First let's check to make sure there isn't some edge case where I don't have the codename for the user's iOS version, getting the value for a nonexistent key results in a crash.
    if ([[codenameForVersion allKeys] containsObject:_deviceVersion]) {
        // yay, I have the codename for the user's iOS version. Let's make it useful.
        NSString *codename = [codenameForVersion objectForKey:_deviceVersion];
        // Now, the easiest way I could think of to obtain the decryption keys was to download the HTML page of theiphonewiki, convert it to a string, and parse, like so:
        NSURL *keyPageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://theiphonewiki.com/wiki/%@_%@_(%@)", codename, _deviceBuild, _deviceModel]];
        // Get the data of the page at keyPageURL
        NSData *keyPageData = [NSData dataWithContentsOfURL:keyPageURL];
        // Convert the data to a string
        NSString *keyPageString = [NSString stringWithUTF8String:[keyPageData bytes]];
        // Now let's check to see if theiphonewiki actually has the key we need
        if ([keyPageString containsString:@"<code id=\"keypage-rootfs-key\">"]) {
            // yay! it does. Lets parse now.
            // separate the into an array to isolate the rfs key
            NSArray *keyPageStringSeparated = [keyPageString componentsSeparatedByString:@"<code id=\"keypage-rootfs-key\">"];
            // get all the text after "keypage-rootfs-key>"
            NSString *theFunPartOfKeyPageString = [keyPageStringSeparated objectAtIndex:1];
            // trim it down further
            NSArray *theFunPartSeparated = [theFunPartOfKeyPageString componentsSeparatedByString:@"</code>"];
            [self logToFile:[theFunPartSeparated firstObject] atLineNumber:__LINE__];
            return [theFunPartSeparated firstObject];
        } else {
            // oof. key isnt available. :rip:
            [self logToFile:[NSString stringWithFormat:@"Key for %@ %@ not available.", _deviceModel, _deviceBuild] atLineNumber:__LINE__];
            UIAlertController *deviceNotSupported = [UIAlertController alertControllerWithTitle:@"Device not supported." message:@"The filesystem for your iOS version is encrypted, and a decryption key is not publicly available. If you are a researcher with a private key, please decrypt the DMG yourself using xpwn and place it in /var/mobile/Media/Succession/rfs.dmg (oh, and could you also pretty please post it to theiphonewiki)." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                exit(0);
            }];
            [deviceNotSupported addAction:exitAction];
            [self presentViewController:deviceNotSupported animated:TRUE completion:nil];
            return @"Failed.";
        }
        
    } else {
        // If the iOS version isn't in the dict above, then :rip:
        [self errorAlert:[NSString stringWithFormat:@"Couldn't get codename for your iOS %@\nPlease email me samgisaninja@unc0ver.dev or dm me on reddit u/Samg_is_a_Ninja", _deviceBuild]];
        return @"Failed.";
    }
}


-(void)errorAlert:(NSString *)message{
    [self logToFile:[NSString stringWithFormat:@"ERROR! %@", message] atLineNumber:__LINE__];
    UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }];
    [errorAlertController addAction:exitAction];
    [self presentViewController:errorAlertController animated:TRUE completion:nil];
}

- (void)logToFile:(NSString *)message atLineNumber:(int)lineNum {
    if ([[_successionPrefs objectForKey:@"log-file"] isEqual:@(1)]) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/mobile/succession.log"]) {
            [[NSFileManager defaultManager] createFileAtPath:@"/private/var/mobile/succession.log" contents:nil attributes:nil];
        }
        NSString *stringToLog = [NSString stringWithFormat:@"[SUCCESSIONLOG %@: %@] Line %@: %@\n", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [NSDate date], [NSString stringWithFormat:@"%d", lineNum], message];
        NSLog(@"%@", stringToLog);
        NSFileHandle *logFileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/private/var/mobile/succession.log"];
        [logFileHandle seekToEndOfFile];
        [logFileHandle writeData:[stringToLog dataUsingEncoding:NSUTF8StringEncoding]];
        [logFileHandle closeFile];
    }
}

@end
