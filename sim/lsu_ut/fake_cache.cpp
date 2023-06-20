#ifndef _FAKE_CACHE_CPP_
#define _FAKE_CACHE_CPP_
#include "./fake_cache.hpp"
bool FakeL1DCache::l1d_req_vld() const{
    return _l1d_req_vld;
}
bool FakeL1DCache::l1d_req_is_fenced() const{
    return _l1d_req_is_fenced;
}
uint16_t FakeL1DCache::l1d_req_rob_index() const{
    return _l1d_req_rob_index;
}
void FakeL1DCache::kill_req(const bool& kill){
    _kill_req = kill;
}
bool FakeL1DCache::ld_resp_vld(){
    return _ld_resp_vld;
}
CacheLine FakeL1DCache::ld_resp(){
    return _ld_resp;
}
bool FakeL1DCache::st_resp_vld(){
    return _st_resp_vld;
}
CacheLine FakeL1DCache::st_resp(){
    return _st_resp;
}
bool FakeL1DCache::ready(){
    return _cache_line_list->size() < MAX_CACHE_SIZE;
}
void FakeL1DCache::req_vld(const bool& vld){
    _req_vld = vld;
}

void FakeL1DCache::dtlb_resp_vld(const bool& dtlb_vld){
    _dtlb_resp_vld = dtlb_vld;
}
void FakeL1DCache::dtlb_resp(const bool& dtlb_hit){
    _dtlb_resp_hit = dtlb_hit;
}
void FakeL1DCache::req(const uint64_t& vi, const uint64_t& vo, const uint64_t& pt, const uint64_t& pa, const uint64_t& d, const uint8_t& ri, 
        const uint8_t& rd, const uint16_t& de, const bool & fence, const bool& ls, const uint8_t& op){
    uint64_t paddr = pa;
    if(!ls)
        paddr = vo + (vi << ADDR_OFFSET_LEN) + (pt << (ADDR_OFFSET_LEN + ADDR_INDEX_LEN));
    uint16_t delay;
    if(_cache_hit_set->find(pt) != _cache_hit_set->end()){// hit
        delay = CACHE_HIT_BASE_DELAY;
    }
    else{
        delay = CACHE_MISS_BASE_DELAY + rand() % CACHE_MISS_MAX_DELAY;
        while(_cache_delay_set->count(delay) == 1){   
            delay++;
        }
    }

    
    _req = CacheLine(paddr, d, ri, rd, delay, fence, ls, op);
    // std::cout << "new req in @ 0x" << std::hex << _req.paddr 
    //             << " data: 0x" << std::hex << _req.data
    //             << std::endl;
}
void FakeL1DCache::eval(){
    // 
    _ld_resp_vld = 0;
    _st_resp_vld = 0;
    _l1d_req_vld = 0;
    // req in and not killed, execute it
    if (_hsk_q & ~_kill_req){ 
        if(_cache_line_list->back().load_or_store){
            uint64_t paddr = _cache_line_list->back().paddr;
            uint64_t data = _cache_line_list->back().data;
            switch (_cache_line_list->back().opcode)
            {
            case STU_SB:
                _real_mem->sb(uint16_t(paddr & 0xffff), data);
                break;
            case STU_SH:
                _real_mem->sh(uint16_t(paddr & 0xffff), data);
                break;
            case STU_SW:

                _real_mem->sw(uint16_t(paddr & 0xffff), data);
                break;
            case STU_SD:
                _real_mem->sd(uint16_t(paddr & 0xffff), data);
                break;
            default:
                break;
            }
            _st_resp_vld = 1;
            _st_resp = _cache_line_list->back();
#ifdef LOG_ENABLE
                LOG << "t " << std::dec << TIME << " cache new st resp out " 
                << (_st_resp.load_or_store ? "st-" : "ld-") << std::dec << uint32_t(_st_resp.opcode) << "\t"
                << " @ 0x" << std::hex << _st_resp.paddr;
                LOG << std::endl;
#endif // LOG_ENABLE         
        }
        else{
            try{
                switch (_cache_line_list->back().opcode)
                {
                case LDU_LB:
                    _cache_line_list->back().data = _real_mem->lb(uint16_t(_cache_line_list->back().paddr));
                    break;
                case LDU_LH:
                    _cache_line_list->back().data = _real_mem->lh(uint16_t(_cache_line_list->back().paddr));
                    break;
                case LDU_LW:
                    _cache_line_list->back().data = _real_mem->lw(uint16_t(_cache_line_list->back().paddr));
                    break;
                case LDU_LD:
                    _cache_line_list->back().data = _real_mem->ld(uint16_t(_cache_line_list->back().paddr));
                    break;
                case LDU_LBU:
                    _cache_line_list->back().data = _real_mem->lbu(uint16_t(_cache_line_list->back().paddr));
                    break;
                case LDU_LHU:
                    _cache_line_list->back().data = _real_mem->lhu(uint16_t(_cache_line_list->back().paddr));
                    break;
                case LDU_LWU:
                    _cache_line_list->back().data = _real_mem->lwu(uint16_t(_cache_line_list->back().paddr));
                    break;
                default:
                    break;
                }
            }
            catch (const char* msg){
                throw msg;
            }

        }
        _l1d_req_vld = 1;
        _l1d_req_is_fenced = _cache_line_list->back().is_fenced;
        _l1d_req_rob_index = _cache_line_list->back().rob_index;
#ifdef LOG_ENABLE
        LOG << "\tt " << std::dec << TIME << ": cache new req in\t" 
        << (_cache_line_list->back().load_or_store ? "st-" : "ld-") << std::dec << uint32_t(_cache_line_list->back().opcode) << "\t"
        << "\t@ 0x" << std::hex << _cache_line_list->back().paddr
        << "\tis fenced: " << (_cache_line_list->back().is_fenced ? "true" : "false")
        << "\tROB Index: " << std::dec << uint64_t(_cache_line_list->back().rob_index)
        << "\trd addr: " << std::dec << uint64_t(_cache_line_list->back().rd_addr);
        if(_cache_line_list->back().load_or_store){
            LOG << "\tdata: " << std::hex << _cache_line_list->back().data;
        }
        LOG << std::endl;
#endif // LOG_ENABLE     
#ifdef DEBUG_OUTPUT
        std::cout << "cache new req in @ 0x" << std::hex << _cache_line_list->back().paddr 
                << " data: 0x" << std::hex << _cache_line_list->back().data
                << std::endl;
#endif // DEBUG_OUTPUT
    }
    // kill the last req
    else if(_kill_req & _hsk_q){
// #ifdef LOG_ENABLE
//         LOG << "\tt " << std::dec << TIME << ": cache kill\t" 
//          << std::endl;
// #endif // LOG_ENABLE     
        // printf("kill\n");
        _kill_req = 0;
        _cache_line_list->pop_back();
    }

    _kill_req = 0;
    // add new req
    bool hsk = _req_vld && _cache_line_list->size() < MAX_CACHE_SIZE;
    
    _hsk_q = hsk;
    if(hsk){
        // printf("hand shake\n");
        _req_vld = 0;
        _cache_line_list->push_back(_req);
        _cache_delay_set->insert(_req.delay);
    }

    // update cachelines
    auto it = _cache_line_list->begin();
    it != _cache_line_list->end();
    uint32_t d = it->delay;
    for(auto it = _cache_line_list->begin(); it != _cache_line_list->end(); ){
        if(it->delay == 0) {
            if(_ld_resp_vld){
                LOG << "t " << std::dec << TIME << "\tld resp: " 
                << (_ld_resp.load_or_store ? "st-" : "ld-") << std::dec << uint32_t(_ld_resp.opcode) << "\t"
                << " @ 0x" << std::hex << _ld_resp.paddr
                <<  "\t rd addr: "<< std::dec << uint32_t(_ld_resp.rd_addr)
                <<  "\t data: "<< std::hex << uint64_t(_ld_resp.data);
                LOG << std::endl; 
                LOG << "t " << std::dec << TIME << "\tanother line delay == 0: " 
                << (it->load_or_store ? "st-" : "ld-") << std::dec << uint32_t(it->opcode) << "\t"
                << " @ 0x" << std::hex << it->paddr
                <<  "\t rd addr: "<< std::dec << uint32_t(it->rd_addr)
                <<  "\t data: "<< std::hex << uint64_t(it->data);
                LOG << std::endl; 
                throw "l1d has multi resp in a tik";
            }
            if(it->load_or_store == 0){
                _ld_resp_vld = 1; 
                _ld_resp = *it;
#ifdef LOG_ENABLE
                LOG << "t " << std::dec << TIME << " cache new ld resp out " 
                << (_ld_resp.load_or_store ? "st-" : "ld-") << std::dec << uint32_t(_ld_resp.opcode) << "\t"
                << " @ 0x" << std::hex << _ld_resp.paddr
                <<  "\t rd addr: "<< std::dec << uint32_t(_ld_resp.rd_addr)
                <<  "\t data: "<< std::hex << uint64_t(_ld_resp.data);
                LOG << std::endl;
#endif // LOG_ENABLE                
#ifdef DEBUG_OUTPUT
                std::cout << "cache new resp out @ 0x" << std::hex << _resp.paddr 
                << " data: 0x" << std::hex << _resp.data 
                << " wb -> " << std::dec << uint32_t(_resp.rd_addr)
                << std::endl;
#endif // DEBUG_OUTPUT
            }   
            _cache_hit_set->insert(it->paddr); // RAR can not hit. Still correct, no worry.
            it = _cache_line_list->erase(it);

        }
        else{
            if(it->delay != 0)
                it->delay --;
            it ++;
        }
    }

    // renew delay heap

    _cache_delay_set->clear();
    for(auto it = _cache_line_list->begin(); it != _cache_line_list->end(); it ++){
        // 
        _cache_delay_set->insert(it->delay);
    }
    // 
}
#endif // _FAKE_CACHE_CPP_