`timescale 1ns / 1ps

module top_ax7203 (
    // ============================================================
    // 200 MHz Differential Clock (Board Input)
    // ============================================================
    input  wire sys_clk_p,
    input  wire sys_clk_n,

    // Active-low reset
    input  wire rst_n,

    // ============================================================
    // RGMII PHY Interface (1G Ethernet)
    // ============================================================
    input  wire        rgmii_rx_clk,
    input  wire [3:0]  rgmii_rxd,
    input  wire        rgmii_rx_ctl,

    output wire        rgmii_tx_clk,
    output wire [3:0]  rgmii_txd,
    output wire        rgmii_tx_ctl,
    output wire        phy_reset_n,

    // LEDs
    output wire [3:0]  led
);

    // ============================================================
    // Clock Buffer
    // ============================================================

    wire clk_200;

    IBUFDS #(
        .DIFF_TERM("TRUE"),
        .IBUF_LOW_PWR("FALSE")
    )
    u_ibufds (
        .I  (sys_clk_p),
        .IB (sys_clk_n),
        .O  (clk_200)
    );

    // TEMPORARY clock routing (you WILL replace with MMCM later)
    wire clk_125;
    wire clk_125_90;
    wire clk_locked;

    clk_wiz_0 u_clk_wiz (
        .clk_in1  (clk_200),
        .clk_out1 (clk_125),
        .clk_out2 (clk_125_90),
        .locked   (clk_locked)
    );

    // ============================================================
    // Reset Synchronization
    // ============================================================

    reg [3:0] rst_sync;

    always @(posedge clk_125 or negedge rst_n) begin
        if (!rst_n || !clk_locked)
            rst_sync <= 4'b1111;
        else
            rst_sync <= {rst_sync[2:0], 1'b0};
    end

    wire rst = rst_sync[3];

    // ============================================================
    // Drive PHY Reset (FIXED)
    // ============================================================

    assign phy_reset_n = ~rst;

    // ============================================================
    // Ethernet Subsystem
    // ============================================================

    wire parser_valid;
    wire parser_last;
    wire parser_meta_valid;

    ethernet_subsystem u_eth_sys (
        .clk_125     (clk_125),
        .clk_125_90  (clk_125_90),
        .rst(rst),

        .rgmii_rx_clk(rgmii_rx_clk),
        .rgmii_rxd(rgmii_rxd),
        .rgmii_rx_ctl(rgmii_rx_ctl),

        .rgmii_tx_clk(rgmii_tx_clk),
        .rgmii_txd(rgmii_txd),
        .rgmii_tx_ctl(rgmii_tx_ctl),

        .parser_valid(parser_valid),
        .parser_last(parser_last),
        .parser_meta_valid(parser_meta_valid)
    );

    // ============================================================
    // LED Debug
    // ============================================================

    assign led[0] = ~rgmii_rx_ctl;
    assign led[1] = ~rgmii_rxd[0];
    assign led[2] = ~rgmii_rxd[1];
    assign led[3] = ~rgmii_rx_clk;
    // ============================================================
    // ILA TEMPORARILY DISABLED (FIXED)
    // ============================================================

    /*
    ila_0 u_ila (
        .clk    (clk_125mhz),
        .probe0 (parser_valid),
        .probe1 (parser_last),
        .probe2 (parser_meta_valid),
        .probe3 (rgmii_rx_ctl),
        .probe4 (rgmii_rxd)
    );
    */

endmodule