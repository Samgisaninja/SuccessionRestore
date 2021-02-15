#import "folder_exists_checker.h"
int folder_exists_checker(char *folder_name)
{
DIR* dir = opendir(folder_name);
if ( dir==NULL )
{
return -1;
}
else
 {
closedir(dir);
return 0;
}
}