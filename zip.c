#include <string.h>
#include "succession.h"

#include <stdio.h>
#include <sys/stat.h>
int main()
{
int counter = 0;
char ch;
char output[40];
FILE *zip;

zip=popen("7z l /private/var/mobile/Media/Succession/succession.ipsw | grep \"dmg\" | sort -k 4 | awk 'END {print $NF}'", "r");

    while( (ch=fgetc(zip)) != EOF)
{
output[counter]=ch;
counter++;
}
printf("%s \n", output);
pclose(zip);
strcpy(output, output);
zip=popen("7z x /private/var/mobile/Media/Succession/succession.ipsw -o/var/mobile/Media/Succession 'output' -r", "r+");
    while( (ch=fgetc(zip)) != EOF)
putchar(ch);


pclose(zip);

    pclose(zip);


return 0;
}