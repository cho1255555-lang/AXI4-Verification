/*
확인할 목록 :
handshake
  1. read, write가 모두 나왔는가                        
  2. 채널별 대기 클럭이 0~5까지 인가되었는가, 6이상으로 인가된 적은 있는가? 
  3. AW 먼저 / W 먼저 / 동시에 handshake가 나왔는가 aw channel 순서
  */

class axi_coverage extends uvm_subscriber #(axi_base_item);
    `uvm_component_utils(axi_coverage)

    axi_base_item tr;

    covergroup cg_hs;   
        option.per_instance = 1;  //인스턴스별 coverage를 따로 수집 (get_inst_coverage()로 이 인스턴스 결과만 리포트)
        //---------------------read, write---------------------
        cp_dir : coverpoint tr.dir; 
        
        //---------------------handshake delay---------------------
        cp_aw_delay : coverpoint tr.aw_delay iff(tr.dir==AXI_WRITE) {
            bins delay [] = {[0:5]};
            illegal_bins out_boundary = {[6:$]};
        }

        cp_w_delay : coverpoint tr.w_delay iff(tr.dir==AXI_WRITE){
            bins delay [] = {[0:5]};
            illegal_bins out_boundary = {[6:$]};
        }

        cp_b_delay : coverpoint tr.b_delay iff(tr.dir==AXI_WRITE){
            bins delay [] = {[0:5]};
            illegal_bins out_boundary = {[6:$]};
        }

        cp_ar_delay : coverpoint tr.ar_delay iff(tr.dir==AXI_READ){
            bins delay [] = {[0:5]};
            illegal_bins out_boundary = {[6:$]};
        }

        cp_r_delay : coverpoint tr.r_delay iff(tr.dir==AXI_READ){
            bins delay [] = {[0:5]};
            illegal_bins out_boundary = {[6:$]};
        }
        
        //---------------------write operation timing 경우의 수---------------------
        cp_aw_timing : coverpoint (int'(tr.aw_delay)-int'(tr.w_delay)) {
            bins aw_first [] = {[-5:-1]};
            bins same_timing = {0};
            bins w_first [] = {[1:5]};
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
        pct = cg_hs.cp_aw_delay.get_inst_coverage(covered, total);  print_cp("cp_aw_delay",  pct, covered, total);
        pct = cg_hs.cp_w_delay.get_inst_coverage(covered, total);   print_cp("cp_w_delay",   pct, covered, total);
        pct = cg_hs.cp_b_delay.get_inst_coverage(covered, total);   print_cp("cp_b_delay",   pct, covered, total);
        pct = cg_hs.cp_ar_delay.get_inst_coverage(covered, total);  print_cp("cp_ar_delay",  pct, covered, total);
        pct = cg_hs.cp_r_delay.get_inst_coverage(covered, total);   print_cp("cp_r_delay",   pct, covered, total);
        pct = cg_hs.cp_aw_timing.get_inst_coverage(covered, total); print_cp("cp_aw_timing", pct, covered, total);
    endfunction

    function void print_cp(string name, real pct, int covered, int total);
        `uvm_info("COV", $sformatf("  %-14s : %6.2f%% (%0d/%0d bins)", name, pct, covered, total), UVM_LOW)
    endfunction
    

endclass



