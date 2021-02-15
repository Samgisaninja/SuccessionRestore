#include <sys/sysctl.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <sys/utsname.h>
const char * system_name();
const char * system_version();
const char * device_model();
const char * device_name();
const char * device_type();
const char * build_version();