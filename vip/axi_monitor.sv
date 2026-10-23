//monitor 역할 : transaction단위의 data를 analysis port를 통해 scbd나 coverage에 broadcast함
//transaction의 단위는 READ 동작과 WRITE 동작으로 나눔 
//AR->R / AW,W -> B 채널 순서로 transaction이 완성됨 ap.write()

//서로 다른 queue에 의존하면 race condition이 생길 수 있음


class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual axi_vif vif;
    uvm_analysis_port#(axi_base_item) ap;

    axi_base_item ar_q[$];
    axi_base_item aw_q[$];
    axi_base_item w_q[$];
    

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap",this);
        if(!uvm_config_db#(virtual axi_vif)::get(this,"","vif",vif))
            `uvm_fatal("NOVIF","can't find vif")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            wait(vif.areset_n === 1'b1);            
            fork
                begin
                    fork
                        ar_mon();
                        r_mon();
                        aw_mon();
                        w_mon();
                        b_mon();
                        @(negedge vif.areset_n);   // reset 들어오면 이게 먼저 끝남
                    join_any
                    disable fork;
                end
            join

            flush_pending();
        end
            

    endtask

    task ar_mon();
        axi_base_item tr;
        forever begin
            @(vif.mon_cb);
            if(vif.mon_cb.arready && vif.mon_cb.arvalid) begin
                tr = axi_base_item::type_id::create("tr");
                tr.dir = AXI_READ;
                tr.addr = vif.mon_cb.araddr;
                tr.len = vif.mon_cb.arlen;
                tr.size = vif.mon_cb.arsize;
                tr.arid = vif.mon_cb.arid;
                tr.burst = burst_e'(vif.mon_cb.arburst);
                ar_q.push_back(tr);

            end
        end
    endtask

    task r_mon();
        axi_base_item tr;
        int unsigned wait_cnt;
        forever begin        
            @(vif.mon_cb);
            if(vif.mon_cb.rready&& vif.mon_cb.rvalid) begin
                if(tr==null) begin
                    if(ar_q.size()==0) begin
                        `uvm_error("MONERROR","No tr in ar_q")
                    end
                    else begin
                    tr = ar_q.pop_front();
                    end
                end
                if(tr != null) begin 
                    tr.rdata.push_back(vif.mon_cb.rdata);
                    tr.rresp.push_back(vif.mon_cb.rresp);
                    tr.rid = vif.mon_cb.rid;
                    tr.r_delay = wait_cnt;
                    if(vif.mon_cb.rlast) begin
                        sending(tr);
                        wait_cnt =0;
                        tr = null;
                    end
                end          
            end
            else if(vif.mon_cb.rvalid) begin
                wait_cnt++;
            end  
        end
    endtask


    task aw_mon();
        axi_base_item tr;
        
        forever begin
            @(vif.mon_cb);
            if(vif.mon_cb.awready && vif.mon_cb.awvalid) begin
                tr = axi_base_item::type_id::create("tr");
                tr.dir = AXI_WRITE;
                tr.addr = vif.mon_cb.awaddr;
                tr.len = vif.mon_cb.awlen;
                tr.size = vif.mon_cb.awsize;
                tr.burst = burst_e'(vif.mon_cb.awburst);
                tr.aw_time = $time();
                aw_q.push_back(tr);
                
            end
        end

    endtask

    task w_mon();
        axi_base_item tr;

        forever begin
            @(vif.mon_cb);
                if(vif.mon_cb.wready && vif.mon_cb.wvalid) begin                    
                if(tr==null) begin
                    tr = axi_base_item::type_id::create("tr");
                    tr.dir = AXI_WRITE;
                    tr.w_time = $time();
                end
                tr.wdata.push_back(vif.mon_cb.wdata);
                tr.wstrb.push_back(vif.mon_cb.wstrb);                
                if(vif.mon_cb.wlast) begin
                    w_q.push_back(tr);
                    tr = null;  
                end
                
            end
        end
    endtask


    task b_mon();
        axi_base_item tr, temp_tr;
        int unsigned wait_cnt;
        forever begin
            @(vif.mon_cb);
            if(vif.mon_cb.bready && vif.mon_cb.bvalid) begin
               if(w_q.size()==0||aw_q.size()==0) begin
                    `uvm_error("MONERROR",{"No condition of write transaction",$sformatf("aw_q size : %0d, w_q size : %0d",aw_q.size(), w_q.size())})
               end
               else begin
                    tr = aw_q.pop_front();
                    temp_tr = w_q.pop_front();
                    tr.wdata = temp_tr.wdata;
                    tr.wstrb = temp_tr.wstrb;
                    tr.w_time = temp_tr.w_time;  
                    tr.bresp = vif.mon_cb.bresp;
                    tr.bid = vif.mon_cb.bid;
                    tr.b_delay = wait_cnt;
                    sending(tr);
                    `uvm_info("MON_DBG", $sformatf("aw_time=%0t w_time=%0t", tr.aw_time, tr.w_time), UVM_LOW)
               end
               wait_cnt = 0;
            end
            else if(vif.mon_cb.bvalid) begin
                wait_cnt++;
            end

        end
    endtask

    function void sending(axi_base_item tr);
        `uvm_info(get_type_name(),{"Monitor",tr.convert2string()},UVM_LOW)
        ap.write(tr);
    endfunction

    function void flush_pending();
        if (ar_q.size() || aw_q.size() || w_q.size())
        `uvm_info(get_type_name(),
            $sformatf("Reset: discarding pending AR=%0d AW=%0d W=%0d",
                    ar_q.size(), aw_q.size(), w_q.size()), UVM_MEDIUM)
        ar_q.delete();
        aw_q.delete();
        w_q.delete();
    endfunction
  
        


endclass