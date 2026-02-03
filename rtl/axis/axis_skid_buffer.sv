//------------------------------------------------------------------------------
// AXI-Stream 1-deep skid buffer (final, duplication-safe)
//------------------------------------------------------------------------------

module axis_skid_buffer #(
    parameter int DATA_WIDTH = 8,
    parameter int USER_WIDTH = 1
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // AXI-stream input
    input  logic [DATA_WIDTH-1:0]  s_tdata,
    input  logic                   s_tvalid,
    input  logic                   s_tlast,
    input  logic [USER_WIDTH-1:0]  s_tuser,
    output logic                   s_tready,

    // AXI-stream output
    output logic [DATA_WIDTH-1:0]  m_tdata,
    output logic                   m_tvalid,
    output logic                   m_tlast,
    output logic [USER_WIDTH-1:0]  m_tuser,
    input  logic                   m_tready
);

    logic                   buf_valid;
    logic [DATA_WIDTH-1:0]  buf_data;
    logic                   buf_last;
    logic [USER_WIDTH-1:0]  buf_user;

    // Ready only when buffer empty
    assign s_tready = !buf_valid;

    // Output always from buffer
    assign m_tvalid = buf_valid;
    assign m_tdata  = buf_data;
    assign m_tlast  = buf_last;
    assign m_tuser  = buf_user;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf_valid <= 1'b0;
            buf_data  <= '0;
            buf_last  <= 1'b0;
            buf_user  <= '0;
        end else begin
            // Consume buffer
            if (buf_valid && m_tready) begin
                buf_valid <= 1'b0;
            end
            // Load buffer (only when empty)
            else if (!buf_valid && s_tvalid) begin
                buf_valid <= 1'b1;
                buf_data  <= s_tdata;
                buf_last  <= s_tlast;
                buf_user  <= s_tuser;
            end
        end
    end

    always_ff @(posedge clk) begin
  if (m_tvalid && m_tready) begin
    $display("[%0t] SKID forward: data=%h last=%b",
             $time, m_tdata, m_tlast);
  end
end


endmodule
