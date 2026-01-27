// ============================================================
// Testbench: axis_ingress_tb
// Purpose  : Unit test for axis_ingress (pass-through)
// ============================================================

`timescale 1ns/1ps

module axis_ingress_tb;

  localparam int DATA_WIDTH = 64;
  localparam int USER_WIDTH = 1;

  logic clk;
  logic rst_n;

  // External side
  logic [DATA_WIDTH-1:0] s_tdata;
  logic                  s_tvalid;
  logic                  s_tready;
  logic                  s_tlast;
  logic [USER_WIDTH-1:0] s_tuser;

  // Internal side
  logic [DATA_WIDTH-1:0] m_tdata;
  logic                  m_tvalid;
  logic                  m_tready;
  logic                  m_tlast;
  logic [USER_WIDTH-1:0] m_tuser;

  always #5 clk = ~clk;

  axis_ingress #(
    .DATA_WIDTH(DATA_WIDTH),
    .USER_WIDTH(USER_WIDTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .s_tdata(s_tdata),
    .s_tvalid(s_tvalid),
    .s_tready(s_tready),
    .s_tlast(s_tlast),
    .s_tuser(s_tuser),
    .m_tdata(m_tdata),
    .m_tvalid(m_tvalid),
    .m_tready(m_tready),
    .m_tlast(m_tlast),
    .m_tuser(m_tuser)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    s_tdata = '0;
    s_tvalid = 0;
    s_tlast = 0;
    s_tuser = 0;
    m_tready = 0;

    repeat (3) @(posedge clk);
    rst_n = 1;

    $display("=== axis_ingress UNIT TEST ===");

    // Apply backpressure
    m_tready = 0;
    s_tdata  = 64'h1122334455667788;
    s_tvalid = 1;
    s_tlast  = 1;

    @(posedge clk);
    if (s_tready !== 0)
      $fatal(1, "FAIL: s_tready should follow m_tready");

    // Release backpressure
    m_tready = 1;
    @(posedge clk);

    if (!m_tvalid)
      $fatal(1, "FAIL: m_tvalid not propagated");

    if (m_tdata !== s_tdata)
      $fatal(1, "FAIL: data mismatch");

    if (!m_tlast)
      $fatal(1, "FAIL: tlast not propagated");

    // Complete transfer
    s_tvalid = 0;
    @(posedge clk);

    $display("✔ axis_ingress UNIT TEST PASSED");
    $finish;
  end

endmodule
