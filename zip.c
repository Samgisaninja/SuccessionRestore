
#include <stdio.h>
#include <sys/stat.h>
int main()
{
char ch;
FILE *zip;
zip=popen("7z l /private/var/mobile/Media/Succession/succession.ipsw | grep \"dmg\" | sort -k 4 | awk 'END {print $NF}'", "r");

    while( (ch=fgetc(zip)) != EOF)
        putchar(ch);
    pclose(zip);


return 0;
}