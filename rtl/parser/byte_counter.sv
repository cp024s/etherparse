// ============================================================
// Module: byte_counter
// Purpose: Byte-accurate position tracking (timing-correct)
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
  // Next-byte calculation (CRITICAL)
  // ----------------------------------------------------------
  logic [$clog2(L2_HEADER_MAX_BYTES + DATA_WIDTH/8 + 1)-1:0] byte_count_next;

  always_comb begin
    if (frame_start)
      byte_count_next = '0;
    else if (beat_accept && !frame_end)
      byte_count_next = byte_count + BYTES_PER_BEAT;
    else
      byte_count_next = byte_count;
  end

  // ----------------------------------------------------------
  // Byte counter register
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      byte_count <= '0;
    else
      byte_count <= byte_count_next;
  end

  // ----------------------------------------------------------
  // Header window indicator
  // ----------------------------------------------------------
  assign in_l2_header = (byte_count < L2_HEADER_MAX_BYTES);

  // ----------------------------------------------------------
  // Header completion (TIMING-CORRECT)
  // ----------------------------------------------------------
  assign header_done = (byte_count_next >= L2_HEADER_MAX_BYTES);

endmodule
