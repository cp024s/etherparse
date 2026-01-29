// ============================================================
// Module: byte_counter
// Purpose:
//  - Count bytes consumed per frame
//  - Assert header_done when header byte threshold is reached
//  - Beat-driven (uses beat_accept)
// ============================================================

`timescale 1ns/1ps

module byte_counter #(
  parameter int DATA_WIDTH   = 64,
  parameter int HEADER_BYTES = 18
)(
  input  logic clk,
  input  logic rst_n,

  // Control
  input  logic beat_accept,   // asserted when a data beat is consumed
  input  logic frame_start,   // single-cycle pulse at start of frame

  // Status
  output logic header_done
);

  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;

  logic [$clog2(HEADER_BYTES+BYTES_PER_BEAT):0] byte_count;
  logic [$clog2(HEADER_BYTES+BYTES_PER_BEAT):0] next_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      byte_count <= '0;
      header_done <= 1'b0;
    end else begin
      // Reset on new frame
      if (frame_start) begin
        byte_count  <= '0;
        header_done <= 1'b0;
      end
      // Count bytes on accepted beats
      else if (beat_accept && !header_done) begin
        next_count = byte_count + BYTES_PER_BEAT;

        if (next_count >= HEADER_BYTES) begin
          byte_count  <= HEADER_BYTES;
          header_done <= 1'b1;
        end else begin
          byte_count <= next_count;
        end
      end
    end
  end

endmodule
