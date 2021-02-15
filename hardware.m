#import "hardware.h"
const char * system_name()
{
return [[[UIDevice currentDevice] systemName] UTF8String];
}
const char * system_version()
{
return [[[UIDevice currentDevice] systemVersion] UTF8String];
} 
const char * device_model()
{
return [[[UIDevice currentDevice] model] UTF8String];
}
const char * device_name() 
{
return [[[UIDevice currentDevice] name] UTF8String];
}
const char * device_type()
{
NSString *deviceType;
struct utsname dt;
            uname(&dt);

            deviceType = [NSString stringWithFormat:@"%s", dt.machine];
return [deviceType UTF8String];
}
const char * build_version()
{
	size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *buildChar = malloc(size);
		sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
		NSString *deviceBuildString = [NSString stringWithUTF8String:buildChar];
return [deviceBuildString UTF8String];
} 