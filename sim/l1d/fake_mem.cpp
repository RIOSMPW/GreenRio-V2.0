#ifndef _FAKE_MEM_CPP_
#define _FAKE_MEM_CPP_
#include "./fake_mem.hpp"

uint8_t FakeMemory::get_byte(const uint16_t& paddr){
    return _mem[paddr];
}
void FakeMemory::set_byte(const uint16_t&  paddr, const uint8_t& data){
    _mem[paddr] = data;
}

uint8_t FakeMemory::pagetable_get_byte(const uint16_t&  paddr){
    return _pagetable[paddr];
}
void FakeMemory::pagetable_set_byte(const uint16_t&  paddr, const uint8_t& data){
    _pagetable[paddr] = data;
}

void FakeMemory::ar_vld(const bool& vld){
    _ar_vld = vld;
}
void FakeMemory::ar_req(const axi_ar_req& ar){
    _ar_req = ar;
}
void FakeMemory::aw_vld(const bool& vld){
    _aw_vld = vld;
}
void FakeMemory::aw_req(const axi_aw_req& aw){
    _aw_req = aw;
}
void FakeMemory::w_vld(const bool& vld){
    _w_vld = vld;
}
void FakeMemory::w_req(const axi_w_req& w){
    _w_req = w;
}
void FakeMemory::b_rdy(const bool & rdy){
    _b_rdy = rdy;
}
void FakeMemory::r_rdy(const bool & rdy){
    _r_rdy = rdy;
}
bool FakeMemory::r_vld() const{
    return _r_vld;
}
axi_r_resp FakeMemory::r_resp() const{
    return _r_resp;
}
bool FakeMemory::b_vld() const{
    return _b_vld;
}
axi_b_resp FakeMemory::b_resp() const{
    return _b_resp;
}
uint64_t FakeMemory::visit_time() const{
    return _visit_time;
}
void FakeMemory::eval() throw(const char* ){
    try{
        //printf("mem eval in\n");
        // enque req
        //printf("1\n");
        if(_aw_vld){
            mem_req req;
            req.aw_vld = 1;
            req.aw = _aw_req;
            req.delay = MEM_BASE_DELAY + random() %  MEM_MAX_DELAY;
            _req_wait_q->push_back(req);
#ifdef LOG_ENABLE
            LOG << "\t\t\tt " << std::dec << TIME << ":axi mem aw req recieved.\t\t"
                << "@ 0x" << std::hex  << req.aw.awaddr << "\t";
            LOG << std::endl;
#endif // LOG_ENABLE
        }
        //printf("2\n");
        if(_ar_vld){
            mem_req req;
            req.ar_vld = 1;
            req.ar = _ar_req;
            req.delay = MEM_BASE_DELAY + random() %  MEM_MAX_DELAY;
            _req_wait_q->push_back(req);
            // std::cout << "ar req @ " << std::hex << req.ar.araddr << std::endl;
#ifdef LOG_ENABLE
            LOG << "\t\t\tt " << std::dec << TIME << ":axi mem ar req recieved.\t\t"
                << "arid: " << std::dec << req.ar.arid << "\t"
                << "@ 0x" << std::hex  << req.ar.araddr << "\t";
            LOG << std::endl;
#endif // LOG_ENABLE
        }
        //printf("3\n");
        if(_w_vld){
            bool flag = 0;
#ifdef LOG_ENABLE
                LOG << "\t\t\tt " << std::dec << TIME << ":axi mem w req recieved.\t\t"
                    << "data : " << std::hex  << _w_req.wdata << "\t";
                LOG << std::endl;
#endif // LOG_ENABLE
            for(auto it = _req_wait_q->begin(); it != _req_wait_q->end(); it ++){
                if(it->aw_vld && (it->w_vld_num < 8)){
                    flag = 1;
                    it->w[it->w_vld_num] = _w_req;
                    it->w_vld_num  ++;
                    break;
                }
            }
            if(!flag){
                throw "w vld while no aw is arrived first";
            }
        }
        
        //printf("4\n");
        // count down delay
        for(auto it = _req_wait_q->begin(); it != _req_wait_q->end(); it ++){
            if(it->delay > 0){
                it->delay --;
            }
        }

        //printf("5\n");
        // move req from wait queue
        while(_req_wait_q->front().delay == 0 && (_req_wait_q->front().ar_vld || (_req_wait_q->front().aw_vld && _req_wait_q->front().w_vld_num == 8))){
            _req_q->push_back(_req_wait_q->front());
            _req_wait_q->pop_front();
        }

        //printf("6\n");
        // handle req
        while(_req_q->size() > 0){
            if((_req_q->front().aw_vld && _req_q->front().w_vld_num == 8) || (_req_q->front().ar_vld)){
                //printf("6.1\n");
                mem_req req = _req_q->front();
                _req_q->pop_front();

                if(req.ar_vld){
                    // std::stringstream ss;
                    // std::cout << "ar req @ " << std::hex << req.ar.araddr << std::endl;
                    for(int i = 0; i < BURST_NUM; i ++){
                        mem_resp resp;
                        //printf("6.2.1\n");
                        uint64_t data = 0;
                        for(int j = 0; j < BURST_SIZE/8; j ++){
                            //printf("6.2.2\n");
                            // printf("ar.araddr:%lx\n", req.ar.araddr);
                            if((DATA_PADDR_BASE <= req.ar.araddr) && (req.ar.araddr < DATA_PADDR_UPPER)){
                                data += uint64_t(_mem[uint16_t(req.ar.araddr + i * 8 + j)]) << (j * 8);
                            }
                            else if ((PAGETABLE_PADDR_BASE <= req.ar.araddr) && (req.ar.araddr < PAGETABLE_PADDR_UPPER)){
                                data += uint64_t(_pagetable[uint16_t(req.ar.araddr + i * 8 + j)]) << (j * 8);
                            }
                            else{
                                // printf(msg.c_str());
                                // if(req.aw_vld)
                                //     printf("aw vld too\n");
                                std::cout << "invalid read access to memory: " << std::hex << req.ar.araddr << std::endl;
                                throw "invalid read access to memory";
                            }
                        }
                        //printf("6.2.3\n");
                        resp.r.rid = req.ar.arid;
                        //printf("6.2.4\n");
                        resp.r.rdata = data;
                        if(i == BURST_NUM - 1)
                            resp.r.rlast = 1;
                        resp.r_vld = 1;

                        _resp_q->push_back(resp);
                        //printf("6.2.5\n");
                    }
                }
                else{
                    //printf("6.3\n");
                    mem_resp resp;
                    for(int i = 0; i < BURST_NUM; i ++){
                        uint64_t data = 0;
                        for(int j = 0; j < BURST_SIZE/8; j ++){
                            if(DATA_PADDR_BASE <= req.aw.awaddr && req.aw.awaddr < DATA_PADDR_UPPER){
                                // printf("1\n");
                                _mem[uint16_t(req.aw.awaddr + i * 8 + j)] = uint8_t(req.w[i].wdata >> (j * 8));
                                // printf("2\n");
                            }
                            else{
                                std::string msg = "invalid write access to memory";
                                // printf(msg.c_str());
                                throw "invalid write access to memory";
                            }
                        }
                    }
#ifdef LOG_ENABLE
                        LOG << "\t\t\tt " << std::dec << TIME << ":axi mem w wb.\t\t";
                        LOG << "@ :" << std::hex << req.aw.awaddr;
                        LOG << "data:";
                        for(uint32_t i = 0; i < BURST_NUM; i ++)
                            LOG << std::hex << req.w[BURST_NUM - i - 1].wdata << " ";
                        LOG << std::endl;
#endif // LOG_ENABLE
                    resp.b_vld = 1;
                    resp.b.bid = req.aw.awid;
                    _resp_q->push_back(resp);
                }
                //printf("6.4\n");
            }
        }

        //printf("7\n");
        // sent resp
        _b_vld = 0;
        _r_vld = 0;
        if(_resp_q->size() > 0){
            
            if(_resp_q->front().b_vld){
                _b_vld = 1;
                _b_resp = _resp_q->front().b;
                if(_b_rdy)
                    _resp_q->pop_front();
            }
            else if(_resp_q->front().r_vld){
                _r_vld = 1;
                _r_resp = _resp_q->front().r;
                if(_r_rdy){
                    _resp_q->pop_front();
#ifdef LOG_ENABLE
                    LOG << "\t\t\tt " << std::dec << TIME << ":axi mem r resp send ";
                    LOG << "data: " << std::hex  << uint32_t(_r_resp.rdata >> 32) <<  " " << uint32_t(_r_resp.rdata) << " \t";
                    LOG << "rid: " << std::dec  << _r_resp.rid << "\t";
                    LOG << "rlast: " << std::dec  << _r_resp.rlast << "\t";
                    LOG << std::endl;
#endif // LOG_ENABLE
                }
            }
        }
        //printf("mem eval out\n");
    }
    catch(const char* msg){
        // printf(msg);
        throw msg;
    }
}
#endif // _FAKE_MEM_CPP_