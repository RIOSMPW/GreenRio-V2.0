#ifndef _MONITOR_CPP_
#define _MONITOR_CPP_
#include "monitor.hpp"

void Monitor::lsu_head(const uint16_t& h){
    _lsu_head = h;
}
void Monitor::lsu_tail(const uint16_t& t){
    _lsu_tail = t;
}

void Monitor::rcu_ready(const bool& rcu_rdy){
    _rcu_ready = rcu_rdy;
}

bool Monitor::req_vld(){
    return _req_vld;
}

Req Monitor::req(){
    return _req;
}

void Monitor::resp_vld(const bool& vld){
    _resp_vld = vld; 
}
void Monitor::resp(const Req& r){
    _resp = r;
}    

bool Monitor::ut_done(){
    return( _req_iss_num == _testcase_max) && (_resp_comm_num == _testcase_max);
}

void Monitor::eval(){
    // new req
    std::string txt = "";
    if(_rcu_ready && _req_vld){ // shake hand
        if(_req.load_or_store == 0)
            _rd_free_list.pop_front();
        _req_iss_num ++;
        _req_vld = 0;
        // if(!_req.load_or_store) // ! do not consider SC
        _iss_que->push_back(_req);
        // update perfect mem
    }

    // send new req
    // printf("iss num:%u \n", _req_iss_num);

    if((rand() % 3 == 0) && _req_iss_num < _testcase_max){
        bool ls = rand() % 2;
        // bool ls = 1; // ! only store
        bool is_fenced = ls ? (rand() % 10 == 0) : 0;
        // bool is_fenced =  0;
        uint8_t op = 0;
        uint64_t paddr_base = uint64_t(0x80000000);
        uint64_t paddr_offset = 0;
        if(ls){// store
            op = rand() % 4;
        }
        else{
            op = rand() % 7;
        }
#ifdef RANDOM_PADDR_ENABLE
        paddr_offset = rand() & 0xffff;
#else // RANDOM_PADDR_ENABLE
        paddr_offset = 0;
#endif
// #ifdef IO_ENABLE
//         if(rand() % 10 == 0){
//             paddr_base = 0;
//             paddr_offset = IO_ADDR_LOW;
//             if(ls){// store
//                 op = rand() % 3;
//             }
//             else{
//                 op = rand() % 7;
//                 while(op != 3){
//                     op = rand() % 7;
//                 } // ld
//             }
//         }
// #endif // IO_ENABLE
        uint64_t paddr = paddr_base + paddr_offset;
        uint64_t data = 0;
        if(ls) 
            data = (uint64_t(rand()) << 32) + uint64_t(rand());
        uint8_t rob_index = 0;
        uint8_t rd_addr = ls ? 0 : _rd_free_list.front(); 
        uint8_t delay = WAKEUP_BASE_DELAY + rand() % WAKEUP_MAX_DELAY;
        
        paddr &= ~(uint64_t(0b111));
        _req_vld = 1;
        _req = Req(paddr, data, rob_index, rd_addr, delay, is_fenced, ls, op);  
        _visit_history[uint16_t(paddr)].push_back(TIME);

    }

    // new resp
    if(_resp_vld){ // ! do not consider SC
        _resp_vld = 0;
        _resp_comm_num ++;
        // printf("monitor new resp: @ 0x%lx\n", _resp.paddr);
        try{
            if(_iss_que->front().paddr != _resp.paddr){
                // printf("_iss_que->front().paddr:%d  _resp.paddr:%d\n", _iss_que->front().paddr, _resp.paddr);
                throw "lsu commit in wrong order";
            }
            // _resp.paddr = _iss_que->front().paddr;
            // _resp.opcode = _iss_que->front().opcode;
            _iss_que->pop_front();
            if(!_resp.load_or_store)
                _rd_free_list.push_back(_resp.rd_addr);

            if(!_resp.load_or_store){
                int size = 0;
                int unsign = 0;
                switch (_resp.opcode)
                {
                case LDU_LB:
                    size = 0;
                    unsign = 0;
                    break;
                case LDU_LH:
                    size = 1;
                    unsign = 0;
                    break;
                case LDU_LW:
                    size = 2;
                    unsign = 0;
                    break;
                case LDU_LD:
                    size = 3;
                    unsign = 1;
                    break;
                case LDU_LBU:
                    size = 0;
                    unsign = 1;
                    break;
                case LDU_LHU:
                    size = 1;
                    unsign = 1;
                    break;
                case LDU_LWU:
                    size = 2;
                    unsign = 1;
                    break;
                default:
                    break;
                }
                uint64_t data = 0;
                for(int i = 0; i < (1 << size); i ++){
                    data += uint64_t(_perfect_mem->get_byte(_resp.paddr + i)) << (i * 8);
                }
                if(!unsign){
                    if(size == 0 && ((data & 0x80) == 0x80)){
                        data |= 0xffffffffffffff00;
                    }
                    else if(size == 1 && ((data & 0x8000) == 0x8000)){
                        data |= 0xffffffffffff0000;
                    }
                    else if(size == 2 && ((data & 0x80000000) == 0x80000000)){
                        data |= 0xffffffff00000000;
                    }
                }
                if(data != _resp.data){
#ifdef LOG_ENABLE
                    LOG << "load fail!" << std::endl;
                    LOG << (_resp.load_or_store ? "store " : "load ")
                        << uint32_t(_resp.opcode) << "\t"
                        << "@ 0x" << std::hex << _resp.paddr
                        << std::endl;
                    LOG << "correct mem: " << std::hex << data << std::endl;
                    LOG << "real mem: " << std::hex << _resp.data << std::endl; 
#endif // LOG_ENABLE
                    throw "load fail!";
                }
            }
            else{
                try{
                    int size = 0;
                    switch (_resp.opcode)
                    {
                    case STU_SB:
                        size = 0;
                        break;
                    case STU_SH:
                        size = 1;
                        break;
                    case STU_SW:
                        size = 2;
                        break;
                    case STU_SD:
                        size = 3;
                        break;
                    default:
                        break;
                    }
                    for(int i = 0; i < (1 << size); i ++){
                        _perfect_mem->set_byte(_resp.paddr + i, uint8_t(_resp.data >> (i * 8)));
                    }
                }
                catch (const char* msg){
                    throw msg;
                }
            }
            if(_resp_comm_num % MEM_CHEKCPOINT == 0 && _resp_comm_num != 0){
                std::cout << "=============\n" << std::dec << _resp_comm_num << " cases done\n=============\n";
                // printf("=============\n%d cases done\n=============\n", _resp_comm_num);
            }
        }
        catch (const char* msg){
            throw msg;
        }
    }

    // if(_resp_comm_num > 0 && (_resp_comm_num % 100 == 0) && !_print_flag){
    //     printf("%d cases pass\n", _resp_comm_num);
    //     _print_flag = 1;
    // }else if(_resp_comm_num > 0 && (_resp_comm_num % 100 == 1) && _print_flag){
    //     _print_flag = 0;
    // }
    
}

bool Monitor::mem_check(){
    for(int i = 0; i < MEM_MAX_SIZE; i ++){
        if(_perfect_mem->get_byte(i) == _real_mem->get_byte(i)) continue;
        LOG << "mem check fail @ 0x" << std::hex << (i << 3) << std::endl
            << "correct mem is 0x" << std::hex << _perfect_mem->get_byte(i) << std::endl
            << "real mem is 0x" << std:: hex << _real_mem->get_byte(i) << std::endl;
        uint16_t addr = uint16_t(i << 3);
        for(int j = 0; j < 8; j ++){
            if(_perfect_mem->get_byte(addr + j) == _real_mem->get_byte(addr + j)) continue;
            LOG << "history visit of this paddr are at time:" << std::endl;
            for(int k = 0; k < _visit_history[uint16_t(addr + j)].size(); k ++){
                LOG << "\t" << _visit_history[uint16_t(addr + j)][k] << std::endl;
            }
        }
        return false;
    }
    LOG << "\nmem check succ" << std::endl
    << "real mem: " << std::dec << _real_mem->visit_time() << std::endl
    << "perfect mem: " << std::dec << _perfect_mem->visit_time()
    << std::endl;
    return true;
}

#endif // _MONITOR_CPP_