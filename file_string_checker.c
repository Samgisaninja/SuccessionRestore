
#include "file_string_checker.h"
int file_string_checker(char *file_name, char *string) {
	FILE *fp;
	int line_num = 1;
	int find_result = 0;
	char temp[512];
	

	if((fp = fopen(file_name, "r")) == NULL) {
		return(-1);
	}
while(fgets(temp, 512, fp) != NULL) {
		if((strstr(temp, string)) != NULL) {
return 1;
break;
		}
	}

	if(find_result == 0) {
return 0;

	}
	
	//Close the file if still open.
	if(fp) {
		fclose(fp);
	}
return(0);
}