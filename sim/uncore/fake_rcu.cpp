#ifndef _FAKE_RCU_CPP_
#define _FAKE_RCU_CPP_
#include "./fake_rcu.hpp"
std::ofstream LOG;
uint64_t TIME;
bool FakeRCU::req_vld(){
    return _lsu_req_vld;
}

Req FakeRCU::req(){
   return _lsu_req; 
}

void FakeRCU::resp_vld(const bool& vld){
    _lsu_resp_vld = vld;
}

void FakeRCU::resp(const Req& cache_line){
    _lsu_resp = cache_line;
}

void FakeRCU::lsu_rdy(const bool& rdy){
    _lsu_rdy = rdy;
}

bool FakeRCU::rcu_rdy(){
    // printf("rcu_ready: %d\n", bool(_rcu->size() < RCU_MAX_SIZE));
    return _rcu->size() < RCU_MAX_SIZE;
}
bool FakeRCU::wakeup_vld(){
    return _wake_up_vld;
}
uint8_t FakeRCU::wakeup_rob_index(){
    return _wake_up_rob_index;
}

bool FakeRCU::commit_vld(){
    return _new_comm_vld;
}
Req FakeRCU::commit(){
    return _new_comm;
}
void FakeRCU::new_req_vld(const bool& vld){
    _new_req_vld = vld;
}
void FakeRCU::new_req(const Req& e){
    _new_req = e;
}
void FakeRCU::eval(){
    // handle old iss
    if(_lsu_rdy){
        _lsu_rdy = 0;
        if(_lsu_req_vld) { // handshake
            _lsu_req_vld = 0;
            for(auto it = _rcu->begin(); it != _rcu->end(); it ++){
                if(it->rob_index != _lsu_req.rob_index) continue;
                it->issued = 1;
#ifdef LOG_ENABLE
                LOG << "t " << std::dec << TIME << ":rcu req issue.\t\t"
                    << (it->load_or_store ? "st-" : "ld-") << std::dec << uint32_t(it->opcode) << "\t"
                    << " @ 0x" << std::hex  << it->paddr << "\t"
                    << " ROB index: " << std::dec << uint32_t(it->rob_index ) << "\t"
                    << " rd addr: " << std::dec << uint32_t(it->rd_addr) << "\t"
                    << " delay: " << std::dec << uint32_t(it->delay) << "\t"
                    << " is fenced: " << (it->is_fenced ? "true" : "false");
                if(it->load_or_store){
                    LOG << " data: " << std::hex << it->data;
                }
                LOG << std::endl;
#endif // LOG_ENABLE
                break;
            }
        }
    }

    // enque new req
    if(_new_req_vld && _rcu->size() < RCU_MAX_SIZE){
        _new_req_vld = 0;
        if(_rcu->size() != 0){
            _new_req.rob_index = (_rcu->back().rob_index + 1) % RCU_MAX_SIZE;
            if(_new_req.rob_index == 0) _new_req.rob_index ++;
        }
        else{
            _new_req.rob_index = 1;
        }
        _rcu->push_back(_new_req);
#ifdef LOG_ENABLE
        LOG << "t " << std::dec << TIME << ":rcu req enque.\t\t"
            << (_new_req.load_or_store ? "st-" : "ld-") << std::dec << uint32_t(_new_req.opcode) << "\t"
            << " @ 0x" << std::hex  << _new_req.paddr << "\t"
            << " ROB index: " << std::dec << uint32_t(_new_req.rob_index ) << "\t"
            << " rd addr: " << std::dec << uint32_t(_new_req.rd_addr) << "\t"
            << " delay: " << std::dec << uint32_t(_new_req.delay) << "\t"
            << " is fenced: " << (_new_req.is_fenced ? "true" : "false");
        if(_new_req.load_or_store){
            LOG << " data: " << std::hex << _new_req.data;
        }
        LOG << std::endl;
#endif // LOG_ENABLE
    }

//     // write back
//     if(_prf_wb_vld){
//         _prf_wb_vld = 0;
//         for(auto it = _rcu->begin(); it != _rcu->end(); it ++){
//             if(it->rd_addr != _prf_wb_rd_addr) continue;
//             it->data = _prf_wb_data;
// #ifdef LOG_ENABLE
//             LOG << "\tt " << std::dec << TIME << ":rcu wb.\t\t"
//                 << " @ 0x"  << std::hex << it->paddr 
//                 <<  "\t rob: "<< std::dec << uint32_t(it->rob_index);
//             if(it->load_or_store == 0)
//                 LOG << "\t data: " << std::hex << it->data;
//             LOG << std::endl;
// #endif // LOG_ENABLE
//             break;
//         }
//     }

    // handle resp
    if(_lsu_resp_vld){
        _lsu_resp_vld = 0;
        for(auto it = _rcu->begin(); it != _rcu->end(); it ++){
            if(it->rob_index != _lsu_resp.rob_index) continue;
            it->rd_addr = _lsu_resp.rd_addr;
            if(_lsu_resp.rd_addr != 0){
                it->data = _lsu_resp.data;
            }
            it->done = 1;
#ifdef LOG_ENABLE
            LOG << "\tt " << std::dec << TIME << ":rcu resp recieved.\t\t"
                << " @ 0x"  << std::hex << it->paddr 
                <<  "\t rob: "<< std::dec << uint32_t(it->rob_index)
                <<  "\t rd addr: "<< std::dec << uint32_t(it->rd_addr)
                <<  "\t data: "<< std::hex << uint64_t(it->data);
            LOG << std::endl;
#endif // LOG_ENABLE
            break;
        }
    }

    // wake_up
    _wake_up_vld = 0;
    for(auto it = _rcu->begin(); it != _rcu->end(); it ++){
        if(it->delay == 0){
            if(!_wake_up_vld && !it->awake){
                _wake_up_vld = 1;
                it->awake = 1;
                _wake_up_rob_index = it->rob_index;
                // printf("wake up\n");
#ifdef DEBUG_OUTPUT
                std::cout << "rcu wake up @ 0x"  << std::hex << it->paddr 
                        <<  "\t rob: "<< std::dec << uint32_t(_wake_up_rob_index)
                        << std::endl;
#endif // DEBUG_OUTPUT
#ifdef LOG_ENABLE
                if(it->load_or_store){
                    LOG << "\tt " << std::dec << TIME << ":rcu wakeup.\t\t"
                        << " @ 0x"  << std::hex << it->paddr 
                        <<  "\t rob: "<< std::dec << uint32_t(_wake_up_rob_index)
                        << std::endl;
                }
#endif // LOG_ENABLE
            }
        }
        else{
            if(it->issued == 1)
                it->delay --;
            // printf("delay: %d\n", it->delay);
        }
    }

    // issue
    if(!_lsu_req_vld){
        for(auto it = _rcu->begin(); it != _rcu->end(); it ++){
            if(it->issued == 1) continue;
            _lsu_req_vld = 1;
            _lsu_req = *it;
// #ifdef LOG_ENABLE
//             LOG << "\tt " << std::dec << TIME << ":rcu iss req.\t\t"
//             << std::hex << it->paddr 
//             << " wb -> " << std::dec << uint32_t(it->rd_addr) 
//             << std::endl;
// #endif // LOG_ENABLE
            break;
        }
    }
    // commit req
    _new_comm_vld = 0;
    if(_rcu->front().issued == 1 && _rcu->front().done == 1 && _rcu->front().awake == 1){
        _new_comm_vld = 1;
        _new_comm = _rcu->front();
        _rcu->pop_front();
#ifdef LOG_ENABLE
        LOG << "t " << std::dec << TIME << ":rcu req deque.\t\t"
            << "@ 0x" << std::hex  << _new_comm.paddr << "\t"
            << "ROB index: " << std::dec << uint32_t(_new_comm.rob_index)  << "\t";
        if(!_new_comm.load_or_store){
            LOG << "data: " << std::hex << _new_comm.data;
        }
        LOG << std::endl;
#endif // LOG_ENABLE
    }
}


#endif // _FAKE_RCU_CPP_
