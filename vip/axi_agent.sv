class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)

    axi_driver drv;
    axi_sequencer sqcr;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(get_is_active()==UVM_ACTIVE) begin
            drv = axi_driver::type_id::create("drv",this);
            sqcr = axi_sequencer::type_id::create("sqcr",this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(get_is_active()==UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqcr.seq_item_export);
        end
    endfunction

endclass
    
        
        