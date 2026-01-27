// ============================================================
// Testbench: ethernet_frame_parser_stress_tb
// Purpose  : AXI-correct stress test for ethernet_frame_parser
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module ethernet_frame_parser_stress_tb;

  localparam int DATA_WIDTH = 64;
  localparam int NUM_FRAMES = 50;

  // ----------------------------------------------------------
  // Clock / Reset
  // ----------------------------------------------------------
  logic clk;
  logic rst_n;
  always #5 clk = ~clk;

  // ----------------------------------------------------------
  // AXI4-Stream input
  // ----------------------------------------------------------
  logic [DATA_WIDTH-1:0] s_axis_tdata;
  logic                  s_axis_tvalid;
  logic                  s_axis_tready;
  logic                  s_axis_tlast;

  // ----------------------------------------------------------
  // AXI4-Stream output
  // ----------------------------------------------------------
  logic [DATA_WIDTH-1:0] m_axis_tdata;
  logic                  m_axis_tvalid;
  logic                  m_axis_tready;
  logic                  m_axis_tlast;

  // ----------------------------------------------------------
  // Metadata
  // ----------------------------------------------------------
  eth_metadata_t         m_axis_tuser;
  logic                  m_axis_tuser_valid;

  // Pulse-safe latch
  logic metadata_seen;

  // ----------------------------------------------------------
  // DUT
  // ----------------------------------------------------------
  ethernet_frame_parser #(
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk                (clk),
    .rst_n              (rst_n),

    .s_axis_tdata       (s_axis_tdata),
    .s_axis_tvalid      (s_axis_tvalid),
    .s_axis_tready      (s_axis_tready),
    .s_axis_tlast       (s_axis_tlast),

    .m_axis_tdata       (m_axis_tdata),
    .m_axis_tvalid      (m_axis_tvalid),
    .m_axis_tready      (m_axis_tready),
    .m_axis_tlast       (m_axis_tlast),

    .m_axis_tuser       (m_axis_tuser),
    .m_axis_tuser_valid (m_axis_tuser_valid)
  );

  // ----------------------------------------------------------
  // Metadata pulse capture
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      metadata_seen <= 1'b0;
    else if (m_axis_tuser_valid)
      metadata_seen <= 1'b1;
  end

  // ----------------------------------------------------------
  // AXI helper: send one beat (HARD CORRECT)
  // ----------------------------------------------------------
  task automatic axi_send_beat(
    input logic [63:0] data,
    input logic        last
  );
  begin
    s_axis_tdata  = data;
    s_axis_tlast  = last;
    s_axis_tvalid = 1'b1;

    // HOLD until accepted
    while (!s_axis_tready)
      @(posedge clk);

    @(posedge clk); // accept cycle

    s_axis_tvalid = 1'b0;
    s_axis_tlast  = 1'b0;
    s_axis_tdata  = '0;
  end
  endtask

  // ----------------------------------------------------------
  // Test sequence
  // ----------------------------------------------------------
  integer f;
  integer timeout;

  initial begin
    // Init
    clk = 0;
    rst_n = 0;

    s_axis_tdata  = '0;
    s_axis_tvalid = 0;
    s_axis_tlast  = 0;
    m_axis_tready = 1;

    repeat (5) @(posedge clk);
    rst_n = 1;

    $display("=== Ethernet Frame Parser STRESS TEST ===");

    for (f = 0; f < NUM_FRAMES; f++) begin
      metadata_seen = 0;

      // --------------------------------------------------
      // Beat 0: Dest MAC FF:FF:FF:FF:FF:FF + 00 11
      // --------------------------------------------------
      axi_send_beat(64'h0011FFFFFFFFFFFF, 1'b0);

      // --------------------------------------------------
      // Beat 1: Src MAC 22:33:44:55 + Ethertype 08 00
      // --------------------------------------------------
      axi_send_beat(64'h0000080055443322, 1'b0);

      // --------------------------------------------------
      // Beat 2: Payload + LAST
      // --------------------------------------------------
      axi_send_beat(64'h0000FFEEDDCCBBAA, 1'b1);

      // --------------------------------------------------
      // Wait for metadata (bounded)
      // --------------------------------------------------
      timeout = 0;
      while (!metadata_seen && timeout < 2000) begin
        @(posedge clk);
        timeout++;
      end

      if (!metadata_seen)
        $fatal(1, "TIMEOUT: metadata never observed for frame %0d", f);

      // --------------------------------------------------
      // Validate metadata
      // --------------------------------------------------
      if (m_axis_tuser.dest_mac !== 48'hFFFFFFFFFFFF)
        $fatal(1, "METADATA ERROR: dest_mac mismatch");

      if (m_axis_tuser.src_mac !== 48'h001122334455)
        $fatal(1, "METADATA ERROR: src_mac mismatch");

      if (!m_axis_tuser.is_ipv4)
        $fatal(1, "METADATA ERROR: IPv4 not detected");
    end

    $display("✔ STRESS TEST PASSED (%0d frames)", NUM_FRAMES);
    $finish;
  end

endmodule
