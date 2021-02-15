#import <string.h>
#import <stdbool.h>
#import "hardware.h"

bool succession_cli_can_run()
{
static int result;
if(geteuid() != 0)
{
//we failed to get root
printf("SuccessionCLI needs to be run as root. Please \"su\" and try again. Alternatively, try ssh root@your_ip_address");
return false;
}
else 
{
return true;
}
if (result==strncmp(system_version(), "9", 1) ==0 )
{
if ( (result=strcmp(device_type(), "iPhone8,1") ==0 ) || (result=strcmp(device_type(), "iPhone8,2") ==0 ) ) {
{
printf("Succession doesn't work on this version");
return false;
}
}
}
else 
{
return true;
}
}