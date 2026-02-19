`timescale 1ns/1ps

// ============================================================
// AXI Header Done + Payload Integration Testbench
// ============================================================

module axi_header_done_payload_tb;

  localparam int DATA_WIDTH = 8;

  // ==========================================================
  // Clock / Reset
  // ==========================================================
  logic clk;
  logic rst_n;

  initial clk = 0;
  always #5 clk = ~clk; // 100MHz

  initial begin
    rst_n = 0;
    #50;
    rst_n = 1;
  end

  // ==========================================================
  // AXI signals
  // ==========================================================
  logic [DATA_WIDTH-1:0] s_axis_tdata;
  logic                 s_axis_tvalid;
  logic                 s_axis_tready;
  logic                 s_axis_tlast;

  logic [DATA_WIDTH-1:0] m_axis_tdata;
  logic                 m_axis_tvalid;
  logic                 m_axis_tready;
  logic                 m_axis_tlast;

  // Metadata
  eth_metadata_t        m_axis_tuser;
  logic                 m_axis_tuser_valid;

  // Always ready on RX
  assign m_axis_tready = 1'b1;

  // ==========================================================
  // DUT
  // ==========================================================
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

  // ==========================================================
  // Runtime parser invariants (CRITICAL)
  // ==========================================================
  parser_runtime_checks u_checks (
    .clk         (clk),
    .rst_n       (rst_n),

    .s_tvalid    (m_axis_tvalid),
    .s_tready    (m_axis_tready),
    .s_tlast     (m_axis_tlast),

    .frame_start (dut.frame_start),
    .frame_end   (dut.frame_end),
    .header_done (dut.header_done),

    .meta_valid  (m_axis_tuser_valid)
  );

  // ==========================================================
  // Metadata visibility (DEBUG ONLY)
  // ==========================================================
  always @(posedge clk) begin
    if (m_axis_tuser_valid) begin
      $display(
        "[META] dst=%h src=%h ethertype=%h vlan=%0d ipv4=%0d",
        m_axis_tuser.dest_mac,
        m_axis_tuser.src_mac,
        m_axis_tuser.ethertype,
        m_axis_tuser.vlan_id,
        m_axis_tuser.is_ipv4
      );
    end
  end

  // ==========================================================
  // AXI RX monitor
  // ==========================================================
  always @(posedge clk) begin
    if (m_axis_tvalid && m_axis_tready) begin
      $display(
        "[RX] data=%h last=%0d",
        m_axis_tdata,
        m_axis_tlast
      );
      if (m_axis_tlast)
        $display("---- RX FRAME END ----");
    end
  end

  // ==========================================================
  // Stimulus
  // ==========================================================
  initial begin
    s_axis_tdata  = '0;
    s_axis_tvalid = 0;
    s_axis_tlast  = 0;

    wait(rst_n);
    @(posedge clk);

    $display("=== Sending header + payload frame ===");

    send_beat(64'h1122334455667788, 0);
    send_beat(64'h99aabbccddeeff00, 0);
    send_beat(64'h0800450000000000, 0); // Ethertype = IPv4
    send_beat(64'hdeadbeefdeadbeef, 0);
    send_beat(64'hcafebabecafebabe, 1);

    #200;
    $display("=== TEST DONE ===");
    $finish;
  end

  // ==========================================================
  // AXI helper task
  // ==========================================================
  task send_beat(input logic [63:0] data, input logic last);
    begin
      @(posedge clk);
      s_axis_tdata  <= data;
      s_axis_tvalid <= 1'b1;
      s_axis_tlast  <= last;

      while (!s_axis_tready)
        @(posedge clk);

      @(posedge clk);
      s_axis_tvalid <= 1'b0;
      s_axis_tlast  <= 1'b0;
    end
  endtask
  
endmodule

// ============================================================
// Include runtime assertions LAST (global scope)
// ============================================================
//`include "tb/assertions/parser_runtime_checks.sv"
