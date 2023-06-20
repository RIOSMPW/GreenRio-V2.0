#ifndef _MEMORY_H_
#define _MEMORY_H_

#include <stdint.h>
#include <functional>
#include <vector>

#include "Vhehe.h"

struct MagicMappedHandler {
    uint32_t start;
    uint32_t length;
    std::function<uint32_t(uint32_t)> handle_read;
    std::function<void(uint32_t, uint32_t, uint8_t)> handle_write;
};

struct MagicMemory {    //一个完全cpp的memory model的最外层wrapper
    std::vector<MagicMappedHandler> mapping;    //多个不连续的handler 对应于meomry 中的一个个section?

    int d_wait;
    int i_wait;
    void I_Request(Vhehe* core);
    void D_Request(Vhehe* core);
    void addHandler(MagicMappedHandler &handler);
    uint32_t* addRamHandler(uint32_t start, uint32_t length);
};

bool loadFromElfFile(const char* filename, uint32_t* data, uint32_t start, uint32_t length);

#endif
