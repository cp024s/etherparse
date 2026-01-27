// ============================================================
// Testbench: frame_control_fsm_tb
// Purpose  : Unit test for frame_control_fsm (Moore FSM aware)
// ============================================================

`timescale 1ns/1ps

module frame_control_fsm_tb;

  logic clk;
  logic rst_n;

  // Inputs
  logic beat_accept;
  logic tlast;
  logic header_done;

  // Outputs
  logic frame_start;
  logic frame_end;
  logic in_header;
  logic in_payload;

  always #5 clk = ~clk;

  frame_control_fsm dut (
    .clk(clk),
    .rst_n(rst_n),
    .beat_accept(beat_accept),
    .tlast(tlast),
    .header_done(header_done),
    .frame_start(frame_start),
    .frame_end(frame_end),
    .in_header(in_header),
    .in_payload(in_payload)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    beat_accept = 0;
    tlast = 0;
    header_done = 0;

    repeat (3) @(posedge clk);
    rst_n = 1;

    $display("=== frame_control_fsm UNIT TEST ===");

    // --------------------------------------------------
    // Start frame (IDLE -> HEADER)
    // --------------------------------------------------
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;

    if (!frame_start)
      $fatal(1, "FAIL: frame_start not asserted on first beat");

    // FSM enters HEADER on NEXT cycle
    @(posedge clk);
    if (!in_header)
      $fatal(1, "FAIL: not in HEADER state after frame start");

    // --------------------------------------------------
    // Header continues
    // --------------------------------------------------
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;

    @(posedge clk);
    if (!in_header)
      $fatal(1, "FAIL: HEADER state lost too early");

    // --------------------------------------------------
    // Header completes (HEADER -> PAYLOAD)
    // --------------------------------------------------
    header_done = 1;
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;
    header_done = 0;

    @(posedge clk);
    if (!in_payload)
      $fatal(1, "FAIL: did not transition to PAYLOAD");

    // --------------------------------------------------
    // Payload continues
    // --------------------------------------------------
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;

    @(posedge clk);
    if (!in_payload)
      $fatal(1, "FAIL: PAYLOAD state lost unexpectedly");

    // --------------------------------------------------
    // End frame (PAYLOAD -> IDLE)
    // --------------------------------------------------
    tlast = 1;
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;
    tlast = 0;

    if (!frame_end)
      $fatal(1, "FAIL: frame_end not asserted on tlast");

    @(posedge clk);
    if (in_header || in_payload)
      $fatal(1, "FAIL: FSM did not return to IDLE");

    $display("✔ frame_control_fsm UNIT TEST PASSED");
    $finish;
  end

endmodule
