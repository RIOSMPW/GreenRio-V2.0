#ifndef PERFECT_MEM_HPP
#define PERFECT_MEM_HPP
#include <assert.h>
#include <stdlib.h>
#include <cstdio>
#include <verilated.h>

// typedef unsigned long uint64_t;
// typedef unsigned uint32_t;
// typedef short uint16_t;
// typedef char uint8_t;

const uint32_t PERFECT_MEM_MAX_SIZE = 2 << (16 - 2); // 16 bits address 
const uint32_t DELAY = 3;
const uint32_t MSHR_DEPTH = 2;

struct req_entry{
    uint64_t data = 0;
    uint32_t lsq_index = 0;
    uint16_t addr = 0;
    bool valid = 0;

    uint16_t delay = 0;
};


class PerfectMem{
private:
    uint32_t* _mem; //32bit in a line, can be fetched easily
    bool _clk;

    bool _random_return = 0;
    req_entry* _req_que = nullptr; 
    bool _lsu_ready;

    uint16_t _addr = 0;
    uint32_t _lsq_index = 0;
    uint32_t _delay = 0;
    bool _lock = 0;
    bool _resp_valid = 0;
    uint32_t _wb_ack = 0;
    // bool _wb_ack = 0;
    // bool _wb_ack_ff = 0;
public: 
    PerfectMem(bool random){
        _mem = new uint32_t[PERFECT_MEM_MAX_SIZE];
        for(uint32_t i = 0; i < PERFECT_MEM_MAX_SIZE; i ++) _mem[i] = i << 2; // mem data == address in 32bits aligned
    
        _random_return = random;
        if(_random_return) _req_que = new req_entry[MSHR_DEPTH];
    }
    ~PerfectMem(){
        delete[] _mem;
        if(_random_return) delete _req_que;
    }

    void set_clk(bool s){_clk = s;}

    bool ready(){
        if(! _random_return)
            return !_lock;
        else{
            bool flag = 0;
            for(int i = 0; i < MSHR_DEPTH; i ++){
                if(!_req_que[i].valid) {
                    flag = 1;
                    break;
                }
                break;
            }
            return flag;
        }
    }

    void lsu_ready(bool r){_lsu_ready = r;}

    uint32_t new_entry(){
        if(!this->ready()) throw "read req come in when queue is not ready";
        for(uint32_t i = 0; i < MSHR_DEPTH; i ++){
            if(!_req_que[i].valid) {
                return i;
            }
        }
    }

    void handle_delay_conflict(const uint32_t& index){
        bool flag = true;
        while(flag){
            flag = false;
            for(int i = 0; i < MSHR_DEPTH; i ++){
                if(index == i) continue;
                if(_req_que[index].delay == _req_que[i].delay) flag = true;
            }
            if(flag) _req_que[index].delay += 1;
        }
    }

    void read64(const uint16_t& addr, const uint32_t& lsq_id){
        // printf("read addr: 0x%x, \n", addr);
        if(addr % 8 != 0){
            printf("addr:%x misaligned in read\n", addr);
            throw "addr misaligned";
        }
        if(!_random_return){
            _addr = addr;
            _delay = DELAY;
            _lsq_index = lsq_id;
            _lock = 1;
        }
        else{
            // printf("mem enque:%x\n", addr);
            uint32_t index = this->new_entry();
            _req_que[index].valid = 1;
            _req_que[index].addr = addr;
            _req_que[index].lsq_index = lsq_id;
            _req_que[index].data = peek64(addr);
            _req_que[index].delay = 1 + random() % DELAY;
            this->handle_delay_conflict(index);
        }
        
    }
    void read32(const uint16_t& addr, const uint32_t& lsq_id){
        // printf("read addr: 0x%x, \n", addr);
        if(addr % 4 != 0){
            printf("addr:%x misaligned in read32\n", addr);
            throw "addr misaligned";
        }
        if(!_random_return){
            _addr = addr;
            _delay = DELAY;
            _lsq_index = lsq_id;
            _lock = 1;
        }
        else{
            uint32_t index = this->new_entry();
            _req_que[index].valid = 1;
            _req_que[index].addr = addr;
            _req_que[index].lsq_index = lsq_id;
            _req_que[index].data = peek32(addr);
            _req_que[index].delay = 1 + random() % DELAY;
            this->handle_delay_conflict(index);
        }
    }
    void read16(const uint16_t& addr, const uint32_t& lsq_id){
        // printf("read addr: 0x%x, \n", addr);
        if(addr % 2 != 0){
            printf("addr:%x misaligned in read32\n", addr);
            throw "addr misaligned";
        }
        if(!_random_return){
            _addr = addr;
            _delay = DELAY;
            _lsq_index = lsq_id;
            _lock = 1;
        }
        else{
            uint32_t index = this->new_entry();
            _req_que[index].valid = 1;
            _req_que[index].addr = addr;
            _req_que[index].lsq_index = lsq_id;
            _req_que[index].data = peek16(addr);
            _req_que[index].delay = 1 + random() % DELAY;
            this->handle_delay_conflict(index);
        }
        
    }
    void read8(const uint16_t& addr, const uint32_t& lsq_id){
        // printf("read addr: 0x%x, \n", addr);
        if(!_random_return){
            _addr = addr;
            _delay = DELAY;
            _lsq_index = lsq_id;
            _lock = 1;
        }
        else{
            uint32_t index = this->new_entry();
            _req_que[index].valid = 1;
            _req_que[index].addr = addr;
            _req_que[index].lsq_index = lsq_id;
            _req_que[index].data = peek8(addr);
            _req_que[index].delay = 1 + random() % DELAY;
            this->handle_delay_conflict(index);
        }
    }

