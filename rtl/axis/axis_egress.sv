// ============================================================
// Module: axis_egress
// Purpose: AXI4-Stream egress (data path NEVER stalls)
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module axis_egress #(
  parameter int DATA_WIDTH = 64
)(
  input  logic                   clk,
  input  logic                   rst_n,

  // Internal AXI stream
  input  logic [DATA_WIDTH-1:0]  axis_tdata_in,
  input  logic                   axis_tvalid_in,
  output logic                   axis_tready_in,
  input  logic                   axis_tlast_in,

  // Output AXI stream
  output logic [DATA_WIDTH-1:0]  m_axis_tdata,
  output logic                   m_axis_tvalid,
  input  logic                   m_axis_tready,
  output logic                   m_axis_tlast,

  // Metadata sideband
  input  eth_metadata_t          metadata_in,
  input  logic                   metadata_valid_in,

  output eth_metadata_t          metadata_out,
  output logic                   metadata_valid_out
);

  // ----------------------------------------------------------
  // AXI data path (ABSOLUTE PASS-THROUGH)
  // ----------------------------------------------------------
  assign m_axis_tdata  = axis_tdata_in;
  assign m_axis_tvalid = axis_tvalid_in;
  assign m_axis_tlast  = axis_tlast_in;

  // READY must depend ONLY on downstream READY
  assign axis_tready_in = m_axis_tready;

  // ----------------------------------------------------------
  // Metadata latch (completely decoupled)
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      metadata_out       <= '0;
      metadata_valid_out <= 1'b0;
    end
    else if (metadata_valid_in) begin
      metadata_out       <= metadata_in;
      metadata_valid_out <= 1'b1;
    end
  end

endmodule
