// ============================================================
// axi_protocol_checker
//  - DUT가 아니라 vif(버스)에 연결하는 VIP 쪽 checker
//  - tb_top에서 직접 인스턴스 : .s_axi(vif)
//  - DUT가 바뀌어도 이 파일은 그대로
//
// [한계 - outstanding 지원 시 수정 필요]
//  - r_len_q, w_len_q가 AR/AW마다 덮어써짐
//    → 여러 burst가 동시에 진행되면 이전 len을 잃어버림 (큐로 바꿔야 함)
// ============================================================

module axi_protocol_checker #(
    parameter int MAX_WAIT = 100           // 응답을 기다릴 최대 사이클
)(
    input logic aclk,
    input logic areset_n,
    axi_vif     s_axi
);
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    default clocking cb @(posedge aclk); endclocking
    default disable iff (!areset_n);

    // =========================================================
    // 1. handshake 신호 (가독성용)
    // =========================================================
    logic aw_hs, w_hs, b_hs, ar_hs, r_hs;
    assign aw_hs = s_axi.awvalid && s_axi.awready;
    assign w_hs  = s_axi.wvalid  && s_axi.wready;
    assign b_hs  = s_axi.bvalid  && s_axi.bready;
    assign ar_hs = s_axi.arvalid && s_axi.arready;
    assign r_hs  = s_axi.rvalid  && s_axi.rready;

    // =========================================================
    // 2. 보조 로직 (beat 카운트, 미완료 트랜잭션 수)
    // =========================================================
    logic [7:0] r_len_q, r_beat_cnt;   // AR에서 받은 len, 현재 R beat 번호
    logic [7:0] w_len_q, w_beat_cnt;   // AW에서 받은 len, 현재 W beat 번호
    int         r_outstanding;         // AR 받았는데 R이 아직 안 끝난 개수
    int         aw_pending;            // B 응답 안 나간 AW 개수
    int         w_pending;             // B 응답 안 나간 W burst 개수

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            r_len_q <= 0;  r_beat_cnt <= 0;
            w_len_q <= 0;  w_beat_cnt <= 0;
            r_outstanding <= 0;
            aw_pending    <= 0;
            w_pending     <= 0;
        end else begin
            // ---- read ----
            if (ar_hs) r_len_q <= s_axi.arlen;
            if (r_hs)  r_beat_cnt <= s_axi.rlast ? 0 : r_beat_cnt + 1;
            r_outstanding <= r_outstanding + int'(ar_hs) - int'(r_hs && s_axi.rlast);

            // ---- write ----
            if (aw_hs) w_len_q <= s_axi.awlen;
            if (w_hs)  w_beat_cnt <= s_axi.wlast ? 0 : w_beat_cnt + 1;
            aw_pending <= aw_pending + int'(aw_hs)                - int'(b_hs);
            w_pending  <= w_pending  + int'(w_hs && s_axi.wlast)  - int'(b_hs);
        end
    end

    // =========================================================
    // 3. 공통 property
    // =========================================================
    // VALID가 올라가면 READY 받을 때까지 유지
    property p_valid_hold(valid, ready);
        valid && !ready |=> valid;
    endproperty

    // READY 기다리는 동안 payload 변경 금지
    property p_payload_stable(valid, ready, payload);
        valid && !ready |=> $stable(payload);
    endproperty

    // =========================================================
    // 4. VALID 유지 (5개 채널)
    // =========================================================
    AW_VALID_HOLD : assert property (p_valid_hold(s_axi.awvalid, s_axi.awready))
        else `uvm_error("AXI_CHK", "AWVALID dropped before AWREADY")
    W_VALID_HOLD  : assert property (p_valid_hold(s_axi.wvalid,  s_axi.wready))
        else `uvm_error("AXI_CHK", "WVALID dropped before WREADY")
    B_VALID_HOLD  : assert property (p_valid_hold(s_axi.bvalid,  s_axi.bready))
        else `uvm_error("AXI_CHK", "BVALID dropped before BREADY")
    AR_VALID_HOLD : assert property (p_valid_hold(s_axi.arvalid, s_axi.arready))
        else `uvm_error("AXI_CHK", "ARVALID dropped before ARREADY")
    R_VALID_HOLD  : assert property (p_valid_hold(s_axi.rvalid,  s_axi.rready))
        else `uvm_error("AXI_CHK", "RVALID dropped before RREADY")

    // =========================================================
    // 5. payload 안정성 (5개 채널)
    // =========================================================
    // AW, AR : awid/arid는 아직 driver가 구동하지 않음
    //          → ID를 clocking block에 추가할 때 payload에 함께 추가
    AW_STABLE : assert property (p_payload_stable(s_axi.awvalid, s_axi.awready,
                    {s_axi.awaddr, s_axi.awlen, s_axi.awsize, s_axi.awburst}))
        else `uvm_error("AXI_CHK", "AW payload changed while waiting")

    W_STABLE  : assert property (p_payload_stable(s_axi.wvalid, s_axi.wready,
                    {s_axi.wdata, s_axi.wstrb, s_axi.wlast}))          // wstrb 추가
        else `uvm_error("AXI_CHK", "W payload changed while waiting")

    B_STABLE  : assert property (p_payload_stable(s_axi.bvalid, s_axi.bready,
                    {s_axi.bid, s_axi.bresp}))                          // bid 추가
        else `uvm_error("AXI_CHK", "B payload changed while waiting")

    AR_STABLE : assert property (p_payload_stable(s_axi.arvalid, s_axi.arready,
                    {s_axi.araddr, s_axi.arlen, s_axi.arsize, s_axi.arburst}))
        else `uvm_error("AXI_CHK", "AR payload changed while waiting")

    R_STABLE  : assert property (p_payload_stable(s_axi.rvalid, s_axi.rready,
                    {s_axi.rid, s_axi.rdata, s_axi.rresp, s_axi.rlast}))  // rid 추가
        else `uvm_error("AXI_CHK", "R payload changed while waiting")

    // =========================================================
    // 6. LAST 위치 검사 (single이든 burst든 마지막 beat에서만 1)
    //    handshake 시점에만 검사 → valid=0일 때의 rlast 값은 보지 않음
    // =========================================================
    R_LAST_CHK : assert property (r_hs |-> (s_axi.rlast == (r_beat_cnt == r_len_q)))
        else `uvm_error("AXI_CHK", $sformatf("RLAST wrong: beat=%0d, arlen=%0d, rlast=%0b",
                                             r_beat_cnt, r_len_q, s_axi.rlast))
    W_LAST_CHK : assert property (w_hs |-> (s_axi.wlast == (w_beat_cnt == w_len_q)))
        else `uvm_error("AXI_CHK", $sformatf("WLAST wrong: beat=%0d, awlen=%0d, wlast=%0b",
                                             w_beat_cnt, w_len_q, s_axi.wlast))

    // =========================================================
    // 7. 채널 간 의존성
    // =========================================================
    // R은 AR handshake가 끝난 뒤에만 나올 수 있음
    R_AFTER_AR : assert property (s_axi.rvalid |-> (r_outstanding > 0))
        else `uvm_error("AXI_CHK", "RVALID asserted without accepted AR")

    // B는 AW handshake + 마지막 W handshake가 모두 끝난 뒤에만
    B_AFTER_AW_W : assert property (s_axi.bvalid |-> (aw_pending > 0 && w_pending > 0))
        else `uvm_error("AXI_CHK", "BVALID asserted before AW and last W completed")

    // =========================================================
    // 8. 응답이 실제로 오는지 (일정 시간 안에)
    // =========================================================
    B_RESP_COMES : assert property (w_hs && s_axi.wlast |-> ##[1:MAX_WAIT] b_hs)
        else `uvm_error("AXI_CHK", "No B handshake after last W")
    R_DONE_COMES : assert property (ar_hs |-> ##[1:MAX_WAIT] (r_hs && s_axi.rlast))
        else `uvm_error("AXI_CHK", "Read burst did not complete after AR")

endmodule