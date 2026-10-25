class axi_base_item extends uvm_sequence_item;
    `uvm_object_utils(axi_base_item)
	
	axi_cfg cfg;

	rand dir_e dir;

	//master -> slave
	
    rand addr_t addr;
	rand len_t len;
	rand size_t size;
	rand burst_e burst;
	

	// Write Data 
	rand data_t wdata[$];
	strb_t wstrb[$];

	//slave -> master
	data_t rdata[$]; 
	resp_t rresp[$]; 
	resp_t bresp;

	rand id_t	arid;
	id_t		rid;
	rand id_t	awid;
	id_t		bid;


	rand int unsigned ar_delay; 
	rand int unsigned r_delay; 
	rand int unsigned aw_delay; 
	rand int unsigned w_delay; 
	rand int unsigned b_delay;
	//AW, W간에 의존성이 없지만 AR과 R, Write와 B사이엔 의존성 존재
	//AR -> R 순서 Write -> B 순서로 의존성 존재 

	time aw_time; //handshake 시점 coverage에 넘기기 위함
	time w_time;
	
	rand bit is_aligned;

	constraint c_align {
		solve is_aligned before addr;
		if (is_aligned) addr == ((addr >> size) << size);
	}	
	
	constraint bus_width_limit {
		(1<<size) <= cfg.bus_width/8; //bus width에 맞춰 burst size constraint
	}

	constraint addr_limit{
		addr <= (1<<cfg.addr_width)-1;
	}

	constraint c_queue_size{
		wdata.size() == len+1;
	}

	constraint c_delay {
		ar_delay inside {[0:5]};
		r_delay inside {[0:5]};
		aw_delay inside {[0:5]};
		w_delay inside {[0:5]};
		b_delay inside {[0:5]};
	}

	constraint c_burst {
		burst != RESERVED;
	}

	constraint c_burst_len {
		if (burst == FIXED) {
			len <= 15;
		}
		else if (burst == INCR) {
			((addr[11:0]>>size)<<size)+(1<<size)*(len+1) <= (1<<12);
		}
		else if (burst == WRAP) {
			addr == ((addr>>size)<<size);
			len inside {1,3,7,15};
		}
	}


	function new(string name = "axi_base_item");
		super.new(name);
	endfunction


	function void post_randomize();
		make_wstrb();
	endfunction

	virtual function void make_wstrb();
		wstrb.delete();
		for(int i=0;i<len+1;i++) begin
			wstrb.push_back(calc_wstrb(i));
		end
	endfunction

	virtual function strb_t calc_wstrb(int unsigned n);
		addr_t a;
		int unsigned lo, hi;
		a = calc_addr(n);
		lo = a % $bits(strb_t);
		hi = (((a >> size) << size) % $bits(strb_t)) + (1<<size) - 1;
		return (strb_t'(1) << (hi + 1)) - (strb_t'(1) << lo);
	endfunction

	virtual function addr_t aligned_addr();
		return ((addr>>size)<<size); 
	endfunction
	
	virtual function addr_t wrap_boundary();
		int unsigned total = (1<<size)*(len+1);
		return (addr / total) * total;
	endfunction

	virtual function addr_t calc_addr(int unsigned n);
		addr_t a;
		int unsigned total;
		case(burst)
			FIXED : a = addr;
			INCR  : a = (n==0)? addr:(aligned_addr() + n*(1<<size));
			WRAP  : begin
				total = (1<<size)*(len+1);
				a = addr+n*(1<<size);
				if(a>=wrap_boundary()+total) begin
					a= a-total;
				end
			end
			default : a = addr;
			
		endcase
		return a;
	endfunction
		
		
 
	virtual function string convert2string();
		string s;

		s = $sformatf("dir: %s, id: 0x%0h, addr: 0x%0h, len: %0d(%0d beats), size: %0d(%0dB), burst: %s",
						dir.name(), (dir == AXI_WRITE) ? awid : arid, addr,
						len, len + 1, size, 1 << size, burst.name());

		if (dir == AXI_WRITE) begin
			foreach (wdata[i])
			s = {s, $sformatf("\n  beat[%0d] wdata: 0x%0h, wstrb: %b",
								i, wdata[i], (i < wstrb.size()) ? wstrb[i] : '0)};
			s = {s, $sformatf("\n  bresp: %0d", bresp)};
		end
		else begin
			if (rdata.size() == 0)
			s = {s, "\n  (no read data yet)"};
			foreach (rdata[i])
			s = {s, $sformatf("\n  beat[%0d] rdata: 0x%0h, rresp: %0d",
								i, rdata[i], (i < rresp.size()) ? rresp[i] : '0)};
		end

		return s;
endfunction

	virtual function string delay_print();
		return $sformatf("ar: %0d, r: %0d, aw: %0d, w: %0d, b:%0d",ar_delay, r_delay,aw_delay,w_delay,b_delay);
	endfunction

    //pkg만들기, 나중에 config로 값을 넘겨서 target design에 맞춰
	//주소 변환하기

   
endclass
