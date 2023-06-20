#ifndef _UTIL_CPP_
#define _UTIL_CPP_
#include "./util.hpp"

void init_log(){
    LOG.open(LOG_PATH);
    std::time_t result = std::time(nullptr);
    LOG << std::asctime(std::localtime(&result)) << std::endl;
}

void close_log(){
    LOG.close();
}

void sync_time(const uint64_t& t){
    TIME = t;
}
#endif //_UTIL_CPP_