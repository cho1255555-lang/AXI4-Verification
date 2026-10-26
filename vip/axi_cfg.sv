class axi_cfg extends uvm_object;
    `uvm_object_utils(axi_cfg)

    uvm_active_passive_enum is_active = UVM_ACTIVE; //agent Passive, Active mode 설정
    bit has_coverage = 1; //coverage on,off 설정
    
    int unsigned seq_rpt = 3; //sequence에서 시나리오 중 repeat할 횟수 설정  
    int unsigned prefill_rpt = 3;
    //시나리오 size, len, addr 범위 설정
    int unsigned min_size = 2;
    int unsigned max_size = 2;
    int unsigned min_len = 0;
    int unsigned max_len = 20;
    int unsigned min_addr = 16'h0;
    int unsigned max_addr = 16'h06FF;
    

    function new(string name = "axi_cfg");
        super.new(name);
    endfunction

endclass