    void write64(const uint16_t& addr, const uint64_t& data){
        // printf("write addr: 0x%x, \n", addr);
        if(addr % 8 != 0){
            printf("addr:%x misaligned in write\n", addr);
            throw "addr misaligned";
        }
        _mem[(addr >> 2) + 1] = uint32_t(data >> 32);
        _mem[(addr >> 2)] = uint32_t(data);
        if(_wb_ack == 0) _wb_ack = 1;
    }
    void write32(const uint16_t& addr, const uint32_t& data){
        // printf("write32 @ 0x%x: %x, \n", addr, uint32_t(data));
        if(addr % 4 != 0){
            printf("addr:%x misaligned in write32\n", addr);
            throw "addr misaligned";
        }
        _mem[(addr >> 2)] = uint32_t(data);
        if(_wb_ack == 0) _wb_ack = 1;
    }
    void write16(const uint16_t& addr, const uint16_t& data){
        // printf("write32 @ 0x%x: %x, \n", addr, uint32_t(data));
        if(addr % 2 != 0){
            printf("addr:%x misaligned in write32\n", addr);
            throw "addr misaligned";
        }
        
        if(addr % 4 == 0){ // lower
            // printf("write16 lower @ 0x%x: origin: %x, %x -> %x, \n", addr, data, uint32_t(_mem[(addr >> 2)]), 
            //     uint32_t(data) + (_mem[(addr >> 2)] & 0xffff0000));
            _mem[(addr >> 2)] = uint32_t(data) + (_mem[(addr >> 2)] & 0xffff0000);
        }
        else{ //upper
            // printf("write16 upper @ 0x%x: origin: %x, %x -> %x, \n", addr, data, uint32_t(_mem[(addr >> 2)]), 
            //     (uint32_t(data) << 16) + (_mem[(addr >> 2)] & 0x0000ffff));
            _mem[(addr >> 2)] = (uint32_t(data) << 16) + (_mem[(addr >> 2)] & 0x0000ffff);
        }
        
        if(_wb_ack == 0) _wb_ack = 1;
    }
    void write8(const uint16_t& addr, const uint8_t& data){
        uint32_t mask = 0xffffffff ^ (0xff << ((addr % 4) * 8));
        // printf("write8 @ 0x%x: origin: %x, %x -> %x, \n", addr, data, uint32_t(_mem[(addr >> 2)]), 
        //     (uint32_t(data) << ((addr % 4) * 8)) + (_mem[(addr >> 2)] & mask));
        _mem[(addr >> 2)] = (uint32_t(data) << ((addr % 4) * 8)) + (_mem[(addr >> 2)] & mask) ;
        if(_wb_ack == 0) _wb_ack = 1;
    }

