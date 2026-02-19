// ============================================================
// Module: eth_header_parser
// Purpose:
//  - Parse Ethernet header fields from PACKED header bytes
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module eth_header_parser (
  input  logic [14*8-1:0] header_bytes,
  input  logic             header_valid,

  output mac_addr_t        dest_mac,
  output mac_addr_t        src_mac,
  output ethertype_t       ethertype_raw,
  output logic             fields_valid
);

  // Ethernet layout:
  // [0:5]   -> Destination MAC
  // [6:11]  -> Source MAC
  // [12:13] -> Ethertype

  assign dest_mac = header_bytes[  0*8 +: 48];
  assign src_mac  = header_bytes[  6*8 +: 48];
  assign ethertype_raw = header_bytes[12*8 +: 16];

  assign fields_valid = header_valid;

endmodule
