// ============================================================
// Testbench: ethernet_frame_parser_stress_tb
// Purpose  : REAL AXI stress test with scoreboard
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module ethernet_frame_parser_stress_tb;

  localparam int DATA_WIDTH = 64;
  localparam int NUM_FRAMES = 50;
  localparam int MAX_BEATS  = 3;

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

  logic metadata_seen;

  // ----------------------------------------------------------
  // Scoreboard queues
  // ----------------------------------------------------------
  logic [DATA_WIDTH-1:0] expected_q [$];
  logic [DATA_WIDTH-1:0] observed_q [$];

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
  // Randomized backpressure (THIS IS STRESS)
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      m_axis_tready <= 1'b0;
    else
      m_axis_tready <= $urandom_range(0,1);
  end

  // ----------------------------------------------------------
  // Capture output beats
  // ----------------------------------------------------------
  always_ff @(posedge clk) begin
    if (m_axis_tvalid && m_axis_tready) begin
      observed_q.push_back(m_axis_tdata);
    end
  end

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
  // AXI helper: send one beat
  // ----------------------------------------------------------
  task automatic axi_send_beat(
    input logic [63:0] data,
    input logic        last
  );
  begin
    s_axis_tdata  = data;
    s_axis_tlast  = last;
    s_axis_tvalid = 1'b1;

    while (!s_axis_tready)
      @(posedge clk);

    @(posedge clk);

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
  integer beat;

  initial begin
    clk = 0;
    rst_n = 0;

    s_axis_tdata  = '0;
    s_axis_tvalid = 0;
    s_axis_tlast  = 0;

    repeat (5) @(posedge clk);
    rst_n = 1;

    $display("=== Ethernet Frame Parser REAL STRESS TEST ===");

    for (f = 0; f < NUM_FRAMES; f++) begin
      metadata_seen = 0;

      // Frame beats with SEQUENCE TAGGING
      for (beat = 0; beat < MAX_BEATS; beat++) begin
        logic last;
        logic [63:0] payload;

        last = (beat == MAX_BEATS-1);
        payload = {16'(f), 16'(beat), 32'hCAFEBABE};

        expected_q.push_back(payload);
        axi_send_beat(payload, last);

        // random gap
        repeat ($urandom_range(0,3)) @(posedge clk);
      end

      // Wait for metadata
      timeout = 0;
      while (!metadata_seen && timeout < 2000) begin
        @(posedge clk);
        timeout++;
      end

      if (!metadata_seen)
        $fatal(1, "TIMEOUT: metadata never observed for frame %0d", f);
    end

    // ------------------------------------------------------
    // Final scoreboard check
    // ------------------------------------------------------
    if (expected_q.size() != observed_q.size()) begin
      $fatal(1,
        "SCOREBOARD SIZE MISMATCH: expected %0d, got %0d",
        expected_q.size(), observed_q.size()
      );
    end

    for (int i = 0; i < expected_q.size(); i++) begin
      if (expected_q[i] !== observed_q[i]) begin
        $fatal(1,
          "DATA MISMATCH @%0d exp=%h got=%h",
          i, expected_q[i], observed_q[i]
        );
      end
    end

    $display("✔ REAL STRESS TEST PASSED (%0d frames)", NUM_FRAMES);
    $finish;
  end

endmodule
