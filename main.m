#import "zip.h"
#import "determine_file_system_type.h"
#import "download.h"
#import <sys/types.h>
#import <sys/stat.h>
#import "file_exists_checker.h"
#import "folder_exists_checker.h"
#import "succession.h"
#import "hardware.h"
#import "succession_cli_can_run.h"
#import "file_string_checker.h"
int main()
{
int result=0;
if (succession_cli_can_run() ==false)
{
//we should exit
return 1;
}
printf("Welcome to SuccessionCLI, your %s (%s) is running iOS %s (%s) \n", device_model(), device_type(), system_version(), build_version());
   if ((folder_exists_checker("/var/mobile/Media/Succession") != 0 ))
{
mkdir("/var/mobile/Media/Succession", 0777);
download("/private/var/mobile/Media/Succession/motd.plist", "https://raw.githubusercontent.com/Samgisaninja/samgisaninja.github.io/master/motd-cli.plist");
download("/private/var/mobile/Media/Succession/devices.json", "https://api.ipsw.me/v4/devices");
download("/private/var/mobile/Media/Succession/SuccessionCLIVersion.txt", "https://raw.githubusercontent.com/Samgisaninja/samgisaninja.github.io/master/SuccessionCLIVersion.txt");
}
if (( file_exists_checker("/var/mobile/Media/Successionm/otd.plist", "r") != 0 ))
{
download("/private/var/mobile/Media/Succession/motd.plist", "https://raw.githubusercontent.com/Samgisaninja/samgisaninja.github.io/master/motd-cli.plist");
}
if (( file_exists_checker("/var/mobile/Media/Succession/devices.json", "r") != 0 ))
{
download("/private/var/mobile/Media/Succession/devices.json", "https://api.ipsw.me/v4/devices");
}
if (( file_exists_checker("/var/mobile/Media/Succession/SuccessionCLIVersion.txt", "r") != 0 ))
{
download("/private/var/mobile/Media/Succession/SuccessionCLIVersion.txt", "https://raw.githubusercontent.com/Samgisaninja/samgisaninja.github.io/master/SuccessionCLIVersion.txt");
}
if ((file_exists_checker("/var/mobile/Media/Succession/rfs.dmg", "r") == 0 )) 
{
bool shouldExitResponse =false;
while (shouldExitResponse == false )
{
printf("Succession has detected a root file system image (dmg), Would you like succession to use it? Y(es)/N(o) \n");
char response=getchar();
response=tolower(response);
putchar(response);
switch (response)
{
case 'y':
shouldExitResponse=true;
break;
case 'n':
shouldExitResponse=true;
break;
default:
shouldExitResponse=false;
break;
}
}
}
if ((file_exists_checker("/var/mobile/Media/Succession/succession.ipsw", "r") == 0 )) 
{
bool shouldExitResponse =false;
while (shouldExitResponse == false )
{
printf("Succession has detected an ipsw, would you like succession to use it? Y(es)/N(o) \n");
char response=getchar();
response=tolower(response);
putchar(response);
switch (response)
{
case 'y':
extract_manifest();
extract_ipsw();
shouldExitResponse=true;
case 'n':
//delete the ipsw somehow
shouldExitResponse=true;
default:
break;
}
}
}
//printf("%i \n", file_string_checker("file.txt", "aa"));
//printf("%s", determine_file_system_type());
return 0;
}
