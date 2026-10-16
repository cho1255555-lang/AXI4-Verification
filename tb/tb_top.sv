`timescale 1ns/1ps 

`include "axi_vip_pkg.sv"
`include "axi_protocol_checker"

module tb_top;

    import uvm_pkg::*;
    import axi_vip_pkg::*;

    logic aclk;
    logic areset_n;

    axi_vif vif (.aclk(aclk), .areset_n(areset_n));

    axi_slave u_dut(.aclk(aclk),.areset_n(areset_n),.s_axi(vif.slave));
    bind axi_slave axi_protocol_checker #(.MAX_WAIT(10)) u_chk (.*);

    
   
    initial  aclk = 0;
    always #5 aclk = ~aclk;

    initial begin
        areset_n = 0;
        repeat(4) @(posedge aclk);
        areset_n =1; 
    end
    
    initial begin
        uvm_config_db#(virtual axi_vif)::set(null, "*", "vif", vif);
        run_test("axi_rand_test");
    end

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0,tb_top);
    end

endmodule
        
        
        
        

    
    