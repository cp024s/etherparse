// ============================================================
// Module: header_shift_register
// Purpose: Capture first 18 bytes of Ethernet frame as byte array
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module header_shift_register #(
  parameter int DATA_WIDTH = 64
)(
  input  logic              clk,
  input  logic              rst_n,

  // AXI beat control
  input  logic              beat_accept,
  input  logic              frame_start,

  // AXI data
  input  logic [DATA_WIDTH-1:0] axis_tdata,

  // Outputs
  output eth_header_bytes_t header_bytes,
  output logic              header_valid
);

  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;

  logic [4:0] byte_count; // counts 0..18

  integer i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      byte_count  <= 0;
      header_bytes <= '{default:8'h00};
      header_valid <= 1'b0;
    end
    else begin
      header_valid <= 1'b0;

      if (frame_start) begin
        byte_count  <= 0;
        header_bytes <= '{default:8'h00};
      end

      if (beat_accept && byte_count < 18) begin
        // Extract bytes from AXI beat (MSB first)
        for (i = 0; i < BYTES_PER_BEAT; i++) begin
          if (byte_count < 18) begin
            header_bytes[byte_count] <=
              axis_tdata[(DATA_WIDTH-1) - (i*8) -: 8];
            byte_count <= byte_count + 1;
          end
        end
      end

      if (byte_count == 18)
        header_valid <= 1'b1;
    end
  end

endmodule
