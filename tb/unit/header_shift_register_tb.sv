// ============================================================
// Testbench: header_shift_register_tb
// Purpose  : Unit test for Ethernet header byte capture
// ============================================================

`timescale 1ns/1ps

module header_shift_register_tb;

  localparam int DATA_WIDTH = 64;

  // Clock / Reset
  logic clk;
  logic rst_n;

  always #5 clk = ~clk;

  // DUT inputs
  logic                  beat_accept;
  logic                  frame_start;
  logic [DATA_WIDTH-1:0] axis_tdata;

  // DUT outputs
  logic [17:0][7:0]      header_bytes;
  logic                 header_valid;

  // DUT
  header_shift_register #(
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .beat_accept  (beat_accept),
    .frame_start  (frame_start),
    .axis_tdata   (axis_tdata),
    .header_bytes (header_bytes),
    .header_valid (header_valid)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    beat_accept = 0;
    frame_start = 0;
    axis_tdata  = '0;

    repeat (3) @(posedge clk);
    rst_n = 1;

    $display("=== header_shift_register UNIT TEST ===");

    // Start frame
    frame_start = 1;
    @(posedge clk);
    frame_start = 0;

    // Beat 0
    axis_tdata = 64'h00_11_22_33_44_55_66_77;
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;

    // Beat 1
    axis_tdata = 64'h88_99_AA_BB_08_00_CC_DD;
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;

    // Beat 2
    axis_tdata = 64'hEE_FF_11_22_33_44_55_66;
    beat_accept = 1;
    @(posedge clk);
    beat_accept = 0;

    @(posedge clk);

    if (!header_valid)
      $fatal(1, "FAIL: header_valid not asserted");

    if (header_bytes[0]  !== 8'h00) $fatal(1, "Byte 0 mismatch");
    if (header_bytes[1]  !== 8'h11) $fatal(1, "Byte 1 mismatch");
    if (header_bytes[2]  !== 8'h22) $fatal(1, "Byte 2 mismatch");
    if (header_bytes[3]  !== 8'h33) $fatal(1, "Byte 3 mismatch");
    if (header_bytes[4]  !== 8'h44) $fatal(1, "Byte 4 mismatch");
    if (header_bytes[5]  !== 8'h55) $fatal(1, "Byte 5 mismatch");

    if (header_bytes[6]  !== 8'h66) $fatal(1, "Byte 6 mismatch");
    if (header_bytes[7]  !== 8'h77) $fatal(1, "Byte 7 mismatch");

    if (header_bytes[8]  !== 8'h88) $fatal(1, "Byte 8 mismatch");
    if (header_bytes[9]  !== 8'h99) $fatal(1, "Byte 9 mismatch");
    if (header_bytes[10] !== 8'hAA) $fatal(1, "Byte 10 mismatch");
    if (header_bytes[11] !== 8'hBB) $fatal(1, "Byte 11 mismatch");

    if (header_bytes[12] !== 8'h08) $fatal(1, "Ethertype MSB mismatch");
    if (header_bytes[13] !== 8'h00) $fatal(1, "Ethertype LSB mismatch");

    $display("✔ header_shift_register UNIT TEST PASSED");
    $finish;
  end

endmodule
