`timescale 1ns / 1ps

module mac_1g_rgmii_wrapper (
    input  wire        clk_125mhz,
    input  wire        rst,

    // ============================================================
    // RGMII PHY Interface
    // ============================================================
    input  wire        rgmii_rx_clk,
    input  wire [3:0]  rgmii_rxd,
    input  wire        rgmii_rx_ctl,

    output wire        rgmii_tx_clk,
    output wire [3:0]  rgmii_txd,
    output wire        rgmii_tx_ctl,
    output wire        phy_reset_n,

    // ============================================================
    // AXI Stream RX (to parser)
    // ============================================================
    output wire [7:0]  rx_axis_tdata,
    output wire        rx_axis_tvalid,
    input  wire        rx_axis_tready,
    output wire        rx_axis_tlast,
    output wire        rx_axis_tuser
);

    // ============================================================
    // PHY Reset (simple hold-low on reset)
    // ============================================================

    assign phy_reset_n = ~rst;

    // ============================================================
    // Internal AXI signals
    // ============================================================

    wire [7:0]  tx_axis_tdata  = 8'd0;
    wire        tx_axis_tvalid = 1'b0;
    wire        tx_axis_tlast  = 1'b0;
    wire        tx_axis_tuser  = 1'b0;
    wire        tx_axis_tready;

    // ============================================================
    // MAC Instance
    // ============================================================

    eth_mac_1g_rgmii_fifo #(
        .ENABLE_PADDING(1),
        .MIN_FRAME_LENGTH(64)
    )
    u_mac (
        // Clocking
        .rx_clk(rgmii_rx_clk),
        .rx_rst(rst),
        .tx_clk(clk_125mhz),
        .tx_rst(rst),
        .logic_clk(clk_125mhz),
        .logic_rst(rst),

        // AXI TX (unused for now)
        .tx_axis_tdata(tx_axis_tdata),
        .tx_axis_tvalid(tx_axis_tvalid),
        .tx_axis_tready(tx_axis_tready),
        .tx_axis_tlast(tx_axis_tlast),
        .tx_axis_tuser(tx_axis_tuser),

        // AXI RX (to parser)
        .rx_axis_tdata(rx_axis_tdata),
        .rx_axis_tvalid(rx_axis_tvalid),
        .rx_axis_tready(rx_axis_tready),
        .rx_axis_tlast(rx_axis_tlast),
        .rx_axis_tuser(rx_axis_tuser),

        // RGMII PHY interface
        .rgmii_rx_clk(rgmii_rx_clk),
        .rgmii_rxd(rgmii_rxd),
        .rgmii_rx_ctl(rgmii_rx_ctl),

        .rgmii_tx_clk(rgmii_tx_clk),
        .rgmii_txd(rgmii_txd),
        .rgmii_tx_ctl(rgmii_tx_ctl)
    );

endmodule
