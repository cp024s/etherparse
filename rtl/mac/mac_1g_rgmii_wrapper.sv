`timescale 1ns / 1ps

module mac_1g_rgmii_wrapper
(
    input  wire        clk_125mhz,
    input  wire        rst,

    /*
     * AXI Stream TX (from your parser or upstream logic)
     */
    input  wire [7:0]  tx_axis_tdata,
    input  wire        tx_axis_tvalid,
    input  wire        tx_axis_tlast,
    input  wire        tx_axis_tuser,
    output wire        tx_axis_tready,

    /*
     * AXI Stream RX (to your parser)
     */
    output wire [7:0]  rx_axis_tdata,
    output wire        rx_axis_tvalid,
    output wire        rx_axis_tlast,
    output wire        rx_axis_tuser,
    input  wire        rx_axis_tready,

    /*
     * RGMII PHY interface
     */
    input  wire        rgmii_rx_clk,
    input  wire [3:0]  rgmii_rxd,
    input  wire        rgmii_rx_ctl,

    output wire        rgmii_tx_clk,
    output wire [3:0]  rgmii_txd,
    output wire        rgmii_tx_ctl,

    output wire [1:0]  speed
);

    eth_mac_1g_rgmii_fifo #(
        .TARGET("XILINX"),
        .IODDR_STYLE("IODDR"),
        .CLOCK_INPUT_STYLE("BUFG"),
        .USE_CLK90("TRUE"),
        .AXIS_DATA_WIDTH(8)
    )
    u_mac (
        /*
         * Clocks & resets
         */
        .gtx_clk        (clk_125mhz),
        .gtx_clk90      (clk_125mhz),   // TEMP: no phase shift yet
        .gtx_rst        (rst),
        .logic_clk      (clk_125mhz),
        .logic_rst      (rst),

        /*
         * AXI TX
         */
        .tx_axis_tdata  (tx_axis_tdata),
        .tx_axis_tkeep  (1'b1),
        .tx_axis_tvalid (tx_axis_tvalid),
        .tx_axis_tready (tx_axis_tready),
        .tx_axis_tlast  (tx_axis_tlast),
        .tx_axis_tuser  (tx_axis_tuser),

        /*
         * AXI RX
         */
        .rx_axis_tdata  (rx_axis_tdata),
        .rx_axis_tkeep  (),
        .rx_axis_tvalid (rx_axis_tvalid),
        .rx_axis_tready (rx_axis_tready),
        .rx_axis_tlast  (rx_axis_tlast),
        .rx_axis_tuser  (rx_axis_tuser),

        /*
         * RGMII
         */
        .rgmii_rx_clk   (rgmii_rx_clk),
        .rgmii_rxd      (rgmii_rxd),
        .rgmii_rx_ctl   (rgmii_rx_ctl),
        .rgmii_tx_clk   (rgmii_tx_clk),
        .rgmii_txd      (rgmii_txd),
        .rgmii_tx_ctl   (rgmii_tx_ctl),

        /*
         * Status
         */
        .tx_error_underflow (),
        .tx_fifo_overflow   (),
        .tx_fifo_bad_frame  (),
        .tx_fifo_good_frame (),
        .rx_error_bad_frame (),
        .rx_error_bad_fcs   (),
        .rx_fifo_overflow   (),
        .rx_fifo_bad_frame  (),
        .rx_fifo_good_frame (),
        .speed              (speed),

        /*
         * Config
         */
        .cfg_ifg        (8'd12),
        .cfg_tx_enable  (1'b1),
        .cfg_rx_enable  (1'b1)
    );

endmodule