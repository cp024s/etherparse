`timescale 1ns/1ps
import eth_parser_pkg::*;

module axi_randomized_end_to_end_tb;

  // ============================================================
  // Clock / Reset
  // ============================================================
  logic clk;
  logic rst_n;

  always #5 clk = ~clk;

  initial begin
    clk   = 0;
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  // ============================================================
  // AXI Stream Signals
  // ============================================================
  logic [63:0] s_axis_tdata;
  logic        s_axis_tvalid;
  logic        s_axis_tready;
  logic        s_axis_tlast;

  logic [63:0] m_axis_tdata;
  logic        m_axis_tvalid;
  logic        m_axis_tready;
  logic        m_axis_tlast;

  eth_metadata_t m_axis_tuser;
  logic          m_axis_tuser_valid;

  // ============================================================
  // DUT
  // ============================================================
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

  // ============================================================
  // Scoreboards
  // ============================================================
  byte unsigned tx_bytes[$];
  byte unsigned rx_bytes[$];

  int tx_frames;
  int rx_frames;
  int metadata_frames;

  // ============================================================
  // Randomized AXI Sink (Backpressure)
  // ============================================================
  always @(posedge clk) begin
    if (!rst_n)
      m_axis_tready <= 0;
    else
      m_axis_tready <= ($urandom_range(0, 3) != 0); // ~75% ready
  end

  always @(posedge clk) begin
    if (m_axis_tvalid && m_axis_tready) begin
      rx_bytes.push_back(m_axis_tdata[7:0]);
      if (m_axis_tlast)
        rx_frames++;
    end
  end

  always @(posedge clk) begin
    if (m_axis_tuser_valid)
      metadata_frames++;
  end

  // ============================================================
  // AXI Source Task (STRICT PROTOCOL)
  // ============================================================
  task automatic axi_send_frame(input byte unsigned frame[]);
    int i;

    for (i = 0; i < frame.size(); i++) begin
      @(posedge clk);
      s_axis_tdata  <= frame[i];
      s_axis_tvalid <= 1'b1;
      s_axis_tlast  <= (i == frame.size()-1);

      wait (s_axis_tready);
    end

    @(posedge clk);
    s_axis_tvalid <= 0;
    s_axis_tlast  <= 0;

    tx_frames++;
  endtask

  // ============================================================
  // Random Frame Generator
  // ============================================================
  function automatic byte unsigned rand_byte();
    return $urandom_range(0,255);
  endfunction

  task automatic gen_random_frame(
    output byte unsigned frame[]
  );
    int len;
    int i;

    // Minimum Ethernet header = 14 bytes
    // Payload randomized
    len = $urandom_range(64, 256);

    frame = new[len];

    // Dest MAC
    for (i = 0; i < 6; i++)
      frame[i] = rand_byte();

    // Src MAC
    for (i = 6; i < 12; i++)
      frame[i] = rand_byte();

    // Ethertype (IPv4)
    frame[12] = 8'h08;
    frame[13] = 8'h00;

    // Payload
    for (i = 14; i < len; i++)
      frame[i] = rand_byte();
  endtask

  // ============================================================
  // Test Sequence
  // ============================================================
  initial begin
    s_axis_tdata  = 0;
    s_axis_tvalid = 0;
    s_axis_tlast  = 0;

    tx_frames       = 0;
    rx_frames       = 0;
    metadata_frames = 0;

    wait (rst_n);

    // ----------------------------------------------------------
    // RANDOMIZED STRESS
    // ----------------------------------------------------------
    int NUM_FRAMES = 50;
    byte unsigned frame[];

    repeat (NUM_FRAMES) begin
      gen_random_frame(frame);

      foreach (frame[i])
        tx_bytes.push_back(frame[i]);

      axi_send_frame(frame);

      // Random inter-frame gap
      repeat ($urandom_range(1,10)) @(posedge clk);
    end

    // ----------------------------------------------------------
    // Wait for RX to finish
    // ----------------------------------------------------------
    wait (rx_frames == tx_frames);
    repeat (20) @(posedge clk);

    // ==========================================================
    // SCOREBOARD CHECKS
    // ==========================================================
    if (tx_bytes.size() != rx_bytes.size())
      $fatal("BYTE COUNT MISMATCH: tx=%0d rx=%0d",
             tx_bytes.size(), rx_bytes.size());

    foreach (tx_bytes[i]) begin
      if (tx_bytes[i] !== rx_bytes[i])
        $fatal("DATA MISMATCH at byte %0d: tx=%02x rx=%02x",
               i, tx_bytes[i], rx_bytes[i]);
    end

    if (metadata_frames != tx_frames)
      $fatal("METADATA ERROR: frames=%0d metadata=%0d",
             tx_frames, metadata_frames);

    $display("========================================");
    $display(" RANDOMIZED AXI END-TO-END PASSED");
    $display(" Frames        : %0d", tx_frames);
    $display(" Bytes         : %0d", tx_bytes.size());
    $display(" Metadata emits: %0d", metadata_frames);
    $display("========================================");

    $finish;
  end

endmodule
