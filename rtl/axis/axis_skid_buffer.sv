// ============================================================
// Module: axis_skid_buffer
// Purpose: Single-beat AXI4-Stream skid buffer
// ============================================================

`timescale 1ns/1ps

module axis_skid_buffer #(
  parameter int DATA_WIDTH = 64
)(
  input  logic                  clk,
  input  logic                  rst_n,

  // AXI input
  input  logic [DATA_WIDTH-1:0] s_axis_tdata,
  input  logic                  s_axis_tvalid,
  output logic                  s_axis_tready,
  input  logic                  s_axis_tlast,

  // AXI output
  output logic [DATA_WIDTH-1:0] m_axis_tdata,
  output logic                  m_axis_tvalid,
  input  logic                  m_axis_tready,
  output logic                  m_axis_tlast
);

  // ----------------------------------------------------------
  // Skid buffer registers
  // ----------------------------------------------------------

  logic [DATA_WIDTH-1:0] data_reg;
  logic                  last_reg;
  logic                  stored;

  // ----------------------------------------------------------
  // Ready/valid logic
  // ----------------------------------------------------------

  assign s_axis_tready = !stored || (m_axis_tready);

  assign m_axis_tvalid = stored ? 1'b1 : s_axis_tvalid;
  assign m_axis_tdata  = stored ? data_reg : s_axis_tdata;
  assign m_axis_tlast  = stored ? last_reg : s_axis_tlast;

  // ----------------------------------------------------------
  // Storage control
  // ----------------------------------------------------------

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stored   <= 1'b0;
      data_reg <= '0;
      last_reg <= 1'b0;
    end
    else begin
      // Capture incoming beat when downstream stalls
      if (s_axis_tvalid && s_axis_tready && !m_axis_tready) begin
        data_reg <= s_axis_tdata;
        last_reg <= s_axis_tlast;
        stored   <= 1'b1;
      end

      // Release stored beat when downstream accepts
      if (stored && m_axis_tready) begin
        stored <= 1'b0;
      end
    end
  end

endmodule
