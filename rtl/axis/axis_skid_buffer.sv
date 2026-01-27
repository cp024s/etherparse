module axis_skid_buffer #(
    parameter int DATA_W = 64,
    parameter int USER_W = 1
) (
    input  logic                 clk,
    input  logic                 rst_n,

    // Slave AXI4-Stream
    input  logic [DATA_W-1:0]    s_axis_tdata,
    input  logic [USER_W-1:0]    s_axis_tuser,
    input  logic                 s_axis_tlast,
    input  logic                 s_axis_tvalid,
    output logic                 s_axis_tready,

    // Master AXI4-Stream
    output logic [DATA_W-1:0]    m_axis_tdata,
    output logic [USER_W-1:0]    m_axis_tuser,
    output logic                 m_axis_tlast,
    output logic                 m_axis_tvalid,
    input  logic                 m_axis_tready
);

    // ------------------------------------------------------------
    // Skid registers
    // ------------------------------------------------------------
    logic [DATA_W-1:0] skid_tdata;
    logic [USER_W-1:0] skid_tuser;
    logic              skid_tlast;
    logic              skid_valid;

    // ------------------------------------------------------------
    // Ready logic
    // ------------------------------------------------------------
    assign s_axis_tready = !skid_valid || m_axis_tready;

    // ------------------------------------------------------------
    // Skid capture / release
    // ------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            skid_valid <= 1'b0;
            skid_tdata <= '0;
            skid_tuser <= '0;
            skid_tlast <= 1'b0;
        end else begin
            // Capture when upstream valid & downstream stalled
            if (s_axis_tvalid && s_axis_tready && !m_axis_tready) begin
                skid_valid <= 1'b1;
                skid_tdata <= s_axis_tdata;
                skid_tuser <= s_axis_tuser;
                skid_tlast <= s_axis_tlast;
            end
            // Release when downstream accepts
            else if (skid_valid && m_axis_tready) begin
                skid_valid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------
    // Output mux
    // ------------------------------------------------------------
    assign m_axis_tvalid = skid_valid ? 1'b1        : s_axis_tvalid;
    assign m_axis_tdata  = skid_valid ? skid_tdata  : s_axis_tdata;
    assign m_axis_tuser  = skid_valid ? skid_tuser  : s_axis_tuser;
    assign m_axis_tlast  = skid_valid ? skid_tlast  : s_axis_tlast;

endmodule
