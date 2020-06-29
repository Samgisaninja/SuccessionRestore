//
//  macros.h
//  libgeneral
//
//  Created by tihmstar on 03.05.19.
//  Copyright © 2019 tihmstar. All rights reserved.
//

#ifndef macros_h
#define macros_h

#include <assert.h>

#ifdef DEBUG //versioning
#	ifndef VERSION_COMMIT_COUNT
#   	define VERSION_COMMIT_COUNT "Debug"
#	endif
#	ifndef VERSION_COMMIT_SHA
#   	define VERSION_COMMIT_SHA "Build: " __DATE__ " " __TIME__
#	endif
#	ifdef HAVE_CONFIG_H
#		include <config.h>
#	endif
#else
#include <config.h>
#endif

#ifndef PACKAGE_NAME
#define PACKAGE_NAME "PACKAGE_NAME_not_set"
#endif

#ifndef VERSION_MAJOR
#define VERSION_MAJOR "0"
#endif

#define VERSION_STRING PACKAGE_NAME " version: " VERSION_MAJOR "." VERSION_COMMIT_COUNT "-" VERSION_COMMIT_SHA


// ---- functions ----

// -- logging --
#ifndef CUSTOM_LOGGING
#define info(a ...) ({printf(a),printf("\n");})
#define log(a ...) ({printf(a),printf("\n");})
#define warning(a ...) ({printf("[WARNING] "), printf(a),printf("\n");})
#define error(a ...) ({printf("[Error] "),printf(a),printf("\n");})
#   ifdef DEBUG
#       define debug(a ...) ({printf("[DEBUG] "),printf(a),printf("\n");})
#   else
#       define debug(a ...)
#   endif
#endif

#define safeFree(ptr) ({if (ptr) free(ptr),ptr=NULL;})
#define safeFreeCustom(ptr,func) ({if (ptr) func(ptr),ptr=NULL;})
#define safeFreeConst(ptr) ({if(void *fbuf = (void*)ptr){ptr = NULL; free(fbuf);}})

#ifdef __cplusplus
#include <functional>
#   ifndef NO_EXCEPT_ASSURE
#       define EXCEPT_ASSURE
#   endif
#endif


// -- assure --

#   define cassure(a) do{ if ((a) == 0){err=__LINE__; goto error;} }while(0)
#   define cretassure(cond, errstr ...) do{ if ((cond) == 0){err=__LINE__;error(errstr); goto error;} }while(0)
#   define creterror(estr ...) do{error(estr);err=__LINE__; goto error; }while(0)


#ifdef EXCEPT_ASSURE
#include "exception.hpp"
//assure cpp
#   define assure(cond) do{ if ((cond) == 0) throw tihmstar::EXPECTIONNAME(__LINE__, __FILE__, "assure failed"); } while(0)
#   define retassure(cond, errstr ...) do{ if ((cond) == 0) throw tihmstar::EXPECTIONNAME(__LINE__,__FILE__,errstr); } while(0)
#   define customassure(cond, custom_except) do{ if ((cond) == 0) throw tihmstar::custom_except(__LINE__, __FILE__, "assure failed"); } while(0)
#   define retcustomassure(cond, custom_except,errstr ...) do{ if ((cond) == 0) throw tihmstar::custom_except(__LINE__, __FILE__, errstr); } while(0)
#   define reterror(errstr ...) do{ throw tihmstar::EXPECTIONNAME(__LINE__, __FILE__, errstr); } while(0)
#   define retcustomerror(custom_except,errstr ...) do{ throw tihmstar::custom_except(__LINE__, __FILE__, errstr); } while(0)
#   define doassure(cond,code) do {if (!(cond)){(code);assure(cond);}} while(0)
//mach assures
#   define assureMach(kernRet) do {kern_return_t __kret = kernRet; if (__kret) throw tihmstar::EXPECTIONNAME(__LINE__, __FILE__, "assure failed");} while(0)
#   define assureMachclean(kernRet) do {kern_return_t __kret = kernRet; if (__kret){clean();assureMach(__kret);}} while(0)
#   define assureCatchClean(code) do {try { code; } catch (EXPECTIONNAME &e) { clean(); throw; }} while (0)
#   define assureNoDoublethrow(code) \
        do{try {code;} catch (EXPECTIONNAME &e) {if (isInException) {error("Double exception! Error in line=%d",__LINE__);}else{throw;}}}while (0)


// //more cpp assure
#   ifndef EXPECTIONNAME
#       define EXPECTIONNAME exception
#   endif


class guard{
    std::function<void()> _f;
public:
    guard(std::function<void()> cleanup) : _f(cleanup) {}
    guard(const guard&) = delete; //delete copy constructor
    guard(guard &&o) = delete; //move constructor
    
    ~guard(){_f();}
};
#define cleanup(f) guard _cleanup(f);

#else
//assure c
#   define assure(a) cassure(a)
#   define retassure(cond, errstr ...) cretassure(cond, errstr)
#   define reterror(estr ...) creterror(estr)

#endif

#endif /* macros_h */
