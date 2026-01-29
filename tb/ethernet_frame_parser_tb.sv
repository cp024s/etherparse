// ============================================================
// Testbench: ethernet_frame_parser_tb
// Purpose  : Validate ethernet_frame_parser (Icarus-safe)
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module ethernet_frame_parser_tb;

  // Clock / Reset
  logic clk;
  logic rst_n;
  always #5 clk = ~clk;

  // AXI input
  logic [63:0] s_axis_tdata;
  logic        s_axis_tvalid;
  logic        s_axis_tready;
  logic        s_axis_tlast;

  // AXI output
  logic [63:0] m_axis_tdata;
  logic        m_axis_tvalid;
  logic        m_axis_tready;
  logic        m_axis_tlast;

  // Metadata
  eth_metadata_t m_axis_tuser;
  logic          m_axis_tuser_valid;

  // DUT
  ethernet_frame_parser dut (
    .clk               (clk),
    .rst_n             (rst_n),
    .s_axis_tdata      (s_axis_tdata),
    .s_axis_tvalid     (s_axis_tvalid),
    .s_axis_tready     (s_axis_tready),
    .s_axis_tlast      (s_axis_tlast),
    .m_axis_tdata      (m_axis_tdata),
    .m_axis_tvalid     (m_axis_tvalid),
    .m_axis_tready     (m_axis_tready),
    .m_axis_tlast      (m_axis_tlast),
    .m_axis_tuser      (m_axis_tuser),
    .m_axis_tuser_valid(m_axis_tuser_valid)
  );

  int wait_cycles;
  bit metadata_seen;

  initial begin
    clk = 0;
    rst_n = 0;

    s_axis_tvalid = 0;
    s_axis_tlast  = 0;
    s_axis_tdata  = 64'd0;
    m_axis_tready = 1'b1;

    repeat (3) @(posedge clk);
    rst_n = 1;

    // ======================================================
    // TEST 1: Non-VLAN IPv4 frame
    // ======================================================
    $display("=== Test 1: Non-VLAN IPv4 frame ===");

    // Beat 0
    s_axis_tvalid = 1'b1;
    s_axis_tdata  = 64'hFFFFFFFFFFFF0011;
    @(posedge clk);

    // Beat 1
    s_axis_tdata = 64'h2233445508000000;
    @(posedge clk);

    // Beat 2 (TLAST)
    s_axis_tdata = 64'h0000000000000000;
    s_axis_tlast = 1'b1;
    @(posedge clk);

    s_axis_tvalid = 0;
    s_axis_tlast  = 0;

    // ------------------------------------------------------
    // Wait for metadata_valid (bounded, no break)
    // ------------------------------------------------------
    metadata_seen = 0;
    for (wait_cycles = 0; wait_cycles < 20; wait_cycles++) begin
      @(posedge clk);
      if (m_axis_tuser_valid)
        metadata_seen = 1;
    end

    if (!metadata_seen)
      $fatal(1, "ERROR: metadata_valid never asserted");

    // ------------------------------------------------------
    // Checks
    // ------------------------------------------------------
    if (m_axis_tuser.dest_mac !== 48'hFFFFFFFFFFFF)
      $fatal(1, "FAIL: dest_mac mismatch");

    if (m_axis_tuser.src_mac !== 48'h001122334455)
      $fatal(1, "FAIL: src_mac mismatch");

    if (m_axis_tuser.ethertype !== 16'h0800)
      $fatal(1, "FAIL: ethertype mismatch");

    if (!m_axis_tuser.is_ipv4)
      $fatal(1, "FAIL: IPv4 not detected");

    if (m_axis_tuser.vlan_present)
      $fatal(1, "FAIL: VLAN incorrectly detected");

    $display("✔ Test 1 PASSED");
    $display("=== ALL TESTS PASSED ===");

    #20;
    $finish;
  end

endmodule
