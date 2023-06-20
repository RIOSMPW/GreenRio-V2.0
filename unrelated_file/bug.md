# 各個UNIT接口沒有對上的情況：
1. hehe.v
    core_empty_u.icache_resp_ready_o 在l1icache上沒有对应  dcache2back_ready

2. func_wrb_valid

3. back2csr_wb_valid 成环

4. rob_cm_valid 成环

5. front2back_exception front2back_ecause问题

6.  
# 问题：
没有SPEC 接口命名太乱