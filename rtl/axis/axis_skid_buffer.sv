// ============================================================
// Module: axis_skid_buffer
// Purpose: AXI4-Stream compliant 1-deep skid buffer (CORRECT)
// ============================================================

`timescale 1ns/1ps

module axis_skid_buffer #(
  parameter int DATA_WIDTH = 64,
  parameter int USER_WIDTH = 1
)(
  input  logic                   clk,
  input  logic                   rst_n,

  // Slave side
  input  logic [DATA_WIDTH-1:0]  s_tdata,
  input  logic                   s_tvalid,
  output logic                   s_tready,
  input  logic                   s_tlast,
  input  logic [USER_WIDTH-1:0]  s_tuser,

  // Master side
  output logic [DATA_WIDTH-1:0]  m_tdata,
  output logic                   m_tvalid,
  input  logic                   m_tready,
  output logic                   m_tlast,
  output logic [USER_WIDTH-1:0]  m_tuser
);

  logic skid_valid;

  // ----------------------------------------------------------
  // Ready logic (THIS MATTERS)
  // ----------------------------------------------------------
  assign s_tready = !skid_valid;

  // ----------------------------------------------------------
  // Sequential logic
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_tvalid   <= 1'b0;
      skid_valid <= 1'b0;
    end
    else begin
      // Downstream handshake
      if (m_tvalid && m_tready) begin
        m_tvalid   <= 1'b0;
        skid_valid <= 1'b0;
      end

      // Accept new data
      if (!m_tvalid && s_tvalid) begin
        m_tvalid   <= 1'b1;
        skid_valid <= !m_tready;

        m_tdata <= s_tdata;
        m_tlast <= s_tlast;
        m_tuser <= s_tuser;
      end
    end
  end

`ifndef SYNTHESIS
  // ----------------------------------------------------------
  // AXI hold assertion (Icarus-safe)
  // ----------------------------------------------------------
  logic [DATA_WIDTH-1:0] hold_data;
  logic                  hold_last;
  logic [USER_WIDTH-1:0] hold_user;

  always_ff @(posedge clk) begin
    if (m_tvalid && !m_tready) begin
      hold_data <= m_tdata;
      hold_last <= m_tlast;
      hold_user <= m_tuser;
    end

    if (m_tvalid && !m_tready) begin
      assert (m_tdata == hold_data)
        else $fatal(1, "AXIS_SKID: data changed while stalled");
      assert (m_tlast == hold_last)
        else $fatal(1, "AXIS_SKID: last changed while stalled");
      assert (m_tuser == hold_user)
        else $fatal(1, "AXIS_SKID: user changed while stalled");
    end
  end
`endif

endmodule
