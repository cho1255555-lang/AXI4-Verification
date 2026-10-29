/*
class uvm_driver #(type REQ = uvm_sequence_item, type RSP = REQ) extends uvm_component;
  uvm_seq_item_pull_port #(REQ, RSP) seq_item_port;   
  REQ req;                                           
  RSP rsp;  
endclass
*/

class axi_driver extends uvm_driver #(axi_base_item);
    `uvm_component_utils(axi_driver)

    virtual axi_vif vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi_vif)::get(this,"","vif",vif))
            `uvm_fatal("NOVIF", "virtual interface not found")
    endfunction

    virtual task run_phase(uvm_phase phase); 
        
        sig_reset();                 
        wait(vif.areset_n); //reset
        @(vif.drv_cb);        
        forever begin
            seq_item_port.get_next_item(req);

            if(req.dir==AXI_WRITE) begin
                fork
                    aw_drive(req); //aw, w 사이엔 dependency가 없음
                    w_drive(req);
                join
                b_drive(req); //write 이후 b 채널 handshake
            end
            else begin
                ar_drive(req);
                r_drive(req);
            end
            seq_item_port.item_done();
        end
    endtask

    virtual task sig_reset();
        vif.drv_cb.arvalid <=0; //driver에서 dut로 drive할 signal들 reset
        vif.drv_cb.rready  <=0;
        vif.drv_cb.awvalid <=0;
        vif.drv_cb.wstrb   <=0;
        vif.drv_cb.wvalid  <=0;
        vif.drv_cb.wlast   <=0;
        vif.drv_cb.bready  <=0;    

    endtask
    
    virtual task aw_drive(axi_base_item req);
        repeat(req.aw_delay) @(vif.drv_cb);
        vif.drv_cb.awvalid <= 1'b1; //awvalid assert
        vif.drv_cb.awaddr  <= req.addr;
        vif.drv_cb.awlen   <= req.len;
        vif.drv_cb.awsize  <= req.size;
        vif.drv_cb.awburst <= req.burst;
        vif.drv_cb.awid    <= req.awid;
        do @(vif.drv_cb); while(vif.drv_cb.awready !== 1'b1); //handshake가 일어날 때까지 기다림
        vif.drv_cb.awvalid <= 1'b0;
    endtask

    virtual task w_drive(axi_base_item req);
        repeat(req.w_delay) @(vif.drv_cb);
        
        for(int i=0;i<req.len+1;i++) begin
            vif.drv_cb.wvalid <= 1'b1;
            vif.drv_cb.wdata  <= req.wdata[i];
            vif.drv_cb.wlast  <= (i==req.len)?1'b1:1'b0;
            vif.drv_cb.wstrb  <= req.wstrb[i];
            do @(vif.drv_cb); while(vif.drv_cb.wready !== 1'b1);
        end
        vif.drv_cb.wvalid <= 1'b0;
        vif.drv_cb.wlast  <= 1'b0; 
    endtask

    virtual task ar_drive(axi_base_item req);
        repeat(req.ar_delay) @(vif.drv_cb);
        vif.drv_cb.arvalid <= 1'b1;
        vif.drv_cb.araddr <= req.addr;
        vif.drv_cb.arlen <= req.len;
        vif.drv_cb.arsize <= req.size;
        vif.drv_cb.arburst <= req.burst;
        vif.drv_cb.arid <= req.arid;
        do @(vif.drv_cb); while(vif.drv_cb.arready !== 1'b1);
        vif.drv_cb.arvalid <= 1'b0;
    endtask

    virtual task r_drive(axi_base_item req); //r channel valid signal은 slave -> master 그래서 driver에선 ready 신호를 assert해야함
        repeat(req.r_delay) @(vif.drv_cb);
        for(int i=0;i<req.len+1;i++) begin
            vif.drv_cb.rready <= 1'b1;
            do @(vif.drv_cb); while(vif.drv_cb.rvalid !== 1'b1);
            //item에 rdata, rresp 담음
            req.rdata.push_back(vif.drv_cb.rdata);
            req.rresp.push_back(vif.drv_cb.rresp);
            vif.drv_cb.rready <= 1'b0;
        end   
    endtask
    
    virtual task b_drive(axi_base_item req); //b channel 또한 r channel과 동일하게 driver에서 ready 신호를 assert 해야함
        repeat(req.b_delay) @(vif.drv_cb);
        vif.drv_cb.bready <= 1'b1; 
        do @(vif.drv_cb); while(vif.drv_cb.bvalid !== 1'b1);
        req.bresp = vif.drv_cb.bresp;
        vif.drv_cb.bready <= 1'b0;
    endtask
    

endclass