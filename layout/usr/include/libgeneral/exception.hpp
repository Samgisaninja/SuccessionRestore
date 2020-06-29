//
//  exception.hpp
//  libgeneral
//
//  Created by tihmstar on 09.03.18.
//  Copyright © 2018 tihmstar. All rights reserved.
//

#ifndef exception_hpp
#define exception_hpp

#include <string>

namespace tihmstar {
    class exception : public std::exception{
        int _code;
        std::string _filename;
        char *_err;
    public:
        exception(int code, const char *filename, const char *err ...);
        
        //custom error can be used
        const char *what();
        
        /*
         -first lowest two bytes of code is sourcecode line
         -next two bytes is strlen of filename in which error happened
         */
        int code() const;
        
        virtual void dump() const;
        
        //Information about build
        virtual std::string build_commit_count() const;
        virtual std::string build_commit_sha() const;
        
        ~exception();
    };
};

#endif /* exception_hpp */
