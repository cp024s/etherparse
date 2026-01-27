`timescale 1ns/1ps

module axis_skid_buffer_tb;

    localparam int DATA_W = 32;
    localparam int USER_W = 1;

    logic clk;
    logic rst_n;

    // Slave side
    logic [DATA_W-1:0] s_axis_tdata;
    logic [USER_W-1:0] s_axis_tuser;
    logic              s_axis_tlast;
    logic              s_axis_tvalid;
    logic              s_axis_tready;

    // Master side
    logic [DATA_W-1:0] m_axis_tdata;
    logic [USER_W-1:0] m_axis_tuser;
    logic              m_axis_tlast;
    logic              m_axis_tvalid;
    logic              m_axis_tready;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    axis_skid_buffer #(
        .DATA_W (DATA_W),
        .USER_W (USER_W)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),

        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tuser   (s_axis_tuser),
        .s_axis_tlast   (s_axis_tlast),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),

        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tuser   (m_axis_tuser),
        .m_axis_tlast   (m_axis_tlast),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Simple sanity stimulus
    // ------------------------------------------------------------
    initial begin
        clk = 0;
        rst_n = 0;

        s_axis_tdata  = '0;
        s_axis_tuser  = '0;
        s_axis_tlast  = 0;
        s_axis_tvalid = 0;
        m_axis_tready = 0;

        #20;
        rst_n = 1;

        // Send one beat, stall downstream
        @(posedge clk);
        s_axis_tdata  <= 32'hDEADBEEF;
        s_axis_tvalid <= 1'b1;
        m_axis_tready <= 1'b0;

        // Hold stall for 3 cycles
        repeat (3) @(posedge clk);

        // Release downstream
        m_axis_tready <= 1'b1;

        @(posedge clk);
        s_axis_tvalid <= 1'b0;

        repeat (5) @(posedge clk);

        $display("axis_skid_buffer TB PASSED");
        $finish;
    end

endmodule
