// ============================================================
// Module: vlan_resolver
// Purpose:
//  - Detect VLAN
//  - Resolve final ethertype
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module vlan_resolver (
  input  logic [14*8-1:0] header_bytes,
  input  ethertype_t      ethertype_raw,
  input  logic            fields_valid,

  output logic            vlan_present,
  output logic [11:0]     vlan_id,
  output ethertype_t     resolved_ethertype,
  output logic [4:0]      l2_header_len,
  output logic            vlan_valid
);

  localparam ethertype_t ETH_VLAN = 16'h8100;

  // VLAN tag layout (bytes 14–17 if present)
  wire [15:0] tci        = header_bytes[14*8 +: 16];
  wire [15:0] vlan_type = header_bytes[16*8 +: 16];

  assign vlan_present = fields_valid && (ethertype_raw == ETH_VLAN);

  assign vlan_id = vlan_present ? tci[11:0] : 12'd0;

  assign resolved_ethertype =
    vlan_present ? vlan_type : ethertype_raw;

  assign l2_header_len =
    vlan_present ? 5'd18 : 5'd14;

  assign vlan_valid = fields_valid;

endmodule
