`timescale 1ns/1ps

module axi_header_done_tb;

  localparam int DATA_WIDTH = 8;
  localparam int CLK_PERIOD = 10;

  // =========================================================
  // Clock / Reset
  // =========================================================
  logic clk;
  logic rst_n;

  initial clk = 0;
  always #(CLK_PERIOD/2) clk = ~clk;

  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  // =========================================================
  // AXI signals
  // =========================================================
  logic [DATA_WIDTH-1:0] s_tdata;
  logic                  s_tvalid;
  logic                  s_tready;
  logic                  s_tlast;

  logic [DATA_WIDTH-1:0] m_tdata;
  logic                  m_tvalid;
  logic                  m_tready;
  logic                  m_tlast;

  // Metadata
  eth_parser_pkg::eth_metadata_t m_tuser;
  logic                          m_tuser_valid;

  // =========================================================
  // DUT
  // =========================================================
  ethernet_frame_parser #(
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk                (clk),
    .rst_n              (rst_n),

    .s_axis_tdata       (s_tdata),
    .s_axis_tvalid      (s_tvalid),
    .s_axis_tready      (s_tready),
    .s_axis_tlast       (s_tlast),

    .m_axis_tdata       (m_tdata),
    .m_axis_tvalid      (m_tvalid),
    .m_axis_tready      (m_tready),
    .m_axis_tlast       (m_tlast),

    .m_axis_tuser       (m_tuser),
    .m_axis_tuser_valid (m_tuser_valid)
  );

  // =========================================================
  // AXI sink always ready (for now)
  // =========================================================
  initial m_tready = 1'b1;

  // =========================================================
  // AXI send task
  // =========================================================
  task send_beat(input logic [DATA_WIDTH-1:0] data,
                 input logic last);
    begin
      @(posedge clk);
      s_tdata  <= data;
      s_tvalid <= 1'b1;
      s_tlast  <= last;

      while (!s_tready)
        @(posedge clk);

      @(posedge clk);
      s_tvalid <= 1'b0;
      s_tlast  <= 1'b0;
      s_tdata  <= '0;
    end
  endtask

  // =========================================================
  // RX monitor
  // =========================================================
  always @(posedge clk) begin
    if (m_tvalid && m_tready) begin
      $display("[%0t] RX: data=%h last=%b",
               $time, m_tdata, m_tlast);
      if (m_tlast)
        $display("---- RX FRAME END ----");
    end

    if (m_tuser_valid) begin
      $display("[%0t] METADATA:",
               $time);
      $display("  dest_mac  = %h", m_tuser.dest_mac);
      $display("  src_mac   = %h", m_tuser.src_mac);
      $display("  ethertype = %h", m_tuser.ethertype);
      $display("  ipv4=%0b ipv6=%0b arp=%0b unknown=%0b",
               m_tuser.is_ipv4,
               m_tuser.is_ipv6,
               m_tuser.is_arp,
               m_tuser.is_unknown);
    end
  end

  // =========================================================
  // TEST SEQUENCE
  // =========================================================
  initial begin
    // Init
    s_tdata  = '0;
    s_tvalid = 0;
    s_tlast  = 0;

    @(posedge rst_n);
    repeat (2) @(posedge clk);

    $display("=== Sending multi-beat Ethernet frame ===");

    // Beat 0: Dest MAC [47:0] + Src MAC [15:0]
    send_beat(64'h112233445566_AABB, 0);

    // Beat 1: Src MAC [31:16] + Ethertype 0x0800 (IPv4)
    send_beat(64'hCCDDEEFF_0800_0000, 0);

    // Beat 2: Payload
    send_beat(64'hDEADBEEFCAFEBABE, 1);

    repeat (20) @(posedge clk);

    $display("=== TEST DONE ===");
    $finish;
  end

endmodule
