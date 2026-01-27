// ============================================================
// Module: header_shift_register
// Purpose: Capture first 18 bytes of Ethernet frame
//          LSB-first (AXI-compliant)
// ============================================================

`timescale 1ns/1ps

module header_shift_register #(
  parameter int DATA_WIDTH = 64
)(
  input  logic                  clk,
  input  logic                  rst_n,

  input  logic                  beat_accept,
  input  logic                  frame_start,
  input  logic [DATA_WIDTH-1:0] axis_tdata,

  output logic [17:0][7:0]      header_bytes,
  output logic                 header_valid
);

  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;

  integer i;
  logic [4:0] byte_count;
  logic [4:0] next_byte_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      byte_count   <= 0;
      header_valid <= 0;
      for (i = 0; i < 18; i++)
        header_bytes[i] <= 8'h00;
    end else begin
      if (frame_start) begin
        byte_count   <= 0;
        header_valid <= 0;
      end
      else if (beat_accept && !header_valid) begin
        next_byte_count = byte_count;

        for (i = 0; i < BYTES_PER_BEAT; i++) begin
          if (next_byte_count < 18) begin
            header_bytes[next_byte_count] <= axis_tdata[(i*8) +: 8];
            next_byte_count++;
          end
        end

        byte_count <= next_byte_count;

        if (next_byte_count >= 18)
          header_valid <= 1'b1;
      end
    end
  end

endmodule
