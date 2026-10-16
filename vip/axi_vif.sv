interface axi_vif (input logic aclk, input logic areset_n);

    import axi_vip_pkg::*;

	// Read Address Channel
	addr_t araddr;
	logic arvalid;
	logic arready;
	len_t arlen;
	size_t arsize;
	burst_e arburst;

	// Read Data Channel
	data_t rdata;
	resp_t rresp;
	logic rvalid;
	logic rready;
	logic rlast;

	// Write Address Channel
	addr_t awaddr;
	logic awvalid;
	logic awready;
	len_t awlen;
	size_t awsize;
	burst_e awburst;

	// Write Data Channel
	data_t wdata;
	strb_t wstrb;
	logic wvalid;
	logic wready;
	logic wlast;

	// Write Response Channel
	resp_t bresp;
	logic bvalid;
	logic bready;

	clocking drv_cb @(posedge aclk);
		default input #1step output #1ns;
		
		input arready;
		input rdata, rresp, rvalid, rlast;
		input awready;
		input wready, bresp, bvalid;
		
		output araddr, arvalid, arlen, arsize, arburst;
		output rready;
		output awaddr, awvalid, awlen, awsize, awburst;
		output wdata, wstrb, wvalid, wlast;
		output bready;
	endclocking

	clocking mon_cb @(posedge aclk); // master, slave 신호 모두 monitoring 하기 위함
		default input #1step;
		
		input araddr, arvalid, arready, arlen, arsize, arburst; //read address channel
		input rdata, rresp, rvalid, rready, rlast; //read data channel
		input awaddr, awvalid, awready, awlen, awsize, awburst; // write address channel
		input wdata, wstrb, wvalid, wready, wlast; //write data channel
		input bresp, bvalid, bready; //write response channel
	endclocking


	modport master (
		clocking drv_cb
	);

	modport mon (
		clocking mon_cb
	);

    modport slave (
		input araddr, arvalid, output arready, input arlen, arsize, arburst,
		output rdata, rresp, rvalid, input rready, output rlast,
		input awaddr, awvalid, output awready, input awlen, awsize, awburst,
		input 	wdata, wstrb, wvalid, output wready, input wlast,
		output bresp, bvalid, input bready
	);

endinterface
