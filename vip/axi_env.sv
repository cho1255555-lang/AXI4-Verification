class axi_env extends uvm_env;
    `uvm_component_utils(axi_env)
    
    axi_agent agt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "agt", "is_active", UVM_ACTIVE);
        agt = axi_agent::type_id::create("agt",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        //scoreboard, coverage port 연결
    endfunction
endclass
        
        
        
        