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
