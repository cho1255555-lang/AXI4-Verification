class axi_err_driver extends axi_driver;
    `uvm_component_utils(axi_err_driver)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        sig_reset();
        wait(vif.areset_n);
        @(vif.drv_cb);
        forever begin
            seq_item_port.get_next_item(req);
            if(req.err_type==ERR_VALID_DROP) begin
                if(req.dir==AXI_WRITE) begin
                    fork 
                        aw_valid_err(req);
                        w_drive(req);
                    join
                    b_drive(req);
                end
                else begin
                    ar_drive(req);
                    r_drive(req);
                end
            end
            else if(req.err_type==ERR_PAYLOAD_CHG) begin
                if(req.dir==AXI_WRITE) begin
                    fork
                       aw_payload_err(req);
                       w_drive(req);
                    join
                    b_drive(req);
                end
                else begin
                    ar_drive(req);
                    r_drive(req);
                end
            end
            else if(req.err_type==ERR_HS_DEP) begin
                if(req.dir==AXI_WRITE) begin
                    fork
                        aw_drive(req);
                        w_drive(req);
                    join
                    b_drive(req);
                end
                else begin
                    r_drive(req);
                    ar_drive(req);
                end
            end
            else if(req.err_type==ERR_WLAST) begin
                if(req.dir==AXI_WRITE) begin
                    fork
                        aw_drive(req);
                        w_last_err(req);
                    join
                    b_drive(req);
                end
                else begin
                    ar_drive(req);
                    r_drive(req);
                end
            end
            else begin
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
            end

            seq_item_port.item_done();

        end
    endtask

    virtual task aw_valid_err(axi_base_item req);
        vif.drv_cb.awvalid <= 1'b1;
        vif.drv_cb.awaddr  <= req.addr;
        vif.drv_cb.awlen   <= req.len;
        vif.drv_cb.awsize  <= req.size;
        vif.drv_cb.awburst <= req.burst;
        vif.drv_cb.awid    <= req.awid;

        @(vif.drv_cb);
        vif.drv_cb.awvalid <= 1'b0;
        @(vif.drv_cb);
        vif.drv_cb.awvalid <= 1'b1;
        repeat(3) @(vif.drv_cb);
        vif.drv_cb.awvalid <= 1'b0;
        @(vif.drv_cb);
        aw_drive(req);
endtask

    virtual task aw_payload_err(axi_base_item req);
        vif.drv_cb.awvalid <= 1'b1; //awvalid assert
        vif.drv_cb.awaddr  <= req.addr;
        vif.drv_cb.awlen   <= req.len;
        vif.drv_cb.awsize  <= req.size;
        vif.drv_cb.awburst <= req.burst;
        vif.drv_cb.awid    <= req.awid; 
        repeat(5) @(vif.drv_cb);
         vif.drv_cb.awaddr  <= 0; //address 변경
        do @(vif.drv_cb); while(vif.drv_cb.awready !== 1'b1);
        vif.drv_cb.awvalid <= 1'b0;
    endtask

    virtual task w_last_err(axi_base_item req);
    
    int err_beat;

    // len=0이면 beat가 정상 W로 보냄
    if (req.len == 0) begin
        w_drive(req);
        return;
    end

    err_beat = (req.len >= 2) ? req.len - 2 : 0;

    for (int i = 0; i <= req.len; i++) begin
        vif.drv_cb.wvalid <= 1'b1;
        vif.drv_cb.wdata  <= req.wdata[i];
        vif.drv_cb.wstrb  <= req.wstrb[i];
        vif.drv_cb.wlast  <= (i == err_beat);
        do @(vif.drv_cb); while (vif.drv_cb.wready !== 1'b1);
    end
    vif.drv_cb.wvalid <= 1'b0;
    vif.drv_cb.wlast  <= 1'b0;
endtask

endclass

