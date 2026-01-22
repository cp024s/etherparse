`timescale 1ns/1ps

module axis_skid_buffer_tb;

    localparam int DATA_WIDTH = 8;
    localparam int USER_WIDTH = 1;

    logic clk;
    logic rst_n;

    logic [DATA_WIDTH-1:0] s_tdata;
    logic                  s_tvalid;
    logic                  s_tlast;
    logic [USER_WIDTH-1:0] s_tuser;
    logic                  s_tready;

    logic [DATA_WIDTH-1:0] m_tdata;
    logic                  m_tvalid;
    logic                  m_tlast;
    logic [USER_WIDTH-1:0] m_tuser;
    logic                  m_tready;

    axis_skid_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .USER_WIDTH(USER_WIDTH)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .s_tdata  (s_tdata),
        .s_tvalid (s_tvalid),
        .s_tlast  (s_tlast),
        .s_tuser  (s_tuser),
        .s_tready (s_tready),
        .m_tdata  (m_tdata),
        .m_tvalid (m_tvalid),
        .m_tlast  (m_tlast),
        .m_tuser  (m_tuser),
        .m_tready (m_tready)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;

        s_tdata  = 0;
        s_tvalid = 0;
        s_tlast  = 0;
        s_tuser  = 0;
        m_tready = 0;

        #20 rst_n = 1;

        // Drive one beat
        @(posedge clk);
        s_tdata  <= 8'hAA;
        s_tvalid <= 1'b1;
        s_tlast  <= 1'b1;

        // Stall downstream
        repeat (3) @(posedge clk);

        // Release downstream
        m_tready <= 1'b1;

        @(posedge clk);
        if (!(m_tvalid && m_tdata == 8'hAA && m_tlast)) begin
            $fatal(1, "SKID BUFFER FAILED: missing or incorrect transfer");
        end

        // Ensure no duplication
        @(posedge clk);
        if (m_tvalid) begin
            $fatal(1, "SKID BUFFER FAILED: duplicate transfer detected");
        end

        $display("AXIS SKID BUFFER TEST PASSED");
        $finish;
    end

endmodule
