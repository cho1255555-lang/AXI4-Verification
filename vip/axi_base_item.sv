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
	rand data_t wdata;
	rand strb_t wstrb;

	//slave -> master
	data_t rdata; 
	resp_t rresp; 
	resp_t bresp;


	rand int unsigned ar_delay; 
	rand int unsigned r_delay; 
	rand int unsigned aw_delay; 
	rand int unsigned w_delay; 
	rand int unsigned b_delay;
	//AW, W간에 의존성이 없지만 AR과 R, Write와 B사이엔 의존성 존재
	//AR -> R 순서 Write -> B 순서로 의존성 존재 

	constraint c_limit {
		(1<<size) <= cfg.bus_width/8; //2^burst size 현재 dut size는 64bit
	}

	constraint c_delay {
		ar_delay inside {[0:5]};
		r_delay inside {[0:5]};
		aw_delay inside {[0:5]};
		w_delay inside {[0:5]};
		b_delay inside {[0:5]};
	}

	//valid 신호는 driver에서 구현 


	function new(string name = "axi_base_item");
		super.new(name);
	endfunction

	virtual function string convert2string();
		string s;

		s = $sformatf("dir: %s, addr: 0x%0h, len: %0d, size: %0d, burst: %s",
		 dir.name(), addr, len, size, burst.name());

		 if(dir == AXI_WRITE) begin
			s = {s,$sformatf(", wdata: 0x%0h, wstrb: 0x%0h, bresp: %0d",
			  wdata, wstrb, bresp)};
		 end
		 else begin
			s = {s, $sformatf(", rdata: 0x%0h, rresp: %0d", rdata, rresp)};
		 end
		return s;
	endfunction

	virtual function string delay_print();
		return $sformatf("ar: %d, r: %d, aw: %d, w: %d, b:%d",ar_delay, r_delay,aw_delay,w_delay,b_delay);
	endfunction

    //pkg만들기, 나중에 config로 값을 넘겨서 target design에 맞춰
	//주소 변환하기

    //이후 extends해서 다양한 시나리오 만들기
endclass

    
    