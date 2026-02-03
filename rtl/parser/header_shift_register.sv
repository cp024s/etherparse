// ============================================================
// header_shift_register (PACKED VERSION)
// Module: header_shift_register
// Purpose:
//  - Capture first HEADER_BYTES bytes of a frame
//  - Output as a PACKED vector (tool-safe)
// ============================================================
import eth_parser_pkg::*;

`timescale 1ns/1ps

module header_shift_register #(
  parameter int DATA_WIDTH   = 64,
  parameter int HEADER_BYTES = 14
)(
  input  logic                     clk,
  input  logic                     rst_n,

  input  logic                     beat_accept,
  input  logic                     frame_start,
  input  logic [DATA_WIDTH-1:0]    axis_tdata,

  output logic [HEADER_BYTES*8-1:0] header_bytes,
  output logic                     header_valid
);

  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;

  int unsigned byte_ptr;
  int unsigned i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      header_bytes <= '0;
      header_valid <= 1'b0;
      byte_ptr     <= 0;
    end else begin
      if (frame_start) begin
        header_bytes <= '0;
        header_valid <= 1'b0;
        byte_ptr     <= 0;
      end
      else if (beat_accept && !header_valid) begin
        for (i = 0; i < BYTES_PER_BEAT; i++) begin
          if (byte_ptr < HEADER_BYTES) begin
            header_bytes[byte_ptr*8 +: 8] <= axis_tdata[i*8 +: 8];
            byte_ptr <= byte_ptr + 1;
          end
        end

        if (byte_ptr >= HEADER_BYTES)
          header_valid <= 1'b1;
      end
    end
  end

endmodule
