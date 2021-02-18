#include <string.h>
#include "succession.h"

#include <stdio.h>
#include <sys/stat.h>
void extract_manifest()
{
FILE *unzip;
char ch;
unzip=popen("7z x /private/var/mobile/Media/Succession/succession.ipsw -o/var/mobile/Media/Succession BuildManifest.plist", "r"); 
    while( (ch=fgetc(unzip)) != EOF)
putchar(ch);
pclose(unzip);
 }
void extract_ipsw()
{
int counter = 0;
char ch;
char command[1000];
char output[40];
FILE *unzip;
unzip=popen("7z l /private/var/mobile/Media/Succession/succession.ipsw | grep \"dmg\" | sort -k 4 | awk 'END {print $NF}'", "r");

    while( (ch=fgetc(unzip)) != EOF)
{
output[counter]=ch;
counter++;
}
printf("%s \n", output);
pclose(unzip);
sprintf(command, "7z x /private/var/mobile/Media/Succession/succession.ipsw -o/var/mobile/Media/Succession %s", output);
unzip=popen(command, "r+");
    while( (ch=fgetc(unzip)) != EOF)
putchar(ch);
pclose(unzip);

}