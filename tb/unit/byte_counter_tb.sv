// ============================================================
// Testbench: byte_counter_tb
// Purpose  : Unit test for byte_counter
// ============================================================

`timescale 1ns/1ps

module byte_counter_tb;

  localparam int DATA_WIDTH   = 64;
  localparam int HEADER_BYTES = 18;
  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;

  logic clk;
  logic rst_n;

  logic beat_accept;
  logic frame_start;
  logic header_done;

  always #5 clk = ~clk;

  byte_counter #(
    .DATA_WIDTH(DATA_WIDTH),
    .HEADER_BYTES(HEADER_BYTES)
  ) dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .beat_accept (beat_accept),
    .frame_start (frame_start),
    .header_done (header_done)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    beat_accept = 0;
    frame_start = 0;

    repeat (3) @(posedge clk);
    rst_n = 1;

    $display("=== byte_counter UNIT TEST ===");

    // Start frame
    frame_start = 1;
    @(posedge clk);
    frame_start = 0;

    // Beat 1 → 8 bytes
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;

    if (header_done)
      $fatal(1, "FAIL: header_done asserted too early");

    // Beat 2 → 16 bytes
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;

    if (header_done)
      $fatal(1, "FAIL: header_done asserted too early");

    // Beat 3 → 24 bytes (>= 18)
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;

    if (!header_done)
      $fatal(1, "FAIL: header_done not asserted at threshold");

    // Additional beats must not change state
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;

    if (!header_done)
      $fatal(1, "FAIL: header_done deasserted unexpectedly");

    $display("✔ byte_counter UNIT TEST PASSED");
    $finish;
  end

endmodule
