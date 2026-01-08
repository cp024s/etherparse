// ============================================================
// Module: axis_egress
// Purpose: AXI-stream egress with metadata alignment
// ============================================================

`timescale 1ns/1ps

import eth_parser_pkg::*;

module axis_egress #(
  parameter int DATA_WIDTH = 64
)(
  input  logic                   clk,
  input  logic                   rst_n,

  // Internal AXI stream input
  input  logic [DATA_WIDTH-1:0]  axis_tdata_in,
  input  logic                   axis_tvalid_in,
  output logic                   axis_tready_in,
  input  logic                   axis_tlast_in,

  // AXI stream output
  output logic [DATA_WIDTH-1:0]  m_axis_tdata,
  output logic                   m_axis_tvalid,
  input  logic                   m_axis_tready,
  output logic                   m_axis_tlast,

  // Metadata input (from metadata_packager)
  input  eth_metadata_t          metadata_in,
  input  logic                   metadata_valid_in,

  // Metadata output (to downstream pipeline)
  output eth_metadata_t          metadata_out,
  output logic                   metadata_valid_out,

  // Frame control
  input  logic                   beat_accept,
  input  logic                   frame_end
);

  // ----------------------------------------------------------
  // AXI payload path (pure pass-through)
  // ----------------------------------------------------------

  assign m_axis_tdata  = axis_tdata_in;
  assign m_axis_tvalid = axis_tvalid_in;
  assign axis_tready_in = m_axis_tready;
  assign m_axis_tlast  = axis_tlast_in;

  // ----------------------------------------------------------
  // Metadata alignment logic
  // ----------------------------------------------------------

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      metadata_out       <= '0;
      metadata_valid_out <= 1'b0;
    end
    else if (metadata_valid_in && !metadata_valid_out) begin
      // Latch metadata once per frame
      metadata_out       <= metadata_in;
      metadata_valid_out <= 1'b1;
    end
    else if (frame_end && beat_accept) begin
      // Clear metadata only after the final beat is accepted
      metadata_valid_out <= 1'b0;
    end
  end

endmodule
