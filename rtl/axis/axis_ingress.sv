// ============================================================
// Module: axis_ingress
// Purpose: AXI4-Stream ingress adapter (pass-through)
// ============================================================

`timescale 1ns/1ps

module axis_ingress #(
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
  output logic [DATA_WIDTH-1:0] axis_tdata,
  output logic                  axis_tvalid,
  input  logic                  axis_tready,
  output logic                  axis_tlast,

  // Handshake indicator
  output logic                  beat_accept
);

  // Pass-through
  assign axis_tdata  = s_axis_tdata;
  assign axis_tvalid = s_axis_tvalid;
  assign axis_tlast  = s_axis_tlast;

  assign s_axis_tready = axis_tready;

  // Beat accepted when both valid and ready
  assign beat_accept = s_axis_tvalid && s_axis_tready;

endmodule
