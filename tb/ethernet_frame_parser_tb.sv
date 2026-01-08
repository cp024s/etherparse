// ============================================================
// Testbench: ethernet_frame_parser_tb
// Compatible with Icarus Verilog (-g2012)
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module ethernet_frame_parser_tb;

  // ----------------------------------------------------------
  // Parameters
  // ----------------------------------------------------------
  localparam int DATA_WIDTH = 64;
  localparam int CLK_PERIOD = 10;

  // ----------------------------------------------------------
  // Clock & reset
  // ----------------------------------------------------------
  logic clk;
  logic rst_n;

  always #(CLK_PERIOD/2) clk = ~clk;

  // ----------------------------------------------------------
  // AXI Stream signals
  // ----------------------------------------------------------
  logic [DATA_WIDTH-1:0] s_axis_tdata;
  logic                  s_axis_tvalid;
  logic                  s_axis_tready;
  logic                  s_axis_tlast;

  logic [DATA_WIDTH-1:0] m_axis_tdata;
  logic                  m_axis_tvalid;
  logic                  m_axis_tready;
  logic                  m_axis_tlast;

  eth_metadata_t         m_axis_tuser;
  logic                  m_axis_tuser_valid;

  // ----------------------------------------------------------
  // DUT
  // ----------------------------------------------------------
  ethernet_frame_parser #(
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
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

  // ----------------------------------------------------------
  // Tasks
  // ----------------------------------------------------------

  task send_beat(
    input logic [DATA_WIDTH-1:0] data,
    input logic last
  );
    begin
      s_axis_tdata  = data;
      s_axis_tvalid = 1'b1;
      s_axis_tlast  = last;

      // Wait until DUT accepts the beat
      while (!s_axis_tready)
        @(posedge clk);

      @(posedge clk);

      s_axis_tvalid = 1'b0;
      s_axis_tlast  = 1'b0;
      s_axis_tdata  = '0;
    end
  endtask

  task send_frame(
    input byte frame [0:255],
    input int  length
  );
    int i;
    int b;
    logic [DATA_WIDTH-1:0] beat;
    begin
      i = 0;
      while (i < length) begin
        beat = '0;
        for (b = 0; b < DATA_WIDTH/8; b = b + 1) begin
          if (i < length) begin
            beat[b*8 +: 8] = frame[i];
            i = i + 1;
          end
        end
        send_beat(beat, (i >= length));
      end
    end
  endtask

  // ----------------------------------------------------------
  // Test frames (STATIC ARRAYS — Icarus safe)
  // ----------------------------------------------------------

  byte ipv4_frame [0:255];
  int  ipv4_len;

  byte vlan_frame [0:255];
  int  vlan_len;

  // ----------------------------------------------------------
  // Test sequence
  // ----------------------------------------------------------

  initial begin
    // Init
    clk = 1'b0;
    rst_n = 1'b0;
    s_axis_tvalid = 1'b0;
    s_axis_tlast  = 1'b0;
    s_axis_tdata  = '0;
    m_axis_tready = 1'b1;

    // Reset
    repeat (5) @(posedge clk);
    rst_n = 1'b1;

    // ------------------------------------------------------
    // Test 1: Non-VLAN IPv4 frame
    // ------------------------------------------------------
    $display("=== Test 1: Non-VLAN IPv4 frame ===");

    ipv4_len = 18;

    ipv4_frame[0]  = 8'hFF;
    ipv4_frame[1]  = 8'hFF;
    ipv4_frame[2]  = 8'hFF;
    ipv4_frame[3]  = 8'hFF;
    ipv4_frame[4]  = 8'hFF;
    ipv4_frame[5]  = 8'hFF;
    ipv4_frame[6]  = 8'h00;
    ipv4_frame[7]  = 8'h11;
    ipv4_frame[8]  = 8'h22;
    ipv4_frame[9]  = 8'h33;
    ipv4_frame[10] = 8'h44;
    ipv4_frame[11] = 8'h55;
    ipv4_frame[12] = 8'h08;
    ipv4_frame[13] = 8'h00;
    ipv4_frame[14] = 8'hDE;
    ipv4_frame[15] = 8'hAD;
    ipv4_frame[16] = 8'hBE;
    ipv4_frame[17] = 8'hEF;

    send_frame(ipv4_frame, ipv4_len);

    wait (m_axis_tuser_valid);

    if (!m_axis_tuser.is_ipv4)
      $fatal("ERROR: IPv4 not detected");

    if (m_axis_tuser.vlan_present)
      $fatal("ERROR: Unexpected VLAN detected");

    $display("✔ Non-VLAN IPv4 frame passed");

    // ------------------------------------------------------
    // Test 2: VLAN IPv4 frame
    // ------------------------------------------------------
    $display("=== Test 2: VLAN IPv4 frame ===");

    vlan_len = 22;

    vlan_frame[0]  = 8'hAA;
    vlan_frame[1]  = 8'hBB;
    vlan_frame[2]  = 8'hCC;
    vlan_frame[3]  = 8'hDD;
    vlan_frame[4]  = 8'hEE;
    vlan_frame[5]  = 8'hFF;
    vlan_frame[6]  = 8'h10;
    vlan_frame[7]  = 8'h20;
    vlan_frame[8]  = 8'h30;
    vlan_frame[9]  = 8'h40;
    vlan_frame[10] = 8'h50;
    vlan_frame[11] = 8'h60;
    vlan_frame[12] = 8'h81;
    vlan_frame[13] = 8'h00;
    vlan_frame[14] = 8'h00;
    vlan_frame[15] = 8'h05; // VLAN ID = 5
    vlan_frame[16] = 8'h08;
    vlan_frame[17] = 8'h00;
    vlan_frame[18] = 8'hCA;
    vlan_frame[19] = 8'hFE;
    vlan_frame[20] = 8'hBA;
    vlan_frame[21] = 8'hBE;

    send_frame(vlan_frame, vlan_len);

    wait (m_axis_tuser_valid);

    if (!m_axis_tuser.vlan_present)
      $fatal("ERROR: VLAN not detected");

    if (m_axis_tuser.vlan_id != 12'd5)
      $fatal("ERROR: VLAN ID mismatch");

    if (!m_axis_tuser.is_ipv4)
      $fatal("ERROR: IPv4 not detected in VLAN frame");

    $display("✔ VLAN IPv4 frame passed");

    // ------------------------------------------------------
    // Done
    // ------------------------------------------------------
    $display("=== All Ethernet parser tests PASSED ===");
    #50;
    $finish;
  end

endmodule
