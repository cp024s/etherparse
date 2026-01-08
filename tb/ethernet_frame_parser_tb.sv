// ============================================================
// Testbench: ethernet_frame_parser_tb
// Fully Icarus-compatible
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module ethernet_frame_parser_tb;

  localparam int DATA_WIDTH = 64;
  localparam int CLK_PERIOD = 10;

  logic clk;
  logic rst_n;

  always #(CLK_PERIOD/2) clk = ~clk;

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

  byte frame_buf [0:255];
  int  frame_len;

  task send_beat(
    input logic [DATA_WIDTH-1:0] data,
    input logic last
  );
    begin
      s_axis_tdata  = data;
      s_axis_tvalid = 1'b1;
      s_axis_tlast  = last;

      while (!s_axis_tready)
        @(posedge clk);

      @(posedge clk);

      s_axis_tvalid = 1'b0;
      s_axis_tlast  = 1'b0;
      s_axis_tdata  = '0;
    end
  endtask

  task send_frame;
    int i;
    int b;
    logic [DATA_WIDTH-1:0] beat;
    begin
      i = 0;
      while (i < frame_len) begin
        beat = '0;
        for (b = 0; b < DATA_WIDTH/8; b = b + 1) begin
          if (i < frame_len) begin
            beat[b*8 +: 8] = frame_buf[i];
            i = i + 1;
          end
        end
        send_beat(beat, (i >= frame_len));
      end
    end
  endtask

  initial begin
    clk = 0;
    rst_n = 0;
    s_axis_tvalid = 0;
    s_axis_tlast  = 0;
    s_axis_tdata  = '0;
    m_axis_tready = 1;

    repeat (5) @(posedge clk);
    rst_n = 1;

    // ===============================
    // Test 1: Non-VLAN IPv4
    // ===============================
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
    wait (m_axis_tuser_valid);

    if (!m_axis_tuser.is_ipv4) begin
      $display("ERROR: IPv4 not detected");
      $finish(1);
    end
    if (m_axis_tuser.vlan_present) begin
      $display("ERROR: Unexpected VLAN detected");
      $finish(1);
    end

    $display("✔ Non-VLAN IPv4 frame passed");

    // ===============================
    // Test 2: VLAN IPv4
    // ===============================
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
    wait (m_axis_tuser_valid);

    if (!m_axis_tuser.vlan_present) begin
      $display("ERROR: VLAN not detected");
      $finish(1);
    end
    if (m_axis_tuser.vlan_id != 12'd5) begin
      $display("ERROR: VLAN ID mismatch");
      $finish(1);
    end
    if (!m_axis_tuser.is_ipv4) begin
      $display("ERROR: IPv4 not detected in VLAN frame");
      $finish(1);
    end

    $display("✔ VLAN IPv4 frame passed");
    $display("=== ALL TESTS PASSED ===");
    #50;
    $finish;
  end

endmodule
