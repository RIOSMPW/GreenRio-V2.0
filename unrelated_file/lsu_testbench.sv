// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
// Specify the module to load or on files.f
`include "lsu.v"
`timescale 1 ns / 100 ps

module lsu_testbench();

    `SVUT_SETUP

    clk;
    rstn;
    stall;
    valid_i;
    [ROB_INDEX_WIDTH - 1 : 0] ROB_index_i;
    [REG_ADDR_WIDTH - 1 : 0] rd_addr_i;
    [XLEN - 1 : 0] rs1_data_i;
    [XLEN - 1 : 0] rs2_data_i;
    [XLEN - 1 : 0] imm_i;
    opcode_i;
    [1:0] size_i;
    load_sign_i;
    req_valid_o;
    [VIRTUAL_ADDR_LEN - 1 : 0] req_addr_o;
    [XLEN - 1 : 0] req_data_o;
    req_ready_i;
    resp_valid_i;
    [XLEN - 1 : 0]resp_data_i;
    resp_ready_o;
    exception_valid_o;
    [4:0] exception_code_o;
    stall_o;
    [ROB_INDEX_WIDTH - 1 : 0] ROB_index_o;
    ls_done_o;
    load_data_valid_o;
    [XLEN - 1 : 0] load_data_o;
    [REG_ADDR_WIDTH - 1 : 0] rd_addr_o;

    lsu 
    dut 
    (
    .clk               (clk),
    .rstn              (rstn),
    .stall             (stall),
    .valid_i           (valid_i),
    .ROB_index_i       (ROB_index_i),
    .rd_addr_i         (rd_addr_i),
    .rs1_data_i        (rs1_data_i),
    .rs2_data_i        (rs2_data_i),
    .imm_i             (imm_i),
    .opcode_i          (opcode_i),
    .size_i            (size_i),
    .load_sign_i       (load_sign_i),
    .req_valid_o       (req_valid_o),
    .req_addr_o        (req_addr_o),
    .req_data_o        (req_data_o),
    .req_ready_i       (req_ready_i),
    .resp_valid_i      (resp_valid_i),
    .0]resp_data_i     (0]resp_data_i),
    .resp_ready_o      (resp_ready_o),
    .exception_valid_o (exception_valid_o),
    .exception_code_o  (exception_code_o),
    .stall_o           (stall_o),
    .ROB_index_o       (ROB_index_o),
    .ls_done_o         (ls_done_o),
    .load_data_valid_o (load_data_valid_o),
    .load_data_o       (load_data_o),
    .rd_addr_o         (rd_addr_o)
    );


    // To create a clock:
    // initial aclk = 0;
    // always #2 aclk = ~aclk;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("lsu_testbench.vcd");
    //     $dumpvars(0, lsu_testbench);
    // end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        // setup() runs when a test begins
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("TESTSUITE_NAME")

    //  Available macros:"
    //
    //    - `MSG("message"):       Print a raw white message
    //    - `INFO("message"):      Print a blue message with INFO: prefix
    //    - `SUCCESS("message"):   Print a green message if SUCCESS: prefix
    //    - `WARNING("message"):   Print an orange message with WARNING: prefix and increment warning counter
    //    - `CRITICAL("message"):  Print a purple message with CRITICAL: prefix and increment critical counter
    //    - `ERROR("message"):     Print a red message with ERROR: prefix and increment error counter
    //
    //    - `FAIL_IF(aSignal):                 Increment error counter if evaluaton is true
    //    - `FAIL_IF_NOT(aSignal):             Increment error coutner if evaluation is false
    //    - `FAIL_IF_EQUAL(aSignal, 23):       Increment error counter if evaluation is equal
    //    - `FAIL_IF_NOT_EQUAL(aSignal, 45):   Increment error counter if evaluation is not equal
    //    - `ASSERT(aSignal):                  Increment error counter if evaluation is not true
    //    - `ASSERT((aSignal == 0)):           Increment error counter if evaluation is not true
    //
    //  Available flag:
    //
    //    - `LAST_STATUS: tied to 1 is last macro did experience a failure, else tied to 0

    `UNIT_TEST("TESTCASE_NAME")

        // Describe here the testcase scenario
        //
        // Because SVUT uses long nested macros, it's possible
        // some local variable declaration leads to compilation issue.
        // You should declare your variables after the IOs declaration to avoid that.

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
