// ============================================================
// Module: vlan_resolver
// Purpose:
//  - Detect VLAN
//  - Resolve final ethertype
// Purpose: Resolve VLAN (DISABLED for 14B Ethernet header)
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module vlan_resolver (
  input  logic [13:0][7:0] header_bytes,   // 14 bytes ONLY
  input  ethertype_t       ethertype_raw,
  input  logic             fields_valid,

  output logic             vlan_present,
  output logic [11:0]      vlan_id,
  output ethertype_t       resolved_ethertype,
  output logic [4:0]       l2_header_len,
  output logic             vlan_valid
);

  // ----------------------------------------------------------
  // VLAN NOT SUPPORTED IN THIS REVISION
  // ----------------------------------------------------------

  always_comb begin
    vlan_present       = 1'b0;
    vlan_id            = 12'd0;
    resolved_ethertype = ethertype_raw;
    l2_header_len      = 5'd14;   // Ethernet header length
    vlan_valid         = fields_valid;
  end

endmodule
