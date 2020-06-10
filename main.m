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
	if ([[argumentsArray objectAtIndex:0] isEqualToString:@"--deviceVersion"]) {
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
				NSLog(@"Error retrieving resource keys: %@\n%@", [error localizedDescription], [error userInfo]);
				printf("Error\n");
			}
			NSString *freeSpace = [NSByteCountFormatter stringFromByteCount:[results[NSURLVolumeAvailableCapacityForImportantUsageKey] longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
			NSString *freeGigabytes = [freeSpace stringByReplacingOccurrencesOfString:@" GB" withString:@""];
			float freeBytesFloat = [freeGigabytes floatValue] * 1000000000;
			printf("%f\n", freeBytesFloat);
#pragma clang diagnostic pop
		} else {
			NSDictionary *fattributes = [[NSDictionary alloc] init];
			fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:@"/private/var/" error:nil];
			NSNumber *fure = [fattributes objectForKey:NSFileSystemFreeSize];
			NSString *forFure = [NSByteCountFormatter stringFromByteCount:[fure longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
			NSString *freeGigabytes = [forFure stringByReplacingOccurrencesOfString:@" GB" withString:@""];
			float freeBytesFloat = [freeGigabytes floatValue] * 1000000000;
			printf("%f\n", freeBytesFloat);
			
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
			printf("ERROR! No API data available for parsing!\n");
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
			printf("ERROR! Filesystem not mounted.\n");
		}
	} else {
		printf("This is a helper tool for succession.sh and cannot do anything on its own. If you'd like to erase your device, please run succession.sh\n");
	}
}
