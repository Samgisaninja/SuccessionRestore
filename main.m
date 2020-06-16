#include <stdio.h>
#include <sys/sysctl.h>
#import "NSTask.h"

int main(int argc, char *argv[], char *envp[]) {
	NSMutableArray *argumentsArray = [[NSMutableArray alloc] init];
	int i;
	for (i = 0; i < argc; i++) {
		[argumentsArray addObject:[NSString stringWithCString:argv[i] encoding:NSASCIIStringEncoding]];
	}
	[argumentsArray removeObject:@"SuccessionCLIhelper"];
	if ([argumentsArray count] < 1) {
		printf("This is a helper tool for succession.sh and cannot do anything on its own. If you'd like to erase your device, please run succession.sh\n");
	} else if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--deviceVersion"]) {
		printf("%s\n", [[[UIDevice currentDevice] systemVersion] UTF8String]);
	} else if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--deviceBuildNumber"]) {
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *buildChar = malloc(size);
		sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
		NSString *deviceBuildString = [NSString stringWithUTF8String:buildChar];
		printf("%s\n", [deviceBuildString UTF8String]);
		free(buildChar);
	} else if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--deviceModel"]) {
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *modelChar = malloc(size);
		sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
		NSString *deviceModelString = [NSString stringWithUTF8String:modelChar];
		free(modelChar);
		printf("%s\n", [deviceModelString UTF8String]);
	} else if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--freeSpace"]) {
		if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
			NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:@"/private/var/"];
			NSError *error = nil;
			NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
			if (!results) {
				printf("Error!\n");
			}
			NSString *freeSpace = [NSByteCountFormatter stringFromByteCount:[results[NSURLVolumeAvailableCapacityForImportantUsageKey] longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
			NSString *freeGigabytes = [freeSpace stringByReplacingOccurrencesOfString:@" GB" withString:@""];
			float freeBytesFloat = [freeGigabytes floatValue] * 1000000000;
			printf("%d\n", (int)freeBytesFloat);
#pragma clang diagnostic pop
		} else {
			NSDictionary *fattributes = [[NSDictionary alloc] init];
			fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:@"/private/var/" error:nil];
			NSNumber *fure = [fattributes objectForKey:NSFileSystemFreeSize];
			NSString *forFure = [NSByteCountFormatter stringFromByteCount:[fure longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
			NSString *freeGigabytes = [forFure stringByReplacingOccurrencesOfString:@" GB" withString:@""];
			float freeBytesFloat = [freeGigabytes floatValue] * 1000000000;
			printf("%d\n", (int)freeBytesFloat);
			
		}
	} else if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--deviceCommonName"]) {
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *modelChar = malloc(size);
		sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
		NSString *deviceModelString = [NSString stringWithUTF8String:modelChar];
		free(modelChar);
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/mobile/Media/Succession/devices.json"]) {
			NSArray *devicesArray = [NSJSONSerialization JSONObjectWithData:[[NSData alloc] initWithContentsOfFile:@"/private/var/mobile/Media/Succession/devices.json"] options:kNilOptions error:nil];
			for (NSDictionary *deviceInfo in devicesArray) {
				if ([[deviceInfo objectForKey:@"identifier"] isEqualToString:deviceModelString]) {
					printf("%s\n", [[deviceInfo objectForKey:@"name"] UTF8String]);
				}
			}
		} else {
			printf("Error! No API data available for parsing!\n");
		}
		
	} else if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--shouldIRun"]) {
		NSDictionary *motd = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Media/Succession/motd.plist"];
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *modelChar = malloc(size);
		sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
		NSString *deviceModelString = [NSString stringWithUTF8String:modelChar];
		free(modelChar);
		sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
		char *buildChar = malloc(size);
		sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
		NSString *deviceBuildString = [NSString stringWithUTF8String:buildChar];
		free(buildChar);
		NSString *dpkgStatus = [NSString stringWithContentsOfFile:@"/Library/dpkg/status" encoding:NSUTF8StringEncoding error:nil];
		NSString *myVersion;
		if ([dpkgStatus containsString:@"com.samgisaninja.successioncli"]) {
			NSArray *dpkgStatusArray = [dpkgStatus componentsSeparatedByString:@"Package: "];
			for (NSString *dpkgPackageStatus in dpkgStatusArray) {
				if ([dpkgPackageStatus containsString:@"com.samgisaninja.successioncli"]) {
					NSArray *statusLines = [dpkgPackageStatus componentsSeparatedByString:[NSString stringWithFormat:@"\n"]];
					for (NSString *line in statusLines) {
						if ([line hasPrefix:@"Version: "]) {
							myVersion = [line stringByReplacingOccurrencesOfString:@"Version: " withString:@""];
						}
					}
				}
			}
		} else {
			myVersion = @"1.0~alpha2";
		}
		if ([[[motd objectForKey:@"all"] objectForKey:@"disabled"] isEqual:@(1)]) {
			printf("false\n");
		} else if ([[[[motd objectForKey:@"successionVersions"] objectForKey:myVersion] objectForKey:@"disabled"] isEqual:@(1)]) {
			printf("false\n");
		} else if ([[[[motd objectForKey:@"deviceModels"] objectForKey:deviceModelString] objectForKey:@"disabled"] isEqual:@(1)]) { 
			printf("false\n");
		} else if ([[[[motd objectForKey:@"iOSVersions"] objectForKey:deviceBuildString] objectForKey:@"disabled"] isEqual:@(1)]) {
			printf("false\n");
		} else {
			printf("true\n");
		}
	} else if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--getMOTD"]) {
		NSDictionary *motd = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Media/Succession/motd.plist"];
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *modelChar = malloc(size);
		sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
		NSString *deviceModelString = [NSString stringWithUTF8String:modelChar];
		free(modelChar);
		sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
		char *buildChar = malloc(size);
		sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
		NSString *deviceBuildString = [NSString stringWithUTF8String:buildChar];
		free(buildChar);
		NSString *dpkgStatus = [NSString stringWithContentsOfFile:@"/Library/dpkg/status" encoding:NSUTF8StringEncoding error:nil];
		NSString *myVersion;
		if ([dpkgStatus containsString:@"com.samgisaninja.successioncli"]) {
			NSArray *dpkgStatusArray = [dpkgStatus componentsSeparatedByString:@"Package: "];
			for (NSString *dpkgPackageStatus in dpkgStatusArray) {
				if ([dpkgPackageStatus containsString:@"com.samgisaninja.successioncli"]) {
					NSArray *statusLines = [dpkgPackageStatus componentsSeparatedByString:[NSString stringWithFormat:@"\n"]];
					for (NSString *line in statusLines) {
						if ([line hasPrefix:@"Version: "]) {
							myVersion = [line stringByReplacingOccurrencesOfString:@"Version: " withString:@""];
						}
					}
				}
			}
		} else {
			myVersion = @"1.0~alpha2";
		}
		if ([[motd objectForKey:@"all"] objectForKey:@"messageContent"] && ![[[motd objectForKey:@"all"] objectForKey:@"messageContent"] isEqualToString:@"No MOTD"]) {
			printf("%s\n", [[[motd objectForKey:@"all"] objectForKey:@"messageContent"] UTF8String]);
		} else if ([[[motd objectForKey:@"successionVersions"] objectForKey:myVersion] objectForKey:@"messageContent"] && ![[[[motd objectForKey:@"successionVersions"] objectForKey:myVersion] objectForKey:@"messageContent"] isEqualToString:@"No MOTD"]) {
			printf("%s\n", [[[[motd objectForKey:@"successionVersions"] objectForKey:myVersion] objectForKey:@"messageContent"] UTF8String]);
		} else if ([[[motd objectForKey:@"deviceModels"] objectForKey:deviceModelString] objectForKey:@"messageContent"] && ![[[[motd objectForKey:@"deviceModels"] objectForKey:deviceModelString] objectForKey:@"messageContent"] isEqualToString:@"No MOTD"]) { 
			printf("%s\n", [[[[motd objectForKey:@"deviceModels"] objectForKey:deviceModelString] objectForKey:@"messageContent"] UTF8String]);
		} else if ([[[motd objectForKey:@"iOSVersions"] objectForKey:deviceBuildString] objectForKey:@"messageContent"] && ![[[[motd objectForKey:@"iOSVersions"] objectForKey:deviceBuildString] objectForKey:@"messageContent"] isEqualToString:@"No MOTD"]) {
			printf("%s\n", [[[[motd objectForKey:@"iOSVersions"] objectForKey:deviceBuildString] objectForKey:@"messageContent"] UTF8String]);
		} else {
			printf("No MOTD\n");
		}
	} else if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--needsDecryption"]) {
		if (kCFCoreFoundationVersionNumber < 1300) {
			printf("TRUE\n");
		} else {
			printf("FALSE\n");
		}
	} else if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--getKeyPageLink"]) {
		NSString *deviceVersion = [[UIDevice currentDevice] systemVersion];
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *modelChar = malloc(size);
		sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
		NSString *deviceModel = [NSString stringWithUTF8String:modelChar];
		free(modelChar);
		sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
		char *buildChar = malloc(size);
		sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
		NSString *deviceBuild = [NSString stringWithUTF8String:buildChar];
		free(buildChar);
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
		if ([[codenameForVersion allKeys] containsObject:deviceVersion]) {
			// yay, I have the codename for the user's iOS version. Let's make it useful.
			NSString *codename = [codenameForVersion objectForKey:deviceVersion];
			// Now, the easiest way I could think of to obtain the decryption keys was to download the HTML page of theiphonewiki, convert it to a string, and parse, like so:
			NSString *keyPageURL = [NSString stringWithFormat:@"https://theiphonewiki.com/wiki/%@_%@_(%@)", codename, deviceBuild, deviceModel];
			printf("%s\n", [keyPageURL UTF8String]);
		} else {
			// If the iOS version isn't in the dict above, then :rip:
			printf("%s\n", [[NSString stringWithFormat:@"Error! Couldn't get codename for your iOS %@\nPlease email me samgisaninja@unc0ver.dev or dm me on reddit u/Samg_is_a_Ninja", deviceBuild] UTF8String]);
		}
	} else if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--getDecryptionKey"]) {
		// Convert the data to a string
		NSString *keyPageString = [NSString stringWithContentsOfFile:@"/private/var/mobile/Media/Succession/keypage.txt" encoding:NSUTF8StringEncoding error:nil];			// Now let's check to see if theiphonewiki actually has the key we need
		if ([keyPageString containsString:@"<code id=\"keypage-rootfs-key\">"]) {
			// yay! it does. Lets parse now.
			// separate the into an array to isolate the rfs key
			NSArray *keyPageStringSeparated = [keyPageString componentsSeparatedByString:@"<code id=\"keypage-rootfs-key\">"];
			// get all the text after "keypage-rootfs-key>"
			NSString *theFunPartOfKeyPageString = [keyPageStringSeparated objectAtIndex:1];
			// trim it down further
			NSArray *theFunPartSeparated = [theFunPartOfKeyPageString componentsSeparatedByString:@"</code>"];
			printf("%s\n", [[theFunPartSeparated firstObject] UTF8String]);
		} else {
			// oof. key isnt available. :rip:
			printf("Error! Key for your device not available.\n");
		}
	} else if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--beginRestore"]) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/mnt/succ/sbin/launchd"]) {
			printf("successionRestore called!\n");
			printf("verified filesystem is mounted\n");
			NSMutableArray *rsyncMutableArgs = [NSMutableArray arrayWithObjects:
												@"-vaxcH",
												@"--delete",
												@"--progress",
												@"--ignore-errors",
												@"--force",
												@"--exclude=/Developer",
												@"--exclude=/System/Library/Caches/com.apple.kernelcaches/kernelcache",
												@"--exclude=/System/Library/Caches/apticket.der",
												@"--exclude=/System/Library/Caches/com.apple.factorydata/",
												@"--exclude=/usr/standalone/firmware/sep-firmware.img4",
												@"--exclude=/usr/local/standalone/firmware/Baseband",
												@"--exclude=/private/var/mnt/succ/",
												@"--exclude=/private/etc/fstab",
												@"--exclude=/etc/fstab",
												@"--exclude=/usr/standalone/firmware/FUD/",
												@"--exclude=/usr/standalone/firmware/Savage/",
												@"--exclude=/System/Library/Pearl",
												@"--exclude=/usr/standalone/firmware/Yonkers/",
												@"--exclude=/private/var/containers/",
												@"--exclude=/var/containers/",
												@"--exclude=/private/var/keybags/",
												@"--exclude=/var/keybags/",
												@"--exclude=/applelogo",
												@"--exclude=/devicetree",
												@"--exclude=/kernelcache",
												@"--exclude=/ramdisk",
												@"/private/var/mnt/succ/.",
												@"/", nil];
			if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Caches/xpcproxy"] || [[NSFileManager defaultManager] fileExistsAtPath:@"/var/tmp/xpcproxy"]) {
				[rsyncMutableArgs addObject:@"--exclude=/Library/Caches/"];
				[rsyncMutableArgs addObject:@"--exclude=/usr/libexec/xpcproxy"];
				[rsyncMutableArgs addObject:@"--exclude=/tmp/xpcproxy"];
				[rsyncMutableArgs addObject:@"--exclude=/var/tmp/xpcproxy"];
				[rsyncMutableArgs addObject:@"--exclude=/usr/lib/substitute-inserter.dylib"];
			}
			NSError *error;
			NSString *fstabString = [NSString stringWithContentsOfFile:@"/private/etc/fstab" encoding:NSUTF8StringEncoding error:&error];
			NSString *filesystemType;
			if (!error) {
				if ([fstabString containsString:@"apfs"]) {
					filesystemType = @"apfs";
				} else if ([fstabString containsString:@"hfs"]){
					filesystemType = @"hfs";
				} else {
					printf("%s\n", [[NSString stringWithFormat:@"Error! Failed to identify filesystem, read fstab successfully, but fstab did not contain filesystem type: %@", fstabString] UTF8String]);
				}
			} else {
				printf("%s\n", [[NSString stringWithFormat:@"Failed to read fstab: %@", [error localizedDescription]] UTF8String]);
			}
			if (![filesystemType isEqualToString:@"apfs"]) {
				printf("non-APFS detected, excluding dyld-shared-cache to prevent running out of storage\n");
				[rsyncMutableArgs addObject:@"--exclude=/System/Library/Caches/com.apple.dyld/"];
			}
			NSTask *rsyncTask = [[NSTask alloc] init];
			[rsyncTask setLaunchPath:@"/usr/bin/rsync"];
			NSArray *rsyncArgs = [NSArray arrayWithArray:rsyncMutableArgs];
			[rsyncTask setArguments:rsyncArgs];
			NSPipe *outputPipe = [NSPipe pipe];
			[rsyncTask setStandardOutput:outputPipe];
			[rsyncTask setStandardError:outputPipe];
			NSFileHandle *stdoutHandle = [outputPipe fileHandleForReading];
			[stdoutHandle waitForDataInBackgroundAndNotify];
			id observer;
			observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:stdoutHandle queue:nil usingBlock:^(NSNotification *note){
				NSData *dataRead = [stdoutHandle availableData];
				NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
				printf("%s\n", [stringRead UTF8String]);
				[stdoutHandle waitForDataInBackgroundAndNotify];
			}];
			rsyncTask.terminationHandler = ^{
				printf("Restore has completed!\n");
				[[NSNotificationCenter defaultCenter] removeObserver:observer];
				extern int SBDataReset(mach_port_t, int);
				extern mach_port_t SBSSpringBoardServerPort(void);
				printf("Calling SBDataReset now...\n");
				SBDataReset(SBSSpringBoardServerPort(), 5);
			};
			if ([rsyncTask launchPath]) {
				printf("rsyncTask has a valid launchPath, lets go!\n");
				[rsyncTask launch];
				[rsyncTask waitUntilExit];
			} else {
				printf("Unable to apply launchPath to rsyncTask. Please (re)install rsync from Cydia.\n");
			}
		} else {
			printf("Error! Filesystem not mounted.\n");
		}
	} else {
		printf("This is a helper tool for succession.sh and cannot do anything on its own. If you'd like to erase your device, please run succession.sh\n");
	}
}
