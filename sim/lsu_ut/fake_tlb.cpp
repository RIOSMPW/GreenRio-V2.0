#ifndef _FAKE_TLB_CPP_
#define _FAKE_TLB_CPP_
#include "./fake_tlb.hpp"
#include <stdlib.h>
void FakeTLB::eval(){
    for(auto it = _delay_list->begin(); it != _delay_list->end(); ){
        if(it->delay == 0) {
            _tlb_hit_set->insert(it->ptag);
#ifdef LOG_ENABLE
                LOG << "\tt " << std::dec << TIME << ":tlb resp back.\t\t"
                    << " ptag: "  << std::hex << it->ptag
                    << std::endl;
#endif // LOG_ENABLE
            it = _delay_list->erase(it);
        }
        else{
            it->delay--;
            it ++;
        }
    }
    _resp = _resp_q;
    _valid = _valid_q;
    _pt = _pt_q;
    _resp_q = 0;
    _valid_q = 0;
    _pt_q = 0;
}

void FakeTLB::req(const bool& valid, const uint64_t& vtag){
    _valid_q = valid;
    _resp_q = _tlb_hit_set->find(vtag) != _tlb_hit_set->end();
    _pt_q = vtag;
    if(!_resp_q & valid){
        bool flag = false;
        for(auto it = _delay_list->begin(); it != _delay_list->end(); it ++){
            if(it->ptag != vtag) continue;
            flag = true;
            break;
        }
        if(!flag)
            _delay_list->push_back(DelaySlot(vtag, TLB_MISS_BASE_DELAY + rand() % TLB_MISS_BASE_DELAY));
    }
#ifdef LOG_ENABLE
    // if(valid && TIME % 10 == 0 && ){
    //     LOG << "t " << std::dec << TIME << ": tlb new req in." 
    //     << "\tvtag: " << std::hex << vtag
    //     << std::endl;
    // }
    if(valid && _resp_q && (TIME % 10 == 0)){
        LOG << "\tt " << std::dec << TIME << ": tlb new req in." 
        << "\tvtag: " << std::hex << vtag
        << std::endl;
    }
#endif // LOG_ENABLE     
}

bool FakeTLB::resp_vld(){
    return _valid;
}

bool FakeTLB::resp() {
    return _resp;
}

uint64_t FakeTLB::ptag(){
    return _pt;
}
#endif // _FAKE_TLB_CPP_
