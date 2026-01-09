// ============================================================
// Module: eth_header_parser
// Purpose: Parse Ethernet II header fields (BYTE-EXPLICIT)
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module eth_header_parser (
  input  logic           clk,
  input  logic           rst_n,

  input  logic [18*8-1:0] header_bytes,
  input  logic           header_valid,

  output mac_addr_t      dest_mac,
  output mac_addr_t      src_mac,
  output ethertype_t     ethertype_raw,
  output logic           fields_valid
);

  // ----------------------------------------------------------
  // Byte extraction helper
  // Byte 0 = MSB of header_bytes
  // ----------------------------------------------------------
  function automatic logic [7:0] get_byte(input int idx);
    int bit_pos;
    begin
      bit_pos = (18 - idx) * 8 - 1;
      get_byte = header_bytes[bit_pos -: 8];
    end
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dest_mac      <= '0;
      src_mac       <= '0;
      ethertype_raw <= '0;
      fields_valid  <= 1'b0;
    end
    else if (header_valid) begin
      // Destination MAC (bytes 0..5)
      dest_mac <= {
        get_byte(0),
        get_byte(1),
        get_byte(2),
        get_byte(3),
        get_byte(4),
        get_byte(5)
      };

      // Source MAC (bytes 6..11)
      src_mac <= {
        get_byte(6),
        get_byte(7),
        get_byte(8),
        get_byte(9),
        get_byte(10),
        get_byte(11)
      };

      // Ethertype (bytes 12..13)
      ethertype_raw <= {
        get_byte(12),
        get_byte(13)
      };

      fields_valid <= 1'b1;
    end
    else begin
      fields_valid <= 1'b0;
    end
  end

endmodule
