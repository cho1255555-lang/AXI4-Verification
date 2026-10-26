class axi_cfg extends uvm_object;
    `uvm_object_utils(axi_cfg)

    int unsigned seq_rep = 10; //sequence에서 시나리오 중 repeat할 횟수 설정  
    uvm_active_passive_enum is_active = UVM_ACTIVE; //agent Passive, Active mode 설정
    bit has_coverage = 1; //coverage on,off 설정

    function new(string name = "axi_cfg");
        super.new(name);
    endfunction

endclass


