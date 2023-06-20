# Entity: csr_unit 

- **File**: csr.v

## Ports

| Port name            | Direction | Type                             | Description |
| -------------------- | --------- | -------------------------------- | ----------- |
| clk                  | input     | wire                             |             |
| rst                  | input     | wire                             |             |
| current_mode_i       | input     | wire [1:0]                       |             |
| func3_i              | input     | wire [2:0]                       |             |
| csr_do_read_i        | input     | wire                             |             |
| csr_do_write_i       | input     | wire                             |             |
| rcu_csr_req_valid_i  | input     | wire                             |             |
| csr_rcu_resp_valid_o | output    | wire                             |             |
| is_csr_i             | input     | wire                             |             |
| prs1_data_i          | input     | wire [XLEN-1:0]                  |             |
| imm_i                | input     | wire [31:0]                      |             |
| prd_i                | input     | wire [PRF_INDEX_WIDTH-1:0]       |             |
| rob_index_i          | input     | wire [ROB_INDEX_WIDTH-1:0]       |             |
| csr_addr_i           | input     | wire [11:0]                      |             |
| csr_rdata_i          | input     | wire [XLEN-1:0]                  |             |
| csr_readable_i       | input     | wire                             |             |
| csr_writable_i       | input     | wire                             |             |
| csr_wrdata_o         | output    | [XLEN-1:0]                       |             |
| csr_wrb_data_o       | output    | wire [XLEN-1:0]                  |             |
| illegal_csr_o        | output    | wire                             |             |
| csr_exception_o      | output    | wire                             |             |
| csr_ecause_o         | output    | wire [EXCEPTION_CAUSE_WIDTH-1:0] |             |

## exception ctrl
* when illegally read or write a csr, csru will return a exception and ecause to rob
