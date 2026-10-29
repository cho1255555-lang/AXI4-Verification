class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)

    uvm_analysis_port #(axi_base_item) ap;
    axi_driver drv;
    axi_monitor mon;
    axi_sequencer sqcr;

    axi_cfg cfg;
   


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ap = new("ap", this); 

        void'(uvm_config_db#(axi_cfg)::get(this,"","cfg",cfg));
        
        if(cfg.is_active==UVM_ACTIVE) begin
            drv = axi_driver::type_id::create("drv",this);
            sqcr = axi_sequencer::type_id::create("sqcr",this);
        end
        mon = axi_monitor::type_id::create("mon",this); //Monitor는 Passive로 항상 dut 모니터링

        
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        mon.ap.connect(ap);

        if(cfg.is_active==UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqcr.seq_item_export);
        end
    endfunction

endclass

