`timescale 1ns/1ps 

`include "axi_vip_pkg.sv"
`include "axi_vif.sv"
`include "axi_protocol_checker.sv"

module tb_top;


    import uvm_pkg::*;
    import axi_vip_pkg::*;

    logic aclk;
    logic areset_n;

    axi_vif vif (.aclk(aclk), .areset_n(areset_n));

    axi_ram #(
        .DATA_WIDTH(`AXI_DATA_W),
        .ADDR_WIDTH(`AXI_ADDR_W),
        .ID_WIDTH($bits(id_t)),
        .PIPELINE_OUTPUT(0)
    ) U_DUT (
        .clk            (aclk),
        .rst            (~areset_n),        // DUT는 active high reset
 
        // AW
        .s_axi_awid     (0), // 나중에 ID 검증 필요할 때 씀
        .s_axi_awaddr   (vif.awaddr),
        .s_axi_awlen    (vif.awlen),
        .s_axi_awsize   (vif.awsize),
        .s_axi_awburst  (vif.awburst),
        .s_axi_awlock   (1'b0),
        .s_axi_awcache  (4'b0),
        .s_axi_awprot   (3'b0),
        .s_axi_awvalid  (vif.awvalid),
        .s_axi_awready  (vif.awready),
        // W
        .s_axi_wdata    (vif.wdata),
        .s_axi_wstrb    (vif.wstrb),
        .s_axi_wlast    (vif.wlast),
        .s_axi_wvalid   (vif.wvalid),
        .s_axi_wready   (vif.wready),
        // B
        .s_axi_bid      (vif.bid),
        .s_axi_bresp    (vif.bresp),        // resp_t가 enum이면 여기서 에러 가능 → 중간 wire + 캐스팅
        .s_axi_bvalid   (vif.bvalid),
        .s_axi_bready   (vif.bready),
        // AR
        .s_axi_arid     ('0),
        .s_axi_araddr   (vif.araddr),
        .s_axi_arlen    (vif.arlen),
        .s_axi_arsize   (vif.arsize),
        .s_axi_arburst  (vif.arburst),
        .s_axi_arlock   (1'b0),
        .s_axi_arcache  (4'b0),
        .s_axi_arprot   (3'b0),
        .s_axi_arvalid  (vif.arvalid),
        .s_axi_arready  (vif.arready),
        // R
        .s_axi_rid      (vif.rid),
        .s_axi_rdata    (vif.rdata),
        .s_axi_rresp    (vif.rresp),
        .s_axi_rlast    (vif.rlast),
        .s_axi_rvalid   (vif.rvalid),
        .s_axi_rready   (vif.rready)
    );

    assign vif.buser = '0; //user 신호 wire로 0처리 dut와 검증하려는 feature에 따라 설정하면 됨
    assign vif.ruser = '0;

//    axi_slave u_dut(.aclk(aclk),.areset_n(areset_n),.s_axi(vif.slave)); 
    axi_protocol_checker #(.MAX_WAIT(100)) u_chk (
    .aclk     (aclk),
    .areset_n (areset_n),
    .s_axi    (vif)
    );

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
        
        
        
        

    
    