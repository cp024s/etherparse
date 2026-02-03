// ============================================================
// Module: byte_counter
// Purpose:
//  - Count bytes consumed per frame
//  - Assert header_done exactly once
// ============================================================

`timescale 1ns/1ps

module byte_counter #(
  parameter int DATA_WIDTH   = 64,
  parameter int HEADER_BYTES = 18
)(
  input  logic clk,
  input  logic rst_n,

  input  logic beat_accept,
  input  logic frame_start,

  output logic header_done
);

  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;
  localparam int CNT_W = $clog2(HEADER_BYTES + BYTES_PER_BEAT + 1);

  logic [CNT_W-1:0] byte_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      byte_count <= '0;
      header_done <= 1'b0;
    end else begin
      if (frame_start) begin
        byte_count  <= '0;
        header_done <= 1'b0;
      end else if (beat_accept && !header_done) begin
        byte_count <= byte_count + BYTES_PER_BEAT;
        if (byte_count + BYTES_PER_BEAT >= HEADER_BYTES)
          header_done <= 1'b1;
      end
    end
  end

endmodule
