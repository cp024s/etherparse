// ============================================================
// Testbench: ethernet_frame_parser_tb
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module ethernet_frame_parser_tb;

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
    .clk              (clk),
    .rst_n            (rst_n),
    .s_axis_tdata     (s_axis_tdata),
    .s_axis_tvalid    (s_axis_tvalid),
    .s_axis_tready    (s_axis_tready),
    .s_axis_tlast     (s_axis_tlast),
    .m_axis_tdata     (m_axis_tdata),
    .m_axis_tvalid    (m_axis_tvalid),
    .m_axis_tready    (m_axis_tready),
    .m_axis_tlast     (m_axis_tlast),
    .m_axis_tuser     (m_axis_tuser),
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

      wait (s_axis_tready);
      @(posedge clk);

      s_axis_tvalid = 1'b0;
      s_axis_tlast  = 1'b0;
    end
  endtask

  task send_frame(input byte frame_bytes[], input int length);
    int i;
    logic [DATA_WIDTH-1:0] beat;
    begin
      i = 0;
      while (i < length) begin
        beat = '0;
        for (int b = 0; b < DATA_WIDTH/8; b++) begin
          if (i < length)
            beat[b*8 +: 8] = frame_bytes[i++];
        end
        send_beat(beat, (i >= length));
      end
    end
  endtask

  // ----------------------------------------------------------
  // Test sequence
  // ----------------------------------------------------------

  initial begin
    clk = 0;
    rst_n = 0;
    s_axis_tvalid = 0;
    s_axis_tlast  = 0;
    m_axis_tready = 1;

    repeat (5) @(posedge clk);
    rst_n = 1;

    $display("=== Test 1: Non-VLAN IPv4 frame ===");

    byte ipv4_frame[] = '{
      // Dest MAC
      8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,
      // Src MAC
      8'h00,8'h11,8'h22,8'h33,8'h44,8'h55,
      // EtherType IPv4
      8'h08,8'h00,
      // Payload (dummy)
      8'hDE,8'hAD,8'hBE,8'hEF
    };

    send_frame(ipv4_frame, ipv4_frame.size());

    wait (m_axis_tuser_valid);
    assert(m_axis_tuser.is_ipv4) else $fatal("IPv4 not detected");
    assert(!m_axis_tuser.vlan_present) else $fatal("Unexpected VLAN");

    $display("✔ Non-VLAN IPv4 passed");

    $display("=== Test 2: VLAN IPv4 frame ===");

    byte vlan_frame[] = '{
      // Dest MAC
      8'hAA,8'hBB,8'hCC,8'hDD,8'hEE,8'hFF,
      // Src MAC
      8'h10,8'h20,8'h30,8'h40,8'h50,8'h60,
      // TPID
      8'h81,8'h00,
      // TCI (VID=5)
      8'h00,8'h05,
      // EtherType IPv4
      8'h08,8'h00,
      // Payload
      8'hCA,8'hFE,8'hBA,8'hBE
    };

    send_frame(vlan_frame, vlan_frame.size());

    wait (m_axis_tuser_valid);
    assert(m_axis_tuser.vlan_present) else $fatal("VLAN not detected");
    assert(m_axis_tuser.vlan_id == 12'd5) else $fatal("Wrong VLAN ID");
    assert(m_axis_tuser.is_ipv4) else $fatal("IPv4 not detected");

    $display("✔ VLAN IPv4 passed");

    $display("=== All tests completed successfully ===");
    #100;
    $finish;
  end

endmodule
