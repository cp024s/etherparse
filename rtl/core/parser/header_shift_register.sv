// ============================================================
// Module: header_shift_register
// Purpose:
//  - Collect first HEADER_BYTES bytes of frame
//  - Assert header_valid exactly when last byte is captured
// Purpose: Capture first 14 bytes of Ethernet frame
// ============================================================

`timescale 1ns/1ps

module header_shift_register #(
  parameter int DATA_WIDTH   = 8,
  parameter int HEADER_BYTES = 14
)(
  input  logic                   clk,
  input  logic                   rst_n,

  input  logic                   beat_accept,
  input  logic                   frame_start,
  input  logic [DATA_WIDTH-1:0]  axis_tdata,

  output logic [HEADER_BYTES-1:0][7:0] header_bytes,
  output logic                   header_valid
);

  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;

  logic [$clog2(HEADER_BYTES+1)-1:0] hdr_ptr;
  integer i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      hdr_ptr      <= '0;
      header_valid <= 1'b0;
    end else begin
      // New frame: restart capture
      if (frame_start) begin
        hdr_ptr      <= '0;
        header_valid <= 1'b0;
      end
      // Capture header bytes
      else if (beat_accept && !header_valid) begin
        for (i = 0; i < BYTES_PER_BEAT; i++) begin
          if (hdr_ptr < HEADER_BYTES) begin
            header_bytes[hdr_ptr] <= axis_tdata[i*8 +: 8];
            hdr_ptr <= hdr_ptr + 1'b1;
          end
        end

        if (hdr_ptr >= HEADER_BYTES-1)
          header_valid <= 1'b1;
      end
    end
  end

endmodule
