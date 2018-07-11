/*
 *  hdik
 *
 *  Copyright (c) 2017 xerub
 */


#include <CoreFoundation/CoreFoundation.h>
#import "IOKit/IOKitLib.h"

int
attach(const char *path, char buf[], size_t sz)
{
    int rv;
    const char *rp;

    if (sz < 6) {
        return -1;
    }

    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0LL, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CFStringRef uuidstr = NULL;

    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    if (uuid) {
        uuidstr = CFUUIDCreateString(kCFAllocatorDefault, uuid);
        CFRelease(uuid);
    }

    CFDictionarySetValue(dict, CFSTR("hdik-unique-identifier"), uuidstr);
    CFRelease(uuidstr);

    rp = realpath(path, NULL);
    if (rp == NULL) {
        rp = path;
    }

    CFDataRef data = CFDataCreate(kCFAllocatorDefault, (void *)rp, strlen(rp));

    CFDictionarySetValue(dict, CFSTR("image-path"), data);
    CFRelease(data);

    CFDictionarySetValue(dict, CFSTR("autodiskmount"), kCFBooleanFalse);

    CFDataRef props = CFPropertyListCreateData(kCFAllocatorDefault, dict, kCFPropertyListXMLFormat_v1_0, 0, NULL);

    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOHDIXController"));
    if (!service) {
        return 1;
    }

    io_connect_t connect;
    rv = IOServiceOpen(service, mach_task_self(), 0, &connect);
    if (rv) {
        return 2;
    }

    struct HDIImageCreateBlock64 {
        uint64_t magic;
        const void *props;
        uint64_t props_size;
        char ignored[0x100 - 24];
    } stru;

    memset(&stru, 0, sizeof(stru));

    stru.magic = 0x1BEEFFEED;
    stru.props = CFDataGetBytePtr(props);
    stru.props_size = CFDataGetLength(props);

    uint32_t val = 0;
    size_t val_size = sizeof(val);

    rv = IOConnectCallStructMethod(connect, 0, &stru, sizeof(stru), &val, &val_size);
    CFRelease(props);
    IOObjectRelease(service);
    IOServiceClose(connect);

    if (rv) {
        fprintf(stderr, "rv = 0x%x\n", rv);
        CFRelease(dict);
        return rv;
    }

    // @comex
    CFMutableDictionaryRef matching = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(matching, CFSTR("IOPropertyMatch"), dict);
    CFRelease(dict);

    service = IOServiceGetMatchingService(kIOMasterPortDefault, matching);
    if (!service) {
        return 3;
    }

    bool ok = false;
    io_iterator_t iter;
    rv = IORegistryEntryCreateIterator(service, kIOServicePlane, kIORegistryIterateRecursively, &iter);
    if (rv) {
        return 4;
    }

    while ((service = IOIteratorNext(iter))) {
        CFStringRef bsd_name = IORegistryEntryCreateCFProperty(service, CFSTR("BSD Name"), NULL, 0);
        if (!bsd_name) {
            continue;
        }
        ok = CFStringGetCString(bsd_name, buf + 5, sz - 5, kCFStringEncodingUTF8);
        break;
    }

    if (!ok) {
        return 5;
    }

    buf[0] = '/';
    buf[1] = 'd';
    buf[2] = 'e';
    buf[3] = 'v';
    buf[4] = '/';
    return 0;
}

#ifdef HAVE_MAIN
int
main(void)
{
    char buf[4096];
    int rv = attach("r.dmg", buf, sizeof(buf));
    if (rv == 0) {
        puts(buf);
    }
    return rv;
}
#endif
