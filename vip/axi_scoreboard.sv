class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_port #(axi_base_item, axi_scoreboard) mon_imp;  
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_imp = new("mon_imp",this);
    endfunction

    virtual function write(axi_base_item tr);
        if(tr.dir==AXI_READ) begin
            read_process(tr);
        end
        else begin
            write_process(tr);
        end
    endfunction

    virtual function read_process(axi_base_item tr);
        
    endfunction

    virtual function write_process(axi_base_item tr);
    
    endfunction
            


    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);


    endfunction
    
    
endclass

    