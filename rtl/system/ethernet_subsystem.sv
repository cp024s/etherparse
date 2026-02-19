`timescale 1ns / 1ps

module ethernet_subsystem (
    // ============================================================
    // Clock / Reset
    // ============================================================
    input  wire        clk_125mhz,
    input  wire        rst,

    // ============================================================
    // RGMII PHY
    // ============================================================
    input  wire        rgmii_rx_clk,
    input  wire [3:0]  rgmii_rxd,
    input  wire        rgmii_rx_ctl,

    output wire        rgmii_tx_clk,
    output wire [3:0]  rgmii_txd,
    output wire        rgmii_tx_ctl,
    output wire        phy_reset_n,

    // ============================================================
    // Parser Output (for debug / future logic)
    // ============================================================
    output wire        parser_valid,
    output wire        parser_last,
    output wire        parser_meta_valid
);

    // ============================================================
    // MAC → Parser AXIS wires
    // ============================================================

    wire [7:0] mac_rx_tdata;
    wire       mac_rx_tvalid;
    wire       mac_rx_tready;
    wire       mac_rx_tlast;
    wire       mac_rx_tuser;

    // ============================================================
    // MAC Wrapper
    // ============================================================

    mac_1g_rgmii_wrapper u_mac (
        .clk_125mhz(clk_125mhz),
        .rst(rst),

        .rgmii_rx_clk(rgmii_rx_clk),
        .rgmii_rxd(rgmii_rxd),
        .rgmii_rx_ctl(rgmii_rx_ctl),

        .rgmii_tx_clk(rgmii_tx_clk),
        .rgmii_txd(rgmii_txd),
        .rgmii_tx_ctl(rgmii_tx_ctl),

        .phy_reset_n(phy_reset_n),

        .m_axis_rx_tdata(mac_rx_tdata),
        .m_axis_rx_tvalid(mac_rx_tvalid),
        .m_axis_rx_tready(mac_rx_tready),
        .m_axis_rx_tlast(mac_rx_tlast),
        .m_axis_rx_tuser(mac_rx_tuser)
    );

    // ============================================================
    // Parser Outputs
    // ============================================================

    wire [7:0] parser_tdata;
    wire       parser_tvalid;
    wire       parser_tlast;
    wire       parser_tuser_valid;

    // ============================================================
    // Ethernet Parser (8-bit mode)
    // ============================================================

    ethernet_frame_parser #(
        .DATA_WIDTH(8),
        .USER_WIDTH(1)
    )
    u_parser (
        .clk(clk_125mhz),
        .rst(rst),

        .s_axis_tdata(mac_rx_tdata),
        .s_axis_tvalid(mac_rx_tvalid),
        .s_axis_tready(mac_rx_tready),
        .s_axis_tlast(mac_rx_tlast),

        .m_axis_tdata(parser_tdata),
        .m_axis_tvalid(parser_tvalid),
        .m_axis_tready(1'b1),
        .m_axis_tlast(parser_tlast),

        .m_axis_tuser(),
        .m_axis_tuser_valid(parser_tuser_valid)
    );

    // ============================================================
    // Expose debug signals upward
    // ============================================================

    assign parser_valid      = parser_tvalid;
    assign parser_last       = parser_tlast;
    assign parser_meta_valid = parser_tuser_valid;

endmodule
