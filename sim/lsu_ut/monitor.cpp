#ifndef _MONITOR_CPP_
#define _MONITOR_CPP_
#include "monitor.hpp"

void Monitor::lsu_head(const uint16_t& h){
    _lsu_head = h;
}
void Monitor::lsu_tail(const uint16_t& t){
    _lsu_tail = t;
}
void Monitor::lsu_iss_vld(const bool& v){
    _lsu_iss_vld = v;
}
void Monitor::lsu_iss_is_fenced(const bool& f){
    _lsu_iss_is_fenced = f;
}
void Monitor::lsu_iss_lsq_index(const uint16_t& ri){
    _lsu_iss_lsq_index = ri;
}

void Monitor::l1d_req_vld(const bool& v){
    _l1d_req_vld = v;
}
void Monitor::l1d_req_is_fenced(const bool& f){
    _l1d_req_is_fenced = f;
}
void Monitor::l1d_req_rob_index(const uint16_t& ri){
    _l1d_req_lsq_index = ri;
}
void Monitor::bus_req_vld(const bool& v){
    _bus_req_vld = v;
}
void Monitor::bus_req_is_fenced(const bool& f){
    _bus_req_is_fenced = f;
}
void Monitor::bus_req_rob_index(const uint16_t& ri){
    _bus_req_lsq_index = ri;
}

void Monitor::rcu_ready(const bool& rcu_rdy){
    _rcu_ready = rcu_rdy;
}

bool Monitor::req_vld(){
    return _req_vld;
}

RCUEntry Monitor::req(){
    return _req;
}

void Monitor::resp_vld(const bool& vld){
    _resp_vld = vld; 
}
void Monitor::resp(const RCUEntry& r){
    _resp = r;
}    

bool Monitor::ut_done(){
    return _req_iss_num == _testcase_max && _resp_comm_num == _testcase_max;
}

void Monitor::eval(){
    // commit fenced req
    if(_fenced_vld && (((_fenced_lsq_index + 1) % LSQ_DEPTH) == _lsu_head)){
        _fenced_vld = 0;
    }
    // new req
    if(_lsu_iss_vld){
        if(_fenced_vld && _lsu_iss_lsq_index != _fenced_lsq_index){
#ifdef LOG_ENABLE
            LOG << "t " << std::dec << TIME << ":lsu issue req beyond fence.\t\t"
            << " iss id: " << std::dec << _lsu_iss_lsq_index
            << " fenced id: " << std::dec << _fenced_lsq_index
            << std::endl;
#endif // LOG_ENABLE
            throw "all following requests shall not be issued before the fenced request has been issued";
        }
        if(_lsu_iss_is_fenced){
            if(_lsu_head != _lsu_iss_lsq_index){
#ifdef LOG_ENABLE
                LOG << "t " << std::dec << TIME << ":lsu issue fenced req before all previous requests have been committed.\t\t"
                << std::endl;
#endif // LOG_ENABLE
                throw "lsu issue fenced req before all previous requests have been committed";
            }

            _fenced_vld = 1;
            _fenced_lsq_index = _lsu_iss_lsq_index;
        }
    }
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
#ifdef IO_ENABLE
        if(rand() % 10 == 0){
            paddr_base = 0;
            paddr_offset = IO_ADDR_LOW;
            if(ls){// store
                op = rand() % 3;
            }
            else{
                op = rand() % 7;
                while(op != 3){
                    op = rand() % 7;
                } // ld
            }
        }
#endif // IO_ENABLE
        uint64_t paddr = paddr_base + paddr_offset;
        uint64_t data = 0;
        if(ls) 
            data = (uint64_t(rand()) << 32) + uint64_t(rand());
        uint8_t rob_index = 1;
        uint8_t rd_addr = ls ? 0 : _rd_free_list.front(); 
        uint8_t delay = WAKEUP_BASE_DELAY + rand() % WAKEUP_MAX_DELAY;
        
        paddr &= ~(uint64_t(0b111));
        _req_vld = 1;
        _req = RCUEntry(paddr, data, rob_index, rd_addr, delay, is_fenced, ls, op);  
        _visit_history[uint16_t(paddr)].push_back(TIME);

    }

    // new resp
    if(_resp_vld){ // ! do not consider SC
        _resp_vld = 0;
        _resp_comm_num ++;
        // printf("monitor new resp: @ 0x%lx\n", _resp.paddr);
        try{
            if(_iss_que->front().paddr != _resp.paddr){
                printf("_iss_que->front().paddr:%d  _resp.paddr:%d\n", _iss_que->front().paddr, _resp.paddr);
                throw "lsu commit in wrong order";
            }
            // _resp.paddr = _iss_que->front().paddr;
            // _resp.opcode = _iss_que->front().opcode;
            _iss_que->pop_front();
            uint64_t data = 0;
            if(!_resp.load_or_store)
                _rd_free_list.push_back(_resp.rd_addr);

            if(!_resp.load_or_store){
                switch (_resp.opcode)
                {
                case LDU_LB:
                    data = _perfect_mem->lb(uint16_t(_resp.paddr));
                    break;
                case LDU_LH:
                    data = _perfect_mem->lh(uint16_t(_resp.paddr));
                    break;
                case LDU_LW:
                    data = _perfect_mem->lw(uint16_t(_resp.paddr));
                    break;
                case LDU_LD:
                    data = _perfect_mem->ld(uint16_t(_resp.paddr));
                    if(_resp.paddr < 0x10000)
                        _perfect_mem->ld(0);
                    break;
                case LDU_LBU:
                    data = _perfect_mem->lbu(uint16_t(_resp.paddr));
                    break;
                case LDU_LHU:
                    data = _perfect_mem->lhu(uint16_t(_resp.paddr));
                    break;
                case LDU_LWU:
                    data = _perfect_mem->lwu(uint16_t(_resp.paddr));
                    break;
                default:
                    break;
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
                    switch (_resp.opcode)
                    {
                    case STU_SB:
                        _perfect_mem->sb(uint16_t(_resp.paddr), _resp.data);
                        break;
                    case STU_SH:
                        _perfect_mem->sh(uint16_t(_resp.paddr), _resp.data);
                        break;
                    case STU_SW:
                        _perfect_mem->sw(uint16_t(_resp.paddr), _resp.data);
                        break;
                    case STU_SD:
                        if(_resp.paddr < 0x10000){
                            _perfect_mem->sw(uint16_t(_resp.paddr), _resp.data & 0xffffffff);
                            _perfect_mem->sw(uint16_t(_resp.paddr + 4), (_resp.data >> 32) & 0xffffffff);
                        }
                        else{
                            _perfect_mem->sd(uint16_t(_resp.paddr), _resp.data);
                        }
                        break;
                    default:
                        break;
                    }
                }
                catch (const char* msg){
                    throw msg;
                }
            }
            if(_resp_comm_num % MEM_CHEKCPOINT == 0 && _resp_comm_num != 0){
                printf("=============\n%d cases done\n=============\n", _resp_comm_num);
            }
        }
        catch (const char* msg){
            throw msg;
        }
    }

    
}

bool Monitor::mem_check(){
    for(int i = 0; i < MEM_MAX_SIZE; i ++){
        if(_perfect_mem->check(i) == _real_mem->check(i)) continue;
        LOG << "mem check fail @ 0x" << std::hex << (i << 3) << std::endl
            << "correct mem is 0x" << std::hex << _perfect_mem->check(i) << std::endl
            << "real mem is 0x" << std:: hex << _real_mem->check(i) << std::endl;
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