interface axi_vif (input logic aclk, input logic areset_n);

    import axi_vip_pkg::*;

	// Read Address Channel
	id_t 		arid;
	addr_t 		araddr;
	len_t 		arlen;
	size_t 		arsize;
	burst_e 	arburst;
	logic       arlock;
    logic [3:0] arcache;
    logic [2:0] arprot;
    logic [3:0] arqos;
    logic [3:0] arregion;
    user_t      aruser;
	logic 		arvalid;
	logic 		arready;

	// Read Data Channel
	id_t        rid;
	data_t 		rdata;
	resp_t 		rresp;
	user_t      ruser;
	logic 		rvalid;
	logic 		rready;
	logic 		rlast;

	// Write Address Channel
	id_t		awid;
	addr_t 		awaddr;
	len_t 		awlen;
	size_t 		awsize;
	burst_e 	awburst;
	logic       awlock;
    logic [3:0] awcache;
    logic [2:0] awprot;
    logic [3:0] awqos;
    logic [3:0] awregion;
    user_t      awuser;
	logic 		awvalid;
	logic 		awready;

	// Write Data Channel
	data_t 		wdata;
	strb_t 		wstrb;
	user_t      wuser;
	logic 		wvalid;
	logic 		wready;
	logic		wlast;

	// Write Response Channel
	id_t        bid;
    resp_t      bresp;
    user_t      buser;
    logic       bvalid;
    logic       bready;

	clocking drv_cb @(posedge aclk);
		default input #1step output #1ns;
		
		input arready;
		input rdata, rresp, rvalid, rlast, rid;
		input awready;
		input wready, bresp, bvalid, bid;
		
		output araddr, arvalid, arlen, arsize, arburst, arid;
		output rready;
		output awaddr, awvalid, awlen, awsize, awburst, awid;
		output wdata, wstrb, wvalid, wlast;
		output bready;
	endclocking

	clocking mon_cb @(posedge aclk); // master, slave 신호 모두 monitoring 하기 위함
		default input #1step;
		
		input araddr, arvalid, arready, arlen, arsize, arburst, arid; //read address channel
		input rdata, rresp, rvalid, rready, rlast, rid; //read data channel
		input awaddr, awvalid, awready, awlen, awsize, awburst, awid; // write address channel
		input wdata, wstrb, wvalid, wready, wlast; //write data channel
		input bresp, bvalid, bready, bid; //write response channel
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
