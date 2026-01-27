// ============================================================
// Module: eth_header_parser
// Purpose: Parse Ethernet header fields
//          fields_valid asserts ONLY when header is complete
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module eth_header_parser (
  input  logic [17:0][7:0] header_bytes,
  input  logic             header_valid,

  output mac_addr_t        dest_mac,
  output mac_addr_t        src_mac,
  output ethertype_t       ethertype_raw,
  output logic             fields_valid
);

  // Icarus-safe continuous assignments
  assign dest_mac = header_valid ? {
    header_bytes[0],
    header_bytes[1],
    header_bytes[2],
    header_bytes[3],
    header_bytes[4],
    header_bytes[5]
  } : '0;

  assign src_mac = header_valid ? {
    header_bytes[6],
    header_bytes[7],
    header_bytes[8],
    header_bytes[9],
    header_bytes[10],
    header_bytes[11]
  } : '0;

  assign ethertype_raw = header_valid ? {
    header_bytes[12],
    header_bytes[13]
  } : '0;

  // Semantic meaning:
  // ALL header fields are complete and stable
  assign fields_valid = header_valid;

endmodule
