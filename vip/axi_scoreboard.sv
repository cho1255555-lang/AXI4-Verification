class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp #(axi_base_item,  axi_scoreboard) ap_imp;

    bit [7:0] mem [addr_t];

    int unsigned n_write;
    int unsigned n_read;
    int unsigned n_byte_written;
    int unsigned n_byte_checked;
    int unsigned n_byte_hit;
    int unsigned n_byte_skipped;
    int unsigned n_mismatch;

    bit check_unwritten = 1;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp",this);
    endfunction

    virtual function void write(axi_base_item tr);
        if(tr.dir==AXI_WRITE) begin
            write_process(tr);
            n_write++;
        end
        else begin
            read_process(tr);
        end
    endfunction

    virtual function void write_process(axi_base_item tr);
        localparam int BUS_BYTES = $bits(strb_t);  // 버스 바이트 수

        data_t wdata;                
        int    beat_byte = 1 << tr.size; //하나의 beat에 보내는 바이트 수     
        addr_t beat_addr, lane_addr;
        int    lane;

        if (tr.bresp != 0)
          `uvm_error("SCBD", $sformatf("BRESP not OKAY : resp %0d", tr.bresp))

        for (int i = 0; i < tr.len+1; i++) begin
            wdata = tr.wdata[i];
            beat_addr = (tr.calc_addr(i) >> tr.size) << tr.size;   //beat의 시작 주소 
            for (int j = 0; j < beat_byte; j++) begin
                lane_addr = beat_addr + j;                         //beat 안의 lane 주소
                lane = lane_addr % BUS_BYTES;                 // 레인 Number
                if (tr.wstrb[i][lane]) begin                             
                    mem[lane_addr] = wdata[8*lane +: 8];
                    n_byte_written++;           
                end
            end
        end
    endfunction

    virtual function void read_process(axi_base_item tr);
        localparam int BUS_BYTES = $bits(strb_t);    // 버스 바이트 수 (32비트면 4)

        data_t      rdata;
        int         beat_byte = 1 << tr.size;         // 하나의 beat에 받는 바이트 수
        addr_t      beat_addr, lane_addr;
        int         lane;
        strb_t      valid_lane;                       // 이 beat에서 유효한 레인
        bit [7:0]   exp;
        logic [7:0] act;
        bit         written;

        n_read++;

        for (int i = 0; i < tr.len+1; i++) begin
            rdata      = tr.rdata[i];                                // i번째 beat 데이터 (원본 유지)
            beat_addr  = (tr.calc_addr(i) >> tr.size) << tr.size;    // beat의 시작 주소
            valid_lane = tr.calc_wstrb(i);                           // 주소로 계산한 유효 레인

            if (tr.rresp[i] != 0)
                `uvm_error("SCBD", $sformatf("RRESP not OKAY : beat %0d resp %0d", i, tr.rresp[i]))

            for (int j = 0; j < beat_byte; j++) begin
                lane_addr = beat_addr + j;                           // beat 안의 바이트 주소
                lane      = lane_addr % BUS_BYTES;                   // 레인 번호

                if (valid_lane[lane]) begin                          // 유효한 칸만 비교
                    written = mem.exists(lane_addr);

                    if (!written && !check_unwritten) begin          // 쓴 적 없는 칸 건너뛰기 (knob)
                        n_byte_skipped++;
                        continue;
                    end

                    exp = written ? mem[lane_addr] : 8'h00;          // 쓴 적 없으면 초기값 0
                    act = rdata[8*lane +: 8];
                    n_byte_checked++;
                    if (written) n_byte_hit++;

                    if (act !== exp) begin
                        n_mismatch++;
                        `uvm_error("SCBD", $sformatf("data mismatch : beat %0d addr 0x%0h exp 0x%02h act 0x%02h (%s)",
                                i, lane_addr, exp, act, written ? "written" : "init"))
                    end
                end
            end
        end
    endfunction


    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SCBD_REPORT", $sformatf({"\n",
            "  ---------------- Scoreboard Summary ----------------\n",
            "  write transactions   : %0d\n",
            "  read  transactions   : %0d\n",
            "  bytes written        : %0d\n",
            "  bytes compared       : %0d\n",
            "    - hit written data : %0d\n",
            "  bytes skipped        : %0d\n",
            "  data mismatches      : %0d\n",
            "  ----------------------------------------------------"},
            n_write, n_read, n_byte_written,
            n_byte_checked, n_byte_hit, n_byte_skipped, n_mismatch), UVM_LOW)

        if (n_read > 0 && n_byte_hit == 0)
            `uvm_warning("SCBD_REPORT", "reads never hit written data : data path was not actually verified")
    endfunction

    



endclass
        

