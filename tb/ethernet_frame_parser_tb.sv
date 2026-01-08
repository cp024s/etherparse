// ============================================================
// Testbench: ethernet_frame_parser_tb
// FINAL – AXI-correct + assertion-driven debug
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
  // Frame buffer
  // ----------------------------------------------------------
  byte frame_buf [0:255];
  int  frame_len;

  // ----------------------------------------------------------
  // AXI-CORRECT send_beat task
  // ----------------------------------------------------------
  task send_beat(
    input logic [DATA_WIDTH-1:0] data,
    input logic last
  );
    begin
      s_axis_tdata  <= data;
      s_axis_tlast  <= last;
      s_axis_tvalid <= 1'b1;

      // Hold VALID until handshake completes
      do begin
        @(posedge clk);
      end while (!(s_axis_tvalid && s_axis_tready));

      // Deassert after successful transfer
      s_axis_tvalid <= 1'b0;
      s_axis_tlast  <= 1'b0;
      s_axis_tdata  <= '0;

      // One-cycle gap
      @(posedge clk);
    end
  endtask

  // ----------------------------------------------------------
  // Send entire frame
  // ----------------------------------------------------------
  task send_frame;
    int i;
    int b;
    logic [DATA_WIDTH-1:0] beat;
    begin
      i = 0;
      while (i < frame_len) begin
        beat = '0;
        for (b = 0; b < DATA_WIDTH/8; b++) begin
          if (i < frame_len) begin
            beat[b*8 +: 8] = frame_buf[i];
            i++;
          end
        end
        send_beat(beat, (i >= frame_len));
      end
    end
  endtask

  // ----------------------------------------------------------
  // Wait for metadata with timeout
  // ----------------------------------------------------------
  task wait_for_metadata;
    int timeout;
    begin
      timeout = 0;
      while (!m_axis_tuser_valid && timeout < 2000) begin
        @(posedge clk);
        timeout++;
      end

      if (!m_axis_tuser_valid) begin
        $display("ERROR: metadata_valid never asserted");
        $display("DEBUG:");
        $display("  beat_accept  = %0d", dut.beat_accept);
        $display("  byte_count   = %0d", dut.byte_count);
        $display("  header_done  = %0d", dut.header_done);
        $display("  header_valid = %0d", dut.header_valid);
        $display("  fields_valid = %0d", dut.fields_valid);
        $display("  vlan_valid   = %0d", dut.vlan_valid);
        $display("  proto_valid  = %0d", dut.proto_valid);
        $finish(1);
      end
    end
  endtask

  // ----------------------------------------------------------
  // Forward progress assertion
  // ----------------------------------------------------------
  int progress_ctr;

  always @(posedge clk) begin
    if (!rst_n) begin
      progress_ctr <= 0;
    end
    else begin
      if (dut.beat_accept)
        progress_ctr <= 0;
      else
        progress_ctr <= progress_ctr + 1;

      if (progress_ctr > 50) begin
        $fatal(1,
          "PIPELINE STALL: no beat_accept for 50 cycles (AXI deadlock)");
      end
    end
  end

  // ----------------------------------------------------------
  // Test sequence
  // ----------------------------------------------------------
  initial begin
    // Init
    clk = 0;
    rst_n = 0;
    s_axis_tvalid = 0;
    s_axis_tlast  = 0;
    s_axis_tdata  = '0;
    m_axis_tready = 1'b1; // Always ready

    // Reset
    repeat (5) @(posedge clk);
    rst_n = 1;

    // ======================================================
    // TEST 1: Non-VLAN IPv4
    // ======================================================
    $display("=== Test 1: Non-VLAN IPv4 frame ===");

    frame_len = 18;
    frame_buf[0]=8'hFF; frame_buf[1]=8'hFF; frame_buf[2]=8'hFF;
    frame_buf[3]=8'hFF; frame_buf[4]=8'hFF; frame_buf[5]=8'hFF;
    frame_buf[6]=8'h00; frame_buf[7]=8'h11; frame_buf[8]=8'h22;
    frame_buf[9]=8'h33; frame_buf[10]=8'h44; frame_buf[11]=8'h55;
    frame_buf[12]=8'h08; frame_buf[13]=8'h00;
    frame_buf[14]=8'hDE; frame_buf[15]=8'hAD;
    frame_buf[16]=8'hBE; frame_buf[17]=8'hEF;

    send_frame();
    wait_for_metadata();

    if (!m_axis_tuser.is_ipv4)
      $fatal(1, "IPv4 not detected");

    if (m_axis_tuser.vlan_present)
      $fatal(1, "Unexpected VLAN detected");

    $display("✔ Non-VLAN IPv4 frame passed");

    // ======================================================
    // TEST 2: VLAN IPv4
    // ======================================================
    $display("=== Test 2: VLAN IPv4 frame ===");

    frame_len = 22;
    frame_buf[0]=8'hAA; frame_buf[1]=8'hBB; frame_buf[2]=8'hCC;
    frame_buf[3]=8'hDD; frame_buf[4]=8'hEE; frame_buf[5]=8'hFF;
    frame_buf[6]=8'h10; frame_buf[7]=8'h20; frame_buf[8]=8'h30;
    frame_buf[9]=8'h40; frame_buf[10]=8'h50; frame_buf[11]=8'h60;
    frame_buf[12]=8'h81; frame_buf[13]=8'h00;
    frame_buf[14]=8'h00; frame_buf[15]=8'h05;
    frame_buf[16]=8'h08; frame_buf[17]=8'h00;
    frame_buf[18]=8'hCA; frame_buf[19]=8'hFE;
    frame_buf[20]=8'hBA; frame_buf[21]=8'hBE;

    send_frame();
    wait_for_metadata();

    if (!m_axis_tuser.vlan_present)
      $fatal(1, "VLAN not detected");

    if (m_axis_tuser.vlan_id != 12'd5)
      $fatal(1, "VLAN ID mismatch");

    if (!m_axis_tuser.is_ipv4)
      $fatal(1, "IPv4 not detected in VLAN frame");

    $display("✔ VLAN IPv4 frame passed");

    // ======================================================
    $display("=== ALL TESTS PASSED ===");
    #20;
    $finish;
  end

endmodule
