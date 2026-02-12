`timescale 1ns / 1ps

module top_ax7203 (
    // Differential clock
    input  wire sys_clk_p,
    input  wire sys_clk_n,

    // Active-low reset
    input  wire rst_n,

    // LEDs
    output wire [3:0] led
);

    // ============================================================
    // Clock buffer
    // ============================================================

    wire clk;

    IBUFDS #(
        .DIFF_TERM("TRUE"),
        .IBUF_LOW_PWR("FALSE")
    ) u_ibufds (
        .I  (sys_clk_p),
        .IB (sys_clk_n),
        .O  (clk)
    );

    // ============================================================
    // Reset sync (active-high internal)
    // ============================================================

    reg [3:0] rst_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rst_sync <= 4'b1111;
        else
            rst_sync <= {rst_sync[2:0], 1'b0};
    end

    wire rst = rst_sync[3];

    // ============================================================
    // Simple AXI test generator (64-bit)
    // ============================================================

    reg  [63:0] tdata;
    reg         tvalid;
    reg         tlast;
    wire        tready;

    reg [7:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 8'd0;
            tvalid  <= 1'b0;
            tlast   <= 1'b0;
            tdata   <= 64'd0;
        end else begin
            tvalid <= 1'b1;
            counter <= counter + 1;

            tdata <= {8{counter}};

            if (counter == 8'd63)
                tlast <= 1'b1;
            else
                tlast <= 1'b0;
        end
    end

    // ============================================================
    // Parser outputs
    // ============================================================

    wire [63:0] m_axis_tdata;
    wire        m_axis_tvalid;
    wire        m_axis_tlast;
    wire        m_axis_tuser_valid;

    // ============================================================
    // Parser instance
    // ============================================================

    ethernet_frame_parser #(
        .DATA_WIDTH(64),
        .USER_WIDTH(1)
    ) uut (
        .clk               (clk),
        .rst               (rst),

        .s_axis_tdata      (tdata),
        .s_axis_tvalid     (tvalid),
        .s_axis_tready     (tready),
        .s_axis_tlast      (tlast),

        .m_axis_tdata      (m_axis_tdata),
        .m_axis_tvalid     (m_axis_tvalid),
        .m_axis_tready     (1'b1),
        .m_axis_tlast      (m_axis_tlast),

        .m_axis_tuser      (),
        .m_axis_tuser_valid(m_axis_tuser_valid)
    );

    // ============================================================
    // LED Debug
    // ============================================================

    assign led[0] = m_axis_tvalid;
    assign led[1] = m_axis_tlast;
    assign led[2] = m_axis_tuser_valid;
    assign led[3] = clk;
    
    // ============================================================
    // ILA Instance
    // ============================================================

    ila_0 u_ila (
        .clk    (clk),

        .probe0 (tvalid),              // AXI input valid
        .probe1 (tready),              // AXI ready
        .probe2 (m_axis_tvalid),       // Parser output valid
        .probe3 (m_axis_tuser_valid),  // Metadata valid
        .probe4 (m_axis_tdata)         // 64-bit data
    );

endmodule



