// assertion 구현 목록
//
//  1. Valid Assert시 handshake 완료 전까지 Payload가 변하지 않음 O
//  2. AR handshake 완료 전까지 RVALID가 assert 하지 않음 O
//  3. W, AW handshake 완료전까지 BVALID 신호 assert 하지 않음 O
//  4. INCR burst 시 4KB boundary를 넘지 않음 O
//  5. FIXED burst 시 beat 길이 16 이하 (AxLEN ≤ 15) O
//  6. WRAP burst 길이가 2/4/8/16 중 하나로 설정됨  O
//  7. len에 따라 len_1번째 beat에만 WLAST assert O
//  8. len에 따라 len+1 번째 beat에만 RLAST assert O




module axi_protocol_checker #(
    parameter int MAX_WAIT = 10           // 응답을 기다릴 최대 사이클
)(
    input logic aclk,
    input logic areset_n,
    axi_vif.check vif
);
    import uvm_pkg::*;
    import axi_vip_pkg::*;
    `include "uvm_macros.svh"

    default clocking cb @(posedge aclk); endclocking
    default disable iff (!areset_n);


    //  handshake 신호 
    logic aw_hs, w_hs, b_hs, ar_hs, r_hs;
    assign aw_hs = vif.awvalid && vif.awready;
    assign w_hs  = vif.wvalid  && vif.wready;
    assign b_hs  = vif.bvalid  && vif.bready;
    assign ar_hs = vif.arvalid && vif.arready;
    assign r_hs  = vif.rvalid  && vif.rready;

    logic [7:0] r_len_q, r_beat_cnt;   // AR에서 받은 len, 현재 R beat 
    logic [7:0] w_len_q, w_beat_cnt;   // AW에서 받은 len, 현재 W beat 
    int         r_pending;        
    int         aw_pending;            
    int         w_pending;             

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            r_len_q <= 0;  r_beat_cnt <= 0;
            w_len_q <= 0;  w_beat_cnt <= 0;
            r_pending <= 0;
            aw_pending    <= 0;
            w_pending     <= 0;
        end else begin
            // ---- read ----
            if (ar_hs) r_len_q <= vif.arlen;
            if (r_hs)  r_beat_cnt <= vif.rlast ? 0 : r_beat_cnt + 1;
            r_pending <= r_pending + int'(ar_hs) - int'(r_hs && vif.rlast);

            // ---- write ----
            if (aw_hs) w_len_q <= vif.awlen;
            if (w_hs)  w_beat_cnt <= vif.wlast ? 0 : w_beat_cnt + 1;
            aw_pending <= aw_pending + int'(aw_hs) - int'(b_hs);
            w_pending  <= w_pending  + int'(w_hs && vif.wlast)  - int'(b_hs);
        end
    end


    //  공통 property
    // VALID assert시 READY 받을 때까지 유지
    property p_valid_hold(valid, ready);
        valid && !ready |=> valid;
    endproperty

    // READY 기다리는 동안 payload 변경 금지
    property p_payload_stable(valid, ready, payload);
        valid && !ready |=> $stable(payload);
    endproperty

   
    //  VALID 유지 

    AW_VALID_HOLD : assert property (p_valid_hold(vif.awvalid, vif.awready))
        else `uvm_error("AXI_CHK", "AWVALID dropped before AWREADY")
    W_VALID_HOLD  : assert property (p_valid_hold(vif.wvalid,  vif.wready))
        else `uvm_error("AXI_CHK", "WVALID dropped before WREADY")
    B_VALID_HOLD  : assert property (p_valid_hold(vif.bvalid,  vif.bready))
        else `uvm_error("AXI_CHK", "BVALID dropped before BREADY")
    AR_VALID_HOLD : assert property (p_valid_hold(vif.arvalid, vif.arready))
        else `uvm_error("AXI_CHK", "ARVALID dropped before ARREADY")
    R_VALID_HOLD  : assert property (p_valid_hold(vif.rvalid,  vif.rready))
        else `uvm_error("AXI_CHK", "RVALID dropped before RREADY")

   
    //  payload 유지 
   
    // AW, AR : awid/arid는 아직 driver가 구동하지 않음
    //          → ID를 clocking block에 추가할 때 payload에 함께 추가
    AW_STABLE : assert property (p_payload_stable(vif.awvalid, vif.awready,
                    {vif.awaddr, vif.awlen, vif.awsize, vif.awburst}))
        else `uvm_error("AXI_CHK", "AW payload changed while waiting")

    W_STABLE  : assert property (p_payload_stable(vif.wvalid, vif.wready,
                    {vif.wdata, vif.wstrb, vif.wlast}))          // wstrb 추가
        else `uvm_error("AXI_CHK", "W payload changed while waiting")

    B_STABLE  : assert property (p_payload_stable(vif.bvalid, vif.bready,
                    {vif.bid, vif.bresp}))                          // bid 추가
        else `uvm_error("AXI_CHK", "B payload changed while waiting")

    AR_STABLE : assert property (p_payload_stable(vif.arvalid, vif.arready,
                    {vif.araddr, vif.arlen, vif.arsize, vif.arburst}))
        else `uvm_error("AXI_CHK", "AR payload changed while waiting")

    R_STABLE  : assert property (p_payload_stable(vif.rvalid, vif.rready,
                    {vif.rid, vif.rdata, vif.rresp, vif.rlast}))  // rid 추가
        else `uvm_error("AXI_CHK", "R payload changed while waiting")

    
    // LAST 위치 Check (single이든 multi든 마지막 beat에서만 1)
    
    R_LAST_CHK : assert property (r_hs |-> (vif.rlast == (r_beat_cnt == r_len_q)))
        else `uvm_error("AXI_CHK", $sformatf("RLAST wrong: beat=%0d, arlen=%0d, rlast=%0b",
                                             r_beat_cnt, r_len_q, vif.rlast))
    W_LAST_CHK : assert property (w_hs |-> (vif.wlast == (w_beat_cnt == w_len_q)))
        else `uvm_error("AXI_CHK", $sformatf("WLAST wrong: beat=%0d, awlen=%0d, wlast=%0b",
                                             w_beat_cnt, w_len_q, vif.wlast))

    
    //  채널 간 의존성
    //  AR-> R 순서
    R_AFTER_AR : assert property (vif.rvalid |-> (r_pending > 0))
        else `uvm_error("AXI_CHK", "RVALID asserted without accepted AR")

    // B Channel handshake는 AW, W handshake가 모두 끝난 뒤에만
    B_AFTER_AW_W : assert property (vif.bvalid |-> (aw_pending > 0 && w_pending > 0))
        else `uvm_error("AXI_CHK", "BVALID asserted before AW and last W completed")

    //FIXED Len Limit 16beat 이하까지 허용
    AW_FIXED_LEN : assert property ((vif.awvalid && vif.awburst == FIXED) |-> (vif.awlen <= 15))
        else `uvm_error("AXI_CHK", $sformatf("AW FIXED burst more than 16 beat assigned value=%0d", vif.awlen))

    AR_FIXED_LEN : assert property ((vif.arvalid && vif.arburst == FIXED) |-> (vif.arlen <= 15))
        else `uvm_error("AXI_CHK", $sformatf("AR FIXED burst more than 16 beat assigned value=%0d", vif.arlen))

   AW_WRAP_LEN : assert property ((vif.awvalid && vif.awburst == WRAP) |-> (vif.awlen inside {1, 3, 7, 15}))
        else `uvm_error("AXI_CHK", $sformatf("AW WRAP burst is not inside 2, 4, 8, 16  assigned value=%0d", vif.awlen))
   
    AR_WRAP_LEN : assert property ((vif.arvalid && vif.arburst == WRAP) |-> (vif.arlen inside {1, 3, 7, 15}))
        else `uvm_error("AXI_CHK", $sformatf("AR WRAP burst is not inside 2, 4, 8, 16  assigned value=%0d", vif.arlen))

    // 4KB Boundary cross 검사
    AW_4KB_BOUNDARY : assert property ((vif.awvalid && vif.awburst == INCR) |-> ((int'(vif.awaddr[11:0]) >> vif.awsize) << vif.awsize)
     + ((int'(vif.awlen) + 1) << vif.awsize) <= (1<<12))
        else `uvm_error("AXI_CHK", "AW crosses 4KB boundary")
    AR_4KB_BOUNDARY : assert property ((vif.arvalid && vif.arburst == INCR) |-> ((int'(vif.araddr[11:0]) >> vif.arsize) << vif.arsize)
     + ((int'(vif.arlen) + 1) << vif.arsize) <= (1<<12))
        else `uvm_error("AXI_CHK", "AR crosses 4KB boundary")

endmodule