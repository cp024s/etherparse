// ============================================================
// Module: axis_egress
// Purpose:
//  - AXI stream egress boundary
//  - Pure pass-through (no buffering, no elasticity)
// ============================================================

`timescale 1ns/1ps

module axis_egress #(
  parameter int DATA_WIDTH = 64,
  parameter int USER_WIDTH = 1
)(
  input  logic                   clk,
  input  logic                   rst_n,

  // Internal AXI stream
  input  logic [DATA_WIDTH-1:0]  s_tdata,
  input  logic                   s_tvalid,
  output logic                   s_tready,
  input  logic                   s_tlast,
  input  logic [USER_WIDTH-1:0]  s_tuser,

  // External AXI stream
  output logic [DATA_WIDTH-1:0]  m_tdata,
  output logic                   m_tvalid,
  input  logic                   m_tready,
  output logic                   m_tlast,
  output logic [USER_WIDTH-1:0]  m_tuser
);

  // Pure wiring — no state
  assign m_tdata  = s_tdata;
  assign m_tvalid = s_tvalid;
  assign m_tlast  = s_tlast;
  assign m_tuser  = s_tuser;

  assign s_tready = m_tready;

endmodule
