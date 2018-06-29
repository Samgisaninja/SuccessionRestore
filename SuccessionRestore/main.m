//
//  main.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 9/27/17.
//  Copyright © 2017 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <sys/stat.h>
#import <unistd.h>
#import "AppDelegate.h"
#define FLAG_PLATFORMIZE (1 << 1)

// Special thanks to PsychoTea (@IBSparkles) for getting root on kernel patch jailbreaks, as well as for both Electra's and Meridian's "kppless" jailbreakd daemon.

void platformize_me() {
    void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle) return;
    
    // Reset errors
    dlerror();
    typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
    fix_entitle_prt_t ptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");
    
    const char *dlsym_error = dlerror();
    if (dlsym_error) return;
    
    ptr(getpid(), FLAG_PLATFORMIZE);
}

void patch_setuid() {
    void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle)
        return;
    
    // Reset errors
    dlerror();
    typedef void (*fix_setuid_prt_t)(pid_t pid);
    fix_setuid_prt_t ptr = (fix_setuid_prt_t)dlsym(handle, "jb_oneshot_fix_setuid_now");
    
    const char *dlsym_error = dlerror();
    if (dlsym_error)
        return;
    
    ptr(getpid());
}

int main(int argc, char * argv[]) {
    @autoreleasepool {
   setuid(0);

  if (getuid() != 0) {
  	//Gets setuid on Electra 
    patch_setuid();
    platformize_me();
    setuid(0); // electra requires you to call setuid again
  }
	//Gets setuid on Meridian
  if (getuid() != 0) {
      patch_setuid();
  }
	return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
}
}
