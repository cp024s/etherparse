// ============================================================
// Module: axis_ingress
// Purpose: AXI4-Stream ingress handler for Ethernet parser
// ============================================================

`timescale 1ns/1ps

module axis_ingress #(
  parameter int DATA_WIDTH = 64
)(
  input  logic                   clk,
  input  logic                   rst_n,

  // AXI4-Stream input (from MAC or upstream block)
  input  logic [DATA_WIDTH-1:0]  s_axis_tdata,
  input  logic                   s_axis_tvalid,
  output logic                   s_axis_tready,
  input  logic                   s_axis_tlast,

  // Internal stream output (to parser pipeline)
  output logic [DATA_WIDTH-1:0]  axis_tdata,
  output logic                   axis_tvalid,
  input  logic                   axis_tready,
  output logic                   axis_tlast,

  // Handshake indicator for downstream logic
  output logic                   beat_accept
);

  // ----------------------------------------------------------
  // AXI handshake logic
  // ----------------------------------------------------------
  //
  // This module does not buffer data. It purely enforces
  // AXI4-Stream handshake correctness and propagates
  // backpressure cleanly.
  //

  assign s_axis_tready = axis_tready;

  assign axis_tdata  = s_axis_tdata;
  assign axis_tvalid = s_axis_tvalid;
  assign axis_tlast  = s_axis_tlast;

  // A beat is accepted only when both sides agree
  assign beat_accept = s_axis_tvalid && s_axis_tready;

endmodule
