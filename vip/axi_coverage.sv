/*
확인할 목록 :
handshake
  1. read, write 동작 case를 검증했는가                        
  2. R, B channel slave가 master에서 ready를 주기 전까지 assert하는 case를 검증했는가
  3. AW, W의 handshake 시점 순서 W Chanel 기준 빠른가, 느린가, 동시에 3가지 경우를 검증했는가
  */

class axi_coverage extends uvm_subscriber #(axi_base_item);
    `uvm_component_utils(axi_coverage)

    axi_base_item tr;

    covergroup cg_hs;   
        option.per_instance = 1;  //인스턴스별 coverage를 따로 수집 (get_inst_coverage()로 이 인스턴스 결과만 리포트)
        //---------------------read, write---------------------
        cp_dir : coverpoint tr.dir; 
        
        //---------------------slave valid signal 유지 확인---------------------

        cp_b_delay : coverpoint tr.b_delay iff(tr.dir==AXI_WRITE){
            bins delay [] = {[0:5]};
            illegal_bins out_boundary = {[6:$]};
        }

        cp_r_delay : coverpoint tr.r_delay iff(tr.dir==AXI_READ){
            bins delay [] = {[0:5]};
            illegal_bins out_boundary = {[6:$]};
        }
        
        //---------------------write operation timing 경우의 수---------------------
        cp_aw_timing : coverpoint (longint'(tr.aw_time) - longint'(tr.w_time)) iff(tr.dir==AXI_WRITE) {
            bins aw_first = {[$:-1]};   // AW가 먼저 
            bins same     = {0};        // 같은 클럭
            bins w_first  = {[1:$]};    // W가 먼저 
        }         
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_hs = new();
    endfunction 

    virtual function void write(axi_base_item t);
        tr = t;
        cg_hs.sample();
    endfunction 
    
    virtual function void report_phase(uvm_phase phase);
        int  covered, total;
        real pct;

        super.report_phase(phase);

        `uvm_info("COV", $sformatf("handshake coverage total : %0.2f%%", cg_hs.get_inst_coverage()), UVM_LOW)

        //coverpoint마다 bin의 coverage를 확인하기 위함

        pct = cg_hs.cp_dir.get_inst_coverage(covered, total);       print_cp("cp_dir",       pct, covered, total);
        pct = cg_hs.cp_b_delay.get_inst_coverage(covered, total);   print_cp("cp_b_delay",   pct, covered, total);
        pct = cg_hs.cp_r_delay.get_inst_coverage(covered, total);   print_cp("cp_r_delay",   pct, covered, total);
        pct = cg_hs.cp_aw_timing.get_inst_coverage(covered, total); print_cp("cp_aw_timing", pct, covered, total);
    endfunction

    function void print_cp(string name, real pct, int covered, int total);
        `uvm_info("COV", $sformatf("  %-14s : %6.2f%% (%0d/%0d bins)", name, pct, covered, total), UVM_LOW)
    endfunction
    

endclass



