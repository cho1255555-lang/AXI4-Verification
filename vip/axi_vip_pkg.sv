`ifndef AXI_PARMS_CFG
`define AXI_PARMS_CFG

`include "axi_defines.svh"

package axi_vip_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef bit [`AXI_ADDR_W-1:0] addr_t;
    typedef bit [`AXI_DATA_W-1:0] data_t;
    typedef bit [`AXI_DATA_W/8-1:0] strb_t;
    typedef bit [`AXI_ID_W-1:0] id_t;
    typedef bit [7:0] len_t;
    typedef bit [2:0] size_t;
    typedef bit [1:0] resp_t;
    typedef bit [1:0] user_t;
    typedef enum bit [1:0] {FIXED, INCR, WRAP, RESERVED} burst_e;
    typedef enum bit {AXI_READ, AXI_WRITE} dir_e;

    
    `include "axi_cfg.sv"
    `include "axi_base_item.sv"
    `include "axi_seq_lib.sv"
    `include "axi_sequencer.sv"
    `include "axi_driver.sv"
    `include "axi_monitor.sv"
    `include "axi_coverage.sv"
    `include "axi_agent.sv"
    `include "axi_scoreboard.sv"
    `include "axi_env.sv"
    `include "axi_base_test.sv"
    

endpackage
`endif 
