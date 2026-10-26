class axi_base_seq extends uvm_sequence#(axi_base_item);
    `uvm_object_utils(axi_base_seq)

    axi_cfg cfg;

    function new(string name="axi_base_seq");
        super.new(name);
    endfunction

    virtual task body();
        if(!uvm_config_db#(axi_cfg)::get(null,get_full_name(),"cfg",cfg))
            `uvm_fatal("CFG", "can't find cfg value")
    endtask

endclass

class hs_rand_seq extends axi_base_seq;
    `uvm_object_utils(hs_rand_seq)

    function new(string name = "hs_rand_seq");
        super.new(name);
    endfunction

    virtual task body();
        super.body();
        repeat(cfg.seq_rpt) begin
            req = axi_base_item::type_id::create("req");
            start_item(req);
            if(!req.randomize() with {len==0; burst == INCR;
                dir dist {AXI_WRITE:=60, AXI_READ:=40};})
                    `uvm_fatal("RAND","randomize error")
            finish_item(req);
            `uvm_info("ITEM_INFO",{req.convert2string(),"\n",req.delay_print()},UVM_LOW);
        end
    endtask
endclass

class multi_beat_seq extends axi_base_seq;
    `uvm_object_utils(multi_beat_seq)
    
    function new(string name = "multi_beat_seq");
        super.new(name);
    endfunction

    virtual task body();
        super.body();
        prefill();
        repeat(cfg.seq_rpt) begin
            req = axi_base_item::type_id::create("req");
            start_item(req);
            if(!req.randomize() with {
                arid ==0;
                awid ==0;
                size inside {[cfg.min_size:cfg.max_size]}; 
                len inside {[cfg.min_len:cfg.max_len]};
                addr inside {[cfg.min_addr:cfg.max_addr]};
                
                is_aligned dist {1:=70, 0:=30};                
                burst dist {INCR:=60, FIXED:=40};
                dir dist {AXI_WRITE:=40, AXI_READ:=60};
                }) begin
                `uvm_fatal("RAND","randmonize error")
            end
            finish_item(req);
            `uvm_info("ITEM_INFO",req.convert2string(),UVM_LOW);
        end
    endtask

    virtual task prefill();
        repeat(cfg.prefill_rpt) begin
            req = axi_base_item::type_id::create("req");
            start_item(req);
            if(!req.randomize() with {
                arid ==0;
                awid ==0;
                size inside {[cfg.min_size:cfg.max_size]}; 
                len inside {[cfg.min_len:cfg.max_len]};
                addr inside {[cfg.min_addr:cfg.max_addr]};
                
                is_aligned dist {1:=60, 0:=40};   
                burst == INCR;
                dir == AXI_WRITE;
                }) begin
                `uvm_fatal("RAND","randmonize error")
            end
            finish_item(req);
            `uvm_info("ITEM_INFO",req.convert2string(),UVM_LOW);
        end

    endtask


endclass



            

