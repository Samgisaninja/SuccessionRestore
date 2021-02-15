#import "file_exists_checker.h"
int file_exists_checker(char *file_name, char *mode)
{
FILE * file=fopen(file_name, mode);
if ( file==NULL )
{
return -1;
}
else {
//fclose(file);
return 0;
}
return 0; 
}
