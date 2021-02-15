#include <curl/curl.h>
#include <stdio.h>
int progress_callback(void *progress_callback, double total_to_download,   double now_downloaded,   double total_to_upload, double uploaded_now);
 int download(char *file, char *url);