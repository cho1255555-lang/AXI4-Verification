/*
확인할 목록 :
handshake
    1. read, write 동작 case를 검증했는가                        
    2. R, B channel slave가 master에서 ready를 주기 전까지 assert하는 case를 검증했는가
    3. AW, W의 handshake 시점 순서 W Chanel 기준 빠른가, 느린가, 동시에 3가지 경우를 검증했는가

multi beat transfer
    1. wstrb full인 경우와 일부 lane이 채워지는 case를 검증했는가
    2. full transfer와 narrow transfer case가 검증되었는가 (read, write 모두)
    3. len의 모든 case를 검증했는가 (read, write 모두)
    4. burst type FIXED, INCR case가 모두 검증되었는가 (multi beat지만 이전 coverage 도 모두 채우기 위함) (read, write 모두)
    5. 정렬 주소와 비정렬 주소를 case가 모두 검증되었는가 (read, write 모두)
    6. address 4KB 범위로 나눠 case 검증 (read, write 모두)
        -시작 주소의 페이지(region) + INCR burst 끝이 4KB 경계에 얼마나 가까운지(4kb_gap)
    7. narrow, full size transfer, aligned, unaligned address 전송 cross case가 검증되었는지 (INCR read, write 모두, FIXED write만 )
    
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
            bins delay []    = {[0:5]};
            bins long_delay  = {[6:$]};
           
        }

        cp_r_delay : coverpoint tr.r_delay iff(tr.dir==AXI_READ){
            bins delay []    = {[0:5]};
            bins long_delay  = {[6:$]};
           
        }
        
        //---------------------write operation timing 경우의 수---------------------
        cp_aw_timing : coverpoint (longint'(tr.aw_time) - longint'(tr.w_time)) iff(tr.dir==AXI_WRITE) {
            bins aw_first = {[$:-1]};   // AW가 먼저 
            bins same     = {0};        // 같은 클럭
            bins w_first  = {[1:$]};    // W가 먼저 
        }         
    endgroup



    covergroup multi_beat;
        option.per_instance = 1;

        //---------------------full, narrow transfer coverage---------------------
        cp_strb : coverpoint tr.wstrb[0] iff(tr.dir==AXI_WRITE){
            bins full = {4'b1111};
            bins upper1 = {4'b1110};
            bins upper2 = {4'b1100};
            bins upper3 = {4'b1000};
        }

        //---------------------full, narrow transfer coverage---------------------
        cp_w_size : coverpoint tr.size iff(tr.dir==AXI_WRITE){
            bins full = {2};
            bins narrow [] = {[0:1]};
            illegal_bins ill_size [] = {[3:$]};
        }
        cp_r_size : coverpoint tr.size iff(tr.dir==AXI_READ){
            bins full = {2};
            bins narrow [] = {[0:1]};
            illegal_bins ill_size [] = {[3:$]};
        }

        //---------------------len coverage---------------------
        cp_w_len : coverpoint tr.len iff(tr.dir==AXI_WRITE){
            bins    one = {0};
            bins    low_len = {[1:14]};
            bins    fixed_limit = {15}; //fixed burst type limit <=16 beat transfer
            bins    over_16 = {[16:254]};
            bins    max_len = {255};
             
            } //len+1 기준

        cp_r_len : coverpoint tr.len iff(tr.dir==AXI_READ){
            bins    one = {0};
            bins    low_len = {[1:14]};
            bins    fixed_limit = {15}; //fixed burst type limit <=16 beat transfer
            bins    over_16 = {[16:254]};
            bins    max_len = {255};
             
            } //len+1 기준

        //---------------------burst type---------------------
        cp_w_burst : coverpoint tr.burst iff(tr.dir==AXI_WRITE){
            bins burst [] = {FIXED, INCR};
            ignore_bins ilburst = {WRAP}; //dut 지원 안함
        }
        cp_r_burst : coverpoint tr.burst iff(tr.dir==AXI_READ){
            bins burst [] = {FIXED, INCR};
            ignore_bins ilburst = {WRAP}; //dut 지원 안함

        }

        //---------------------aligned / unaligned---------------------
        cp_w_aligned : coverpoint (tr.addr & ((1 << tr.size)-1)) iff(tr.dir==AXI_WRITE) {
            bins aligned   = {0};
            bins unaligned[]  = {[1:3]};        
        }
        
        cp_r_aligned : coverpoint (tr.addr & ((1 << tr.size)-1)) iff(tr.dir==AXI_READ) {
            bins aligned   = {0};
            bins unaligned[]  = {[1:3]};        
        }

        //---------------------4KB 페이지 위치---------------------
        cp_w_region : coverpoint tr.addr iff (tr.dir == AXI_WRITE) {
            bins first_page = {[16'h0000 : 16'h0FFF]};   // 첫 4KB 페이지
            bins middle     = {[16'h1000 : 16'hEFFF]};
            bins last_page  = {[16'hF000 : 16'hFFFF]};   // 마지막 4KB 페이지
        }

        cp_r_region : coverpoint tr.addr iff (tr.dir == AXI_READ) {
            bins first_page = {[16'h0000 : 16'h0FFF]};   // 첫 4KB 페이지
            bins middle     = {[16'h1000 : 16'hEFFF]};
            bins last_page  = {[16'hF000 : 16'hFFFF]};   // 마지막 4KB 페이지
        }

        //---------------------INCR burst 끝 ~ 4KB 경계까지 남은 바이트---------------------
        // item의 c_incr constraint와 같은 식 : 4096 - (페이지 안 정렬 시작 위치 + 전체 전송 바이트)
        // 0 이면 burst가 4KB 경계에 정확히 맞춰 끝남 (constraint의 <= 경계값)
        cp_w_4kb_gap : coverpoint (4096 - ( ((tr.addr[11:0] >> tr.size) << tr.size) + (1 << tr.size) * (tr.len + 1) ))
                       iff (tr.dir == AXI_WRITE && tr.burst == INCR) {
            bins exact_end = {0};
            bins near      = {[1:64]};
            bins far       = {[65:4095]};
        }
        cp_r_4kb_gap : coverpoint (4096 - ( ((tr.addr[11:0] >> tr.size) << tr.size) + (1 << tr.size) * (tr.len + 1) ))
                       iff (tr.dir == AXI_READ && tr.burst == INCR) {
            bins exact_end = {0};
            bins near      = {[1:64]};
            bins far       = {[65:4095]};
        }

        //--------------------- burst × len---------------------
        // FIXED는 len 16 beat까지만 허용  
        cx_w_burst_len : cross cp_w_burst, cp_w_len {
            ignore_bins fixed_over_16 = binsof(cp_w_burst) intersect {FIXED} &&
                                        binsof(cp_w_len)   intersect {[16:255]};
        }
        cx_r_burst_len : cross cp_r_burst, cp_r_len {
            ignore_bins fixed_over_16 = binsof(cp_r_burst) intersect {FIXED} &&
                                        binsof(cp_r_len)   intersect {[16:255]};
        }
        //---------------------size × aligned (INCR / FIXED 각각)---------------------
        cx_w_incr_size_aligned  : cross cp_w_size, cp_w_aligned iff(tr.burst==INCR);
        cx_r_incr_size_aligned  : cross cp_r_size, cp_r_aligned iff(tr.burst==INCR);
 
        // FIXED는 write만 : narrow면 매 beat 같은 lane, unaligned면 매 beat 같은 일부 strobe 반복
        cx_w_fixed_size_aligned : cross cp_w_size, cp_w_aligned iff(tr.burst==FIXED);
        
    endgroup
    

    function new(string name, uvm_component parent);
        super.new(name, parent);
        if(tr.len==0) begin
            cg_hs = new();
        end
        multi_beat = new();
    endfunction 

    virtual function void write(axi_base_item t);
        tr = t;
        cg_hs.sample();
        multi_beat.sample();
    endfunction 
    
    
     virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        //---------------------handshake---------------------
        `uvm_info("COV", $sformatf("handshake coverage total : %0.2f%%", cg_hs.get_inst_coverage()), UVM_LOW)

        //---------------------burst---------------------
        `uvm_info("COV", $sformatf("burst coverage total : %0.2f%%", multi_beat.get_inst_coverage()), UVM_LOW)

        /*
        // xsim : coverpoint 단위 get_inst_coverage(covered, total) 호출 시 kernel crash → 세부는 xcrg HTML로 확인
        int  covered, total;   // ← 주석을 풀 때는 이 선언을 함수 맨 위로 옮길 것
        real pct;

        pct = cg_hs.cp_dir.get_inst_coverage(covered, total);       print_cp("cp_dir",       pct, covered, total);
        pct = cg_hs.cp_b_delay.get_inst_coverage(covered, total);   print_cp("cp_b_delay",   pct, covered, total);
        pct = cg_hs.cp_r_delay.get_inst_coverage(covered, total);   print_cp("cp_r_delay",   pct, covered, total);
        pct = cg_hs.cp_aw_timing.get_inst_coverage(covered, total); print_cp("cp_aw_timing", pct, covered, total);

        pct = multi_beat.cp_strb.get_inst_coverage(covered, total);                 print_cp("cp_strb",                 pct, covered, total);
        pct = multi_beat.cp_w_size.get_inst_coverage(covered, total);               print_cp("cp_w_size",               pct, covered, total);
        pct = multi_beat.cp_r_size.get_inst_coverage(covered, total);               print_cp("cp_r_size",               pct, covered, total);
        pct = multi_beat.cp_w_len.get_inst_coverage(covered, total);                print_cp("cp_w_len",                pct, covered, total);
        pct = multi_beat.cp_r_len.get_inst_coverage(covered, total);                print_cp("cp_r_len",                pct, covered, total);
        pct = multi_beat.cp_w_burst.get_inst_coverage(covered, total);              print_cp("cp_w_burst",              pct, covered, total);
        pct = multi_beat.cp_r_burst.get_inst_coverage(covered, total);              print_cp("cp_r_burst",              pct, covered, total);
        pct = multi_beat.cp_w_aligned.get_inst_coverage(covered, total);            print_cp("cp_w_aligned",            pct, covered, total);
        pct = multi_beat.cp_r_aligned.get_inst_coverage(covered, total);            print_cp("cp_r_aligned",            pct, covered, total);
        pct = multi_beat.cp_w_region.get_inst_coverage(covered, total);             print_cp("cp_w_region",             pct, covered, total);
        pct = multi_beat.cp_r_region.get_inst_coverage(covered, total);             print_cp("cp_r_region",             pct, covered, total);
        pct = multi_beat.cp_w_4kb_gap.get_inst_coverage(covered, total);            print_cp("cp_w_4kb_gap",            pct, covered, total);
        pct = multi_beat.cp_r_4kb_gap.get_inst_coverage(covered, total);            print_cp("cp_r_4kb_gap",            pct, covered, total);
        pct = multi_beat.cx_w_burst_len.get_inst_coverage(covered, total);          print_cp("cx_w_burst_len",          pct, covered, total);
        pct = multi_beat.cx_r_burst_len.get_inst_coverage(covered, total);          print_cp("cx_r_burst_len",          pct, covered, total);
        pct = multi_beat.cx_w_incr_size_aligned.get_inst_coverage(covered, total);  print_cp("cx_w_incr_size_aligned",  pct, covered, total);
        pct = multi_beat.cx_r_incr_size_aligned.get_inst_coverage(covered, total);  print_cp("cx_r_incr_size_aligned",  pct, covered, total);
        pct = multi_beat.cx_w_fixed_size_aligned.get_inst_coverage(covered, total); print_cp("cx_w_fixed_size_aligned", pct, covered, total);
        */
    endfunction
   
    
endclass



