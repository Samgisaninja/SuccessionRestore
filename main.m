#include <stdio.h>
#include <sys/sysctl.h>

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
		printf("%s\n", [[freeSpace UTF8String] stringByReplacingOccurrencesOfString:@" GB" withString:@""]);
#pragma clang diagnostic pop
	} else {
		NSDictionary *fattributes = [[NSDictionary alloc] init];
		fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:@"/private/var/" error:nil];
		NSNumber *fure = [fattributes objectForKey:NSFileSystemFreeSize];
		NSString *forFure = [NSByteCountFormatter stringFromByteCount:[fure longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
		printf("%s\n", [[forFure UTF8String] stringByReplacingOccurrencesOfString:@" GB" withString:@""]);
		
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
			myVersion = @"1.0~alpha1";
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
			myVersion = @"1.0~alpha1";
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
			// DO DANGER
		} else {
			printf("ERROR! Filesystem not mounted.\n");
		}
	} else {
		printf("This is a helper tool for succession.sh and cannot do anything on its own. If you'd like to erase your device, please run succession.sh\n");
	}
}
