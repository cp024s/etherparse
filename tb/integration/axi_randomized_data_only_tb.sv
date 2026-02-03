`timescale 1ns/1ps

module axi_randomized_data_only_tb;

  // ============================================================
  // Clock / Reset
  // ============================================================
  logic clk;
  logic rst_n;

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  // ============================================================
  // AXI Signals
  // ============================================================
  logic [63:0] s_axis_tdata;
  logic        s_axis_tvalid;
  logic        s_axis_tready;
  logic        s_axis_tlast;

  logic [63:0] m_axis_tdata;
  logic        m_axis_tvalid;
  logic        m_axis_tready;
  logic        m_axis_tlast;

  // ============================================================
  // DUT
  // ============================================================
  ethernet_frame_parser dut (
    .clk           (clk),
    .rst_n         (rst_n),

    .s_axis_tdata  (s_axis_tdata),
    .s_axis_tvalid (s_axis_tvalid),
    .s_axis_tready (s_axis_tready),
    .s_axis_tlast  (s_axis_tlast),

    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tready (m_axis_tready),
    .m_axis_tlast  (m_axis_tlast),

    .m_axis_tuser       (),
    .m_axis_tuser_valid ()
  );

  // ============================================================
  // Simple scoreboards (fixed-size arrays)
  // ============================================================
  byte tx_mem [0:4095];
  byte rx_mem [0:4095];

  int tx_ptr;
  int rx_ptr;
  int frames_tx;
  int frames_rx;

  // ============================================================
  // Backpressure
  // ============================================================
  always @(posedge clk) begin
    if (!rst_n)
      m_axis_tready <= 0;
    else
      m_axis_tready <= ($urandom_range(0,3) != 0);
  end

  always @(posedge clk) begin
    if (m_axis_tvalid && m_axis_tready) begin
      rx_mem[rx_ptr++] = m_axis_tdata[7:0];
      if (m_axis_tlast)
        frames_rx++;
    end
  end

  // ============================================================
  // AXI send task (legal protocol)
  // ============================================================
  task send_frame(input int length);
    int i;
    for (i = 0; i < length; i++) begin
      @(posedge clk);
      s_axis_tdata  <= $urandom;
      s_axis_tvalid <= 1;
      s_axis_tlast  <= (i == length-1);

      wait (s_axis_tready);

      tx_mem[tx_ptr++] = s_axis_tdata[7:0];
    end

    @(posedge clk);
    s_axis_tvalid <= 0;
    s_axis_tlast  <= 0;
    frames_tx++;
  endtask

  // ============================================================
  // Test
  // ============================================================
  initial begin
    s_axis_tvalid = 0;
    s_axis_tdata  = 0;
    s_axis_tlast  = 0;

    tx_ptr = 0;
    rx_ptr = 0;
    frames_tx = 0;
    frames_rx = 0;

    wait (rst_n);

    repeat (20) begin
      send_frame($urandom_range(64,256));
      repeat ($urandom_range(1,10)) @(posedge clk);
    end

    wait (frames_rx == frames_tx);
    repeat (10) @(posedge clk);

    // ==========================================================
    // Checks
    // ==========================================================
    if (tx_ptr != rx_ptr)
      $fatal(1, "BYTE COUNT MISMATCH tx=%0d rx=%0d", tx_ptr, rx_ptr);

    for (int i = 0; i < tx_ptr; i++) begin
      if (tx_mem[i] !== rx_mem[i])
        $fatal(1, "DATA MISMATCH @%0d tx=%02x rx=%02x",
               i, tx_mem[i], rx_mem[i]);
    end

    $display("====================================");
    $display(" AXI RANDOM DATA TEST PASSED (IVERILOG)");
    $display(" Frames: %0d  Bytes: %0d", frames_tx, tx_ptr);
    $display("====================================");

    $finish;
  end

endmodule
