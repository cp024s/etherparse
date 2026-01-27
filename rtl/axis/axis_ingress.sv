// ============================================================
// Module: axis_ingress
// Purpose:
//  - AXI stream ingress boundary
//  - Pure pass-through (no buffering, no elasticity)
// ============================================================

`timescale 1ns/1ps

module axis_ingress #(
  parameter int DATA_WIDTH = 64,
  parameter int USER_WIDTH = 1
)(
  input  logic                   clk,
  input  logic                   rst_n,

  // External AXI stream
  input  logic [DATA_WIDTH-1:0]  s_tdata,
  input  logic                   s_tvalid,
  output logic                   s_tready,
  input  logic                   s_tlast,
  input  logic [USER_WIDTH-1:0]  s_tuser,

  // Internal AXI stream
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

`ifndef SYNTHESIS
  logic [DATA_WIDTH-1:0] m_tdata_q;
  logic                  m_tlast_q;
  logic [USER_WIDTH-1:0] m_tuser_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      m_tdata_q <= '0;
      m_tlast_q <= 1'b0;
      m_tuser_q <= '0;
    end
    else begin
      // When stalled, outputs must not change
      if (m_tvalid && !m_tready) begin
        assert (m_tdata == m_tdata_q)
          else $fatal("AXIS_INGRESS: m_tdata changed while stalled");
        assert (m_tlast == m_tlast_q)
          else $fatal("AXIS_INGRESS: m_tlast changed while stalled");
        assert (m_tuser == m_tuser_q)
          else $fatal("AXIS_INGRESS: m_tuser changed while stalled");
      end

      // Capture previous values
      m_tdata_q <= m_tdata;
      m_tlast_q <= m_tlast;
      m_tuser_q <= m_tuser;
    end
  end

  // LAST must only assert with VALID
  always_ff @(posedge clk) begin
    if (rst_n) begin
      assert (!(m_tlast && !m_tvalid))
        else $fatal("AXIS_INGRESS: m_tlast asserted without m_tvalid");
    end
  end
`endif

endmodule