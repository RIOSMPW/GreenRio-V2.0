# ALU

## Ports:
 name         |     width      |             description                |
| :----------------- | :------------- | :------------------------------------- |
| **GLOBAL**|
| clk | 1 | clk| 
|rstn | 1 | rstn|
|wfi| 1 | wfi |
| trap| 1 | trap|
| **CACUL** | 
| opr1_i | XLEN | oprand 1|
| opr2_i | XLEN | oprand 2|
| half_i | 1 | |
| alu_function_select_i   | 3 |  |
| function_modifier_i | 1 |  |  
| rob_index_i | ROB_INDEX_WIDTH | 
| prd_addr_i |  PHY_REG_ADDR_WIDTH | 
| rcu_fu_alu_req_valid_i | 1 | rcu is sending data to this alu | 
 **BTB/Gshare**|
| cmp_input_a_i | XLEN | |
|cmp_input_b_i | XLEN | |
| cmp_function_select   | 3 | funct3 |
| is_branch_i | 1 | is branch (include jump) |
| is_jump_i | 1   |  is jump|
| pc_i |   VIRTUAL_ADDR_LEN | current pc|
| next_pc_i | VIRTUAL_ADDR_LEN | pc_i + 4 | 
| is_jump_o | 1 | 
| is_branch | 1 | 
| pc_o | VIRTUAL_ADDR_LEN | directly from pc_i |
| next_pc_o |  VIRTUAL_ADDR_LEN | directly from next_pc_i |
| prd_addr_o | PHY_REG_ADDR_WIDTH | 
| rob_index | ROB_INDEX_WIDTH | 
| alu_result | XLEN | 
| cmp_result | | | 
| alu_resp_valid_o | 1 | alu resp valid