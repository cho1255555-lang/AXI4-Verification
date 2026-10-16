module tb_top;
    
    logic aclk, areset_n;

    axi_if vif (.aclk(aclk),
        .areset_n(areset_n));

    axi_slave u1 (.aclk(vif.aclk),
        .areset_n(vif.areset_n),
        .s_axi(vif.slave)
    );

    initial aclk = 0;
    always #5 aclk = ~aclk;

    
    initial begin
        areset_n = 1;
        vif.arvalid = 0;
        vif.awvalid = 0;
        vif.wvalid  = 0;
        vif.wlast   = 0;
        vif.rready  = 0;
        vif.bready  = 0;
      repeat(3) @(posedge aclk);
        areset_n =0;
      repeat(2) @(posedge aclk);
      	areset_n =1;
        $finish;
        
    end

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
    end
	
  
endmodule

    
    

