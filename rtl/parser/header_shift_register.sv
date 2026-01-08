// ============================================================
// Module: header_shift_register
// Purpose: Byte-accurate capture of Ethernet L2 header
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
  input  logic in_l2_header,

  // AXI stream data
  input  logic [DATA_WIDTH-1:0] axis_tdata,

  // Outputs
  output logic [L2_HEADER_MAX_BYTES*8-1:0] header_bytes,
  output logic                            header_valid
);

  // ----------------------------------------------------------
  // Local parameters
  // ----------------------------------------------------------

  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;

  // ----------------------------------------------------------
  // Internal state
  // ----------------------------------------------------------

  logic [$clog2(L2_HEADER_MAX_BYTES+1)-1:0] header_byte_count;

  // ----------------------------------------------------------
  // Header capture logic
  // ----------------------------------------------------------

  integer i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      header_bytes      <= '0;
      header_byte_count <= '0;
      header_valid      <= 1'b0;
    end
    else if (frame_start) begin
      // Reset at start of every frame
      header_bytes      <= '0;
      header_byte_count <= '0;
      header_valid      <= 1'b0;
    end
    else if (beat_accept && in_l2_header && !header_valid) begin
      // Extract bytes from this beat
      for (i = 0; i < BYTES_PER_BEAT; i = i + 1) begin
        if (header_byte_count < L2_HEADER_MAX_BYTES) begin
          header_bytes[
            (header_byte_count*8) +: 8
          ] <= axis_tdata[(i*8) +: 8];

          header_byte_count <= header_byte_count + 1;
        end
      end

      // Header capture complete
      if ((header_byte_count + BYTES_PER_BEAT) >= L2_HEADER_MAX_BYTES) begin
        header_valid <= 1'b1;
      end
    end
  end

endmodule