    uint64_t resp(){
        if(!_random_return){
            return (uint64_t(_mem[(_addr >> 2) + 1]) << 32) + uint64_t(_mem[(_addr >> 2)]);
        }
        else{
            for(int i = 0; i < MSHR_DEPTH; i ++)
                if(this->_req_que[i].delay == 0 && this->_req_que[i].valid) 
                    return uint64_t(this->_req_que[i].data);
            return 0;
        }
    }
    uint32_t resp_lsq_index(){
        if(!_random_return){
            return _lsq_index;
        }
        else{
            for(int i = 0; i < MSHR_DEPTH; i ++)
                if(this->_req_que[i].delay == 0 && this->_req_que[i].valid) 
                    return uint32_t(this->_req_que[i].lsq_index);
            return 0;
        }
        
    }
    uint32_t resp32(){
        if(!_random_return){
            if(_delay == 0) return _mem[_addr>>2];
            else return 0;
        }
        else{
            for(int i = 0; i < MSHR_DEPTH; i ++)
                if(this->_req_que[i].delay == 0 && this->_req_que[i].valid) 
                    return uint32_t(this->_req_que[i].data);
            return 0;
        }
        
    }
    bool resp_valid(){
        if(!_random_return){
            return _resp_valid;
        }
        else{
            for(int i = 0; i < MSHR_DEPTH; i ++)
                if(this->_req_que[i].delay == 0 && this->_req_que[i].valid) 
                    return 1;
            return 0;
        }   
        
    }
    bool wb_ack(){
        return _wb_ack == 2;
    }
    void eval(){
        // if(_resp_valid) _resp_valid = 0;
        if(!_random_return){
            if(_clk){
                if(_resp_valid){
                    _lock = 0;
                    _resp_valid = 0;
                }
                if(_wb_ack != 0){
                    // printf("_wb_ack:%x\n", _wb_ack);
                    // _wb_ack = 0;
                    _wb_ack = _wb_ack < 2 ? _wb_ack + 1 : 0;

                }
                if(_delay == 0 && _lock){
                    _resp_valid = 1;
                }
                if(_delay > 0) _delay --;
            }
        }
        else{
            for(int i = 0; i < MSHR_DEPTH; i ++){
                if(_lsu_ready && _req_que[i].valid && _req_que[i].delay == 0) {
                    _req_que[i].valid = 0;
                    break;
                }
            }
            for(int i = 0; i < MSHR_DEPTH; i ++){
                if(!_req_que[i].valid) continue;
                if( _req_que[i].delay == 0) throw "no entry should be both delay == 0 and valid when eval";
                _req_que[i].delay --;
            }
        }
        
    }

    uint64_t peek64(const uint16_t& addr){
        if(addr % 8 != 0){
            printf("addr:%x misaligned in peek64\n", addr);
            throw "addr misaligned";
        }
        // return 0;
        return (uint64_t(_mem[(addr >> 2) + 1]) << 32) + uint64_t(_mem[(addr >> 2)]);
    }
    uint32_t peek32(const uint16_t& addr){
        if(addr % 4 != 0){
            printf("addr:%x misaligned in peek32\n", addr);
            throw "addr misaligned";
        }
        return uint32_t(_mem[addr >> 2]);
    }
    uint16_t peek16(const uint16_t& addr){
        if(addr % 2 != 0){
            printf("addr:%x misaligned in peek16\n", addr);
            throw "addr misaligned";
        }
        if(addr % 4 == 0){
            return uint16_t(_mem[addr >> 2]);
        }
        else{
            return uint16_t(_mem[addr >> 2] >> 16);
        }
    }
    uint8_t peek8(const uint16_t& addr){
        // printf("%x -> %x\n", _mem[addr >> 2], uint8_t(_mem[addr >> 2] >> (8 * (addr % 4))));
        return uint8_t(_mem[addr >> 2] >> (8 * (addr % 4)));
    }
    uint32_t get(const uint32_t index){
        return _mem[index];
    }

    bool final_check(PerfectMem* other){
        for(int i = 0; i < PERFECT_MEM_MAX_SIZE; i ++) {
            // printf("%x @ %x\n", other->get(i), i << 2);
            if(_mem[i] != other->get(i)) {
                printf("final mem check wrong @ %x, %x - %x\n", i << 2, _mem[i], other->get(i));
                return false;
            }
        }
        return true;
    }
};

struct request{
    uint64_t data;
    uint32_t address; // 16bits addr
    uint8_t size;
    bool sign;
    bool opcode;
    request(const uint64_t& d, const uint32_t& a, const uint8_t& s, const bool& sgn, const bool& o):
        data(d), address(a), size(s), sign(sgn), opcode(o){}
};

#endif //PERFECT_MEM_HPP