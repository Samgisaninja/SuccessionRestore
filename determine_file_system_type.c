#include "determine_file_system_type.h"
const char *determine_file_system_type()
{
struct statfs output;
statfs("/", &output);
//printf("Type: %u", output.f_type);
//printf("Subtype: %u", output.f_fssubtype);
//printf("Type name: %s", output.f_fstypename);
return output.f_fstypename;
}
