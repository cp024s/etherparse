// ============================================================
// Module: header_shift_register
// Purpose: Robust Ethernet L2 header capture (byte-accurate)
// ============================================================

`timescale 1ns/1ps

module header_shift_register #(
  parameter int DATA_WIDTH = 64,
  parameter int L2_HEADER_MAX_BYTES = 18
)(
  input  logic clk,
  input  logic rst_n,

  // Control
  input  logic beat_accept,
  input  logic frame_start,

  // AXI data
  input  logic [DATA_WIDTH-1:0] axis_tdata,

  // Outputs
  output logic [L2_HEADER_MAX_BYTES*8-1:0] header_bytes,
  output logic                            header_valid
);

  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;

  integer i;
  logic [$clog2(L2_HEADER_MAX_BYTES+1)-1:0] hdr_byte_idx;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      header_bytes <= '0;
      hdr_byte_idx <= '0;
      header_valid <= 1'b0;
    end
    else if (frame_start) begin
      header_bytes <= '0;
      hdr_byte_idx <= '0;
      header_valid <= 1'b0;
    end
    else if (beat_accept && !header_valid) begin
      // Capture bytes sequentially
      for (i = 0; i < BYTES_PER_BEAT; i++) begin
        if (hdr_byte_idx + i < L2_HEADER_MAX_BYTES) begin
          header_bytes[(hdr_byte_idx + i)*8 +: 8]
            <= axis_tdata[i*8 +: 8];
        end
      end

      // Advance byte index
      if (hdr_byte_idx + BYTES_PER_BEAT >= L2_HEADER_MAX_BYTES) begin
        hdr_byte_idx <= L2_HEADER_MAX_BYTES;
        header_valid <= 1'b1;
      end
      else begin
        hdr_byte_idx <= hdr_byte_idx + BYTES_PER_BEAT;
      end
    end
  end

endmodule
