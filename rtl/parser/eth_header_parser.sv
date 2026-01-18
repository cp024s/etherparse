// ============================================================
// Module: eth_header_parser
// Purpose: Decode Ethernet II header fields from byte array
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module eth_header_parser (
  input  eth_header_bytes_t header_bytes,
  input  logic              header_valid,

  output mac_addr_t         dest_mac,
  output mac_addr_t         src_mac,
  output ethertype_t        ethertype_raw,
  output logic              fields_valid
);

  always_comb begin
    // Defaults
    dest_mac      = '0;
    src_mac       = '0;
    ethertype_raw = '0;
    fields_valid  = 1'b0;

    if (header_valid) begin
      // Destination MAC: bytes 0..5
      dest_mac = {
        header_bytes[0],
        header_bytes[1],
        header_bytes[2],
        header_bytes[3],
        header_bytes[4],
        header_bytes[5]
      };

      // Source MAC: bytes 6..11
      src_mac = {
        header_bytes[6],
        header_bytes[7],
        header_bytes[8],
        header_bytes[9],
        header_bytes[10],
        header_bytes[11]
      };

      // Ethertype: bytes 12..13
      ethertype_raw = {
        header_bytes[12],
        header_bytes[13]
      };

      fields_valid = 1'b1;
    end
  end

endmodule
