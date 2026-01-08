// ============================================================
// Module: byte_counter
// Purpose: Byte-accurate position tracking within Ethernet frame
// ============================================================

`timescale 1ns/1ps

module byte_counter #(
  parameter int DATA_WIDTH = 64,
  parameter int L2_HEADER_MAX_BYTES = 18
)(
  input  logic clk,
  input  logic rst_n,

  // Control inputs
  input  logic beat_accept,
  input  logic frame_start,
  input  logic frame_end,

  // Outputs
  output logic [$clog2(L2_HEADER_MAX_BYTES + DATA_WIDTH/8 + 1)-1:0] byte_count,
  output logic in_l2_header,
  output logic header_done
);

  // ----------------------------------------------------------
  // Local parameters
  // ----------------------------------------------------------
  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;

  // ----------------------------------------------------------
  // Byte counter logic
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      byte_count <= '0;
    end
    else if (frame_start) begin
      // Reset counter at start of every frame
      byte_count <= '0;
    end
    else if (beat_accept && !frame_end) begin
      // Advance only when a beat is actually accepted
      byte_count <= byte_count + BYTES_PER_BEAT;
    end
  end

  // ----------------------------------------------------------
  // Header window indicator
  // ----------------------------------------------------------
  assign in_l2_header = (byte_count < L2_HEADER_MAX_BYTES);

  // ----------------------------------------------------------
  // Header completion indicator (CRITICAL)
  // ----------------------------------------------------------
  //
  // This is the single authoritative signal indicating that
  // the Ethernet L2 header (including optional VLAN) has been
  // fully received.
  //
  assign header_done = (byte_count >= L2_HEADER_MAX_BYTES);

endmodule
