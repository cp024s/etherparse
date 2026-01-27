// ============================================================
// Module: eth_header_parser
// Purpose: Parse Ethernet II header fields (BYTE-ACCURATE)
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module eth_header_parser (
  input  logic [18*8-1:0] header_bytes,
  input  logic            header_valid,

  output mac_addr_t       dest_mac,
  output mac_addr_t       src_mac,
  output ethertype_t      ethertype_raw,
  output logic            fields_valid
);

  // Byte view (LSB = first byte on wire)
  logic [7:0] b [0:17];

  integer i;
  always_comb begin
    for (i = 0; i < 18; i++)
      b[i] = header_bytes[i*8 +: 8];
  end

  always_ff @(posedge header_valid) begin
    // Destination MAC: bytes 0–5
    dest_mac <= {
      b[0], b[1], b[2], b[3], b[4], b[5]
    };

    // Source MAC: bytes 6–11
    src_mac <= {
      b[6], b[7], b[8], b[9], b[10], b[11]
    };

    // EtherType: bytes 12–13
    ethertype_raw <= {
      b[12], b[13]
    };

    fields_valid <= 1'b1;
  end

endmodule
