class axi_env extends uvm_env;
    `uvm_component_utils(axi_env)
    
    axi_agent agt;
    axi_scoreboard scbd;
    axi_coverage cov;
    axi_cfg cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(axi_cfg)::get(this,"","cfg",cfg)) begin
            `uvm_fatal("ENV FATAL","can't get cfg")
        end
        if(cfg.has_coverage) begin
            cov = axi_coverage::type_id::create("cov",this);
        end
        agt = axi_agent::type_id::create("agt",this);
        scbd = axi_scoreboard::type_id::create("scbd",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(cfg.has_coverage) begin
            agt.ap.connect(cov.analysis_export);
        end
        agt.ap.connect(scbd.ap_imp);
    endfunction
endclass
        
        
        
        