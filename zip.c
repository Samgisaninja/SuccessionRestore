#include <zip.h>
#include <stdio.h>
#include <sys/stat.h>
int main()
{
struct zip *p;
int error;
p=zip_open("/var/mobile/Media/Succession/succession.ipsw", 0, &error);
printf("%d \n", error);
return 0;
}


