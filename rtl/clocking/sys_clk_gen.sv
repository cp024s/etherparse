module sys_clk_gen (
  input  logic sys_clk_p,
  input  logic sys_clk_n,
  input  logic rst_n,
  output logic clk_100m,
  output logic locked
);

  logic sys_clk_ibuf;

  // Differential clock buffer
  IBUFDS #(
    .DIFF_TERM("TRUE"),
    .IBUF_LOW_PWR("FALSE")
  ) u_ibufds (
    .I (sys_clk_p),
    .IB(sys_clk_n),
    .O (sys_clk_ibuf)
  );

  // MMCM: 200 MHz → 100 MHz
  MMCME2_BASE #(
    .CLKFBOUT_MULT_F(5.0),   // 200 * 5 = 1000
    .CLKOUT0_DIVIDE_F(10.0), // 1000 / 10 = 100
    .CLKIN1_PERIOD(5.0)
  ) u_mmcm (
    .CLKIN1   (sys_clk_ibuf),
    .CLKFBIN  (),
    .CLKFBOUT (),
    .CLKOUT0  (clk_100m),
    .LOCKED   (locked),
    .RST      (~rst_n)
  );

endmodule
