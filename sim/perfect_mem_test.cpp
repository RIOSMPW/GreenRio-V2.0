#include "perfect_mem.hpp"
#include <assert.h>
#include <stdio.h>
int main(){
    PerfectMem pm;
    // printf("0x1000: %lx\n", pm.peek(uint32_t(0x1000)));
    // printf("resp:%x\n", pm.resp());

    for(int i = 0; i < 10 * 8; i += 8) assert(pm.peek64(i) == (uint64_t(i + 4) << 32) + uint64_t((i)));
    pm.read(0x1000);
    while(!pm.resp_valid()) {
        assert(!pm.ready());
        pm.eval();
    }
    // printf("resp:%lx\n", pm.resp());
    assert(pm.resp() == ((uint64_t(0x1004) << 32) + uint64_t(0x1000)));
    printf("test done\n");

    return 0;
}