// ============================================================
// Module: axis_ingress
// Purpose: AXI4-Stream ingress with clean handshake detection
// ============================================================

`timescale 1ns/1ps

module axis_ingress #(
  parameter int DATA_WIDTH = 64
)(
  input  logic                   clk,
  input  logic                   rst_n,

  // AXI4-Stream slave interface
  input  logic [DATA_WIDTH-1:0]  s_axis_tdata,
  input  logic                   s_axis_tvalid,
  output logic                   s_axis_tready,
  input  logic                   s_axis_tlast,

  // Internal stream
  output logic [DATA_WIDTH-1:0]  axis_tdata,
  output logic                   axis_tvalid,
  input  logic                   axis_tready,
  output logic                   axis_tlast,

  // Handshake indicator
  output logic                   beat_accept
);

  // ----------------------------------------------------------
  // AXI pass-through
  // ----------------------------------------------------------

  assign axis_tdata  = s_axis_tdata;
  assign axis_tvalid = s_axis_tvalid;
  assign axis_tlast  = s_axis_tlast;

  // ----------------------------------------------------------
  // READY propagation
  // ----------------------------------------------------------
  //
  // READY must depend ONLY on downstream readiness.
  // Never gate READY with TVALID — that causes deadlock.
  //
  assign s_axis_tready = axis_tready;

  // ----------------------------------------------------------
  // Beat accept (authoritative)
  // ----------------------------------------------------------
  //
  // A beat is accepted exactly when VALID and READY are high.
  //
  assign beat_accept = axis_tvalid && axis_tready;

endmodule
