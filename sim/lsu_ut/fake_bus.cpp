#ifndef _FAKE_BUS_CPP_
#define _FAKE_BUS_CPP_
#include "./fake_bus.hpp"
void FakeBus::req_vld(const bool& vld){
    _req_vld = vld;
}
void FakeBus::req(const uint64_t& pa, const uint64_t& d, const uint8_t& ri, 
        const uint8_t& rd, const uint16_t& de, const bool& fence, const bool& ls, const uint8_t& sel){
    uint64_t paddr = pa;
    uint16_t delay = BUS_BASE_DELAY + rand() % BUS_MAX_DELAY;
    _req = BusEntry(paddr, d, ri, rd, delay, fence, ls, sel);        
}

bool FakeBus::resp_vld(){
    return _resp_vld;
}

BusEntry FakeBus::resp(){
    return _bus_entry;
}

void FakeBus::eval(){
    _resp_vld = 0;
    if(_req_vld && !_bus_entry_vld){ // handshake
        _bus_entry_vld = 1;
        _bus_entry = _req;
        uint64_t data = _bus_entry.data;
        bool ls = _bus_entry.load_or_store;
        uint8_t sel = _bus_entry.opcode;
        uint64_t paddr = _bus_entry.paddr;
        try{
            if(!ls) {
                switch (sel)
                {
                case 0b1:
                    data = _real_mem->lbu(uint16_t(paddr));
                    break;
                case 0b0011:
                    data = _real_mem->lhu(uint16_t(paddr));
                    break;
                case 0b1111:
                    data = _real_mem->lwu(uint16_t(paddr));
                    break;
                default:
                    break;
                }
                _bus_entry.data = data;
            }
            else{
                switch (sel)
                {
                case 0b1:
                    _real_mem->sb(uint16_t(paddr), data);
                    break;
                case 0b0011:
                    _real_mem->sh(uint16_t(paddr), data);
                    break;
                case 0b1111:
                    _real_mem->sw(uint16_t(paddr), data);
                    break;
                default:
                    break;
                }
            }
        }
        catch (const char* msg){
            throw msg;
        }
#ifdef LOG_ENABLE
        LOG << "\tt " << std::dec << TIME << ":bus enque.\t\t"
            << (_bus_entry.load_or_store ? "store sel: " : "load sel: ") << std::dec << uint32_t(_bus_entry.opcode) << "\t"
            << " @ 0x" << std::hex  << _bus_entry.paddr << "\t"
            << " delay: " << std::dec << uint32_t(_bus_entry.delay) << "\t";
        if(_bus_entry.load_or_store){
            LOG << " data: " << std::hex << _bus_entry.data;
        }
        LOG << std::endl;
#endif // LOG_ENABLE
    }
    
    if((_bus_entry.delay == 0) && _bus_entry_vld) {
#ifdef LOG_ENABLE
        LOG << "\tt " << std::dec << TIME << ":bus resp.\t\t"
            << (_bus_entry.load_or_store ? "store sel: " : "load sel: ") << std::dec << uint32_t(_bus_entry.opcode) << "\t"
            << " @ 0x" << std::hex  << _bus_entry.paddr << "\t"
            << " delay: " << std::dec << uint32_t(_bus_entry.delay) << "\t";
        if(!_bus_entry.load_or_store){
            LOG << " data: " << std::hex << _bus_entry.data;
        }
        LOG << std::endl;
#endif // LOG_ENABLE
        _resp_vld = 1;
        _bus_entry_vld = 0; // shakehand
    }
    if(_bus_entry.delay > 0) _bus_entry.delay--;
}
#endif // _FAKE_BUS_CPP_
