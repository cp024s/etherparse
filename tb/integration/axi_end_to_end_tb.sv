// ============================================================
// AXI End-to-End Sanity Testbench
// Compatible with Icarus + Vivado
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module axi_end_to_end_tb;

  localparam int DATA_WIDTH = 8;

  // ----------------------------------------------------------
  // Clock / Reset
  // ----------------------------------------------------------
  logic clk;
  logic rst_n;

  initial clk = 0;
  always #5 clk = ~clk;   // 100 MHz

  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  // ----------------------------------------------------------
  // AXI signals
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
  ethernet_frame_parser dut (
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
  // AXI Source (TX)
  // ----------------------------------------------------------
  task automatic axi_send_frame(input byte unsigned frame[]);
    int i;
    int beats;
    logic [DATA_WIDTH-1:0] beat;

    beats = (frame.size() + 7) / 8;

    for (i = 0; i < beats; i++) begin
      beat = '0;
      for (int b = 0; b < 8; b++) begin
        if ((i*8 + b) < frame.size())
          beat[8*b +: 8] = frame[i*8 + b];
      end

      @(posedge clk);
      s_axis_tdata  <= beat;
      s_axis_tvalid <= 1'b1;
      s_axis_tlast  <= (i == beats-1);

      wait (s_axis_tready);
      $display("[%0t] TX: data=%h last=%b", $time, beat, s_axis_tlast);
    end

    @(posedge clk);
    s_axis_tvalid <= 0;
    s_axis_tlast  <= 0;
  endtask

  // ----------------------------------------------------------
  // AXI Sink (RX)
  // ----------------------------------------------------------
  initial begin
    m_axis_tready = 1'b1;

    // Introduce backpressure later
    forever begin
      @(posedge clk);
      if ($time > 200) begin
        m_axis_tready <= ($urandom_range(0,3) != 0);
      end
    end
  end

  always @(posedge clk) begin
    if (m_axis_tvalid && m_axis_tready) begin
      $display("[%0t] RX: data=%h last=%b",
               $time, m_axis_tdata, m_axis_tlast);
      if (m_axis_tlast)
        $display("---- RX FRAME END ----");
    end
  end

  // ----------------------------------------------------------
  // Metadata Monitor
  // ----------------------------------------------------------
  always @(posedge clk) begin
    if (m_axis_tuser_valid) begin
      $display("[%0t] METADATA: ethertype=%h vlan=%b",
               $time,
               m_axis_tuser.ethertype,
               m_axis_tuser.vlan_present);
    end
  end

  // ----------------------------------------------------------
  // Test Sequence
  // ----------------------------------------------------------
  initial begin
    byte unsigned frame[];

    // Wait for reset
    wait (rst_n);

    // Ethernet frame (dest MAC + src MAC + ethertype IPv4)
    frame = '{
      8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,
      8'h00,8'h11,8'h22,8'h33,8'h44,8'h55,
      8'h08,8'h00,        // IPv4
      8'hDE,8'hAD,8'hBE,8'hEF
    };

    $display("=== Sending frame ===");
    axi_send_frame(frame);

    repeat (50) @(posedge clk);
    $display("=== TEST DONE ===");
    $finish;
  end

endmodule
