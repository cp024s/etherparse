// ============================================================
// Module: eth_header_parser
// Purpose: Parse Ethernet II header fields (portable version)
// ============================================================

`timescale 1ns/1ps

module eth_header_parser (
  input  logic [17:0][7:0] header_bytes,
  input  logic             header_valid,

  output logic [47:0]       dest_mac,
  output logic [47:0]       src_mac,
  output logic [15:0]       ethertype_raw,
  output logic             fields_valid
);

  // Destination MAC: bytes 0..5
  assign dest_mac = header_valid ? {
    header_bytes[0],
    header_bytes[1],
    header_bytes[2],
    header_bytes[3],
    header_bytes[4],
    header_bytes[5]
  } : 48'h0;

  // Source MAC: bytes 6..11
  assign src_mac = header_valid ? {
    header_bytes[6],
    header_bytes[7],
    header_bytes[8],
    header_bytes[9],
    header_bytes[10],
    header_bytes[11]
  } : 48'h0;

  // Ethertype: bytes 12..13
  assign ethertype_raw = header_valid ? {
    header_bytes[12],
    header_bytes[13]
  } : 16'h0;

  // Valid follows header_valid
  assign fields_valid = header_valid;

endmodule
