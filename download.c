#include "download.h"
int progress_function(void *progress_callback, double total_to_download,   double now_downloaded,   double total_to_upload, double uploaded_now)
{
	printf("Downloading %i%% \r", (now_downloaded/total_to_download)*100);
fflush(stdout);

return 0;
}
int download(char *file, char *url)
{
FILE *fp=fopen(file, "w");
curl_global_init(CURL_GLOBAL_DEFAULT);
CURL *curl=curl_easy_init();
curl_easy_setopt(curl, CURLOPT_URL, url);
curl_easy_setopt(curl, CURLOPT_VERBOSE, 0L);
curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0);
curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, progress_function);
curl_easy_perform(curl);
curl_easy_cleanup(curl);

return 0;
}