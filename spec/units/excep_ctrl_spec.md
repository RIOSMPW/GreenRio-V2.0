# Entity: excep_ctrl 

- **File**: excep_ctrl.v
## Diagram

## Ports

| Port name          | Direction | Type           | Description |
| ------------------ | --------- | -------------- | ----------- |
| rob_commit_valid_i | input     |                |             |
| rob_cm_exp_pc_i    | input     | [PC_WIDTH-1:0] |             |
| rob_cm_mret_i      | input     |                |             |
| rob_cm_wfi_i       | input     |                |             |
| rob_cm_ecause_i    | input     | [3:0]          |             |
| rob_cm_exp_i       | input     |                |             |
| sip_i              | input     |                |  software interrupt           |
| tip_i              | input     |                |  timer interrupt           |
| eip_i              | input     |                |  external interrupt           |
| global_trapped_o   | output    |                |  exception ctrl signal           |
| global_mret_o      | output    |                |  exception ctrl signal           |
| global_sret_o      | output    |                |  exception ctrl signal           |
| global_wfi_o       | output    |                |  exception ctrl signal           |
| csr_retired_o      | output    |                |             |
| csr_ecp_o          | output    | [31:0]         |             |
| csr_ecause_o       | output    | [3:0]          |             |
| csr_interupt_o     | output    |                |             |
## Signals

| Name      | Type | Description |
| --------- | ---- | ----------- |
| exception | wire |             |
