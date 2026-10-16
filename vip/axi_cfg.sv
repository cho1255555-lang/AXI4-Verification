class axi_cfg extends uvm_object;
    `uvm_object_utils(axi_cfg)

    int unsigned bus_width = 32; // dut의 bus width에 따라 설정 c_limit constraint에서 사용
    int unsigned seq_rep = 10; //sequence에서 시나리오 중 repeat할 횟수 설정    
    
    function new(string name = "axi_cfg");
        super.new(name);
    endfunction

endclass

