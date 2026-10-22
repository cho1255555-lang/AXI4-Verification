class axi_base_test extends uvm_test;
    `uvm_component_utils(axi_base_test)

    axi_env env;
    axi_cfg cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        env = axi_env::type_id::create("env",this);
        cfg = axi_cfg::type_id::create("cfg");
        uvm_config_db#(axi_cfg)::set(this,"*","cfg",cfg);

    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
         uvm_root::get().print_topology();
    endfunction

endclass

class axi_rand_test extends axi_base_test;
    `uvm_component_utils(axi_rand_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        multi_beat_seq seq;
      	//hs_rand_seq seq;
        phase.raise_objection(this);
        //seq = hs_rand_seq::type_id::create("seq");
        seq = multi_beat_seq::type_id::create("seq");
        seq.start(env.agt.sqcr);
        #100ns;
        phase.drop_objection(this);
    endtask

    

endclass
        


        