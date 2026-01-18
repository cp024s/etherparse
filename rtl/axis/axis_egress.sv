// ============================================================
// Module: axis_egress
// Purpose: AXI4-Stream egress with metadata alignment
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module axis_egress #(
  parameter int DATA_WIDTH = 64
)(
  input  logic                  clk,
  input  logic                  rst_n,

  // AXI input
  input  logic [DATA_WIDTH-1:0] axis_tdata_in,
  input  logic                  axis_tvalid_in,
  output logic                  axis_tready_in,
  input  logic                  axis_tlast_in,

  // AXI output
  output logic [DATA_WIDTH-1:0] m_axis_tdata,
  output logic                  m_axis_tvalid,
  input  logic                  m_axis_tready,
  output logic                  m_axis_tlast,

  // Metadata input
  input  eth_metadata_t         metadata_in,
  input  logic                  metadata_valid_in,

  // Metadata output (AXI sideband)
  output eth_metadata_t         metadata_out,
  output logic                  metadata_valid_out
);

  // ----------------------------------------------------------
  // AXI pass-through
  // ----------------------------------------------------------

  assign m_axis_tdata  = axis_tdata_in;
  assign m_axis_tvalid = axis_tvalid_in;
  assign m_axis_tlast  = axis_tlast_in;
  assign axis_tready_in = m_axis_tready;

  // ----------------------------------------------------------
  // Metadata latching
  // ----------------------------------------------------------

  eth_metadata_t metadata_reg;
  logic          metadata_active;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      metadata_reg    <= '0;
      metadata_active <= 1'b0;
    end
    else begin
      // Latch metadata when it becomes valid
      if (metadata_valid_in && !metadata_active) begin
        metadata_reg    <= metadata_in;
        metadata_active <= 1'b1;
      end

      // Clear metadata at end of frame
      if (axis_tvalid_in && axis_tready_in && axis_tlast_in) begin
        metadata_active <= 1'b0;
      end
    end
  end

  assign metadata_out       = metadata_reg;
  assign metadata_valid_out = metadata_active;

endmodule
