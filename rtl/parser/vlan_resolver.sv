// ============================================================
// Module: vlan_resolver
// Purpose: Detect and resolve single 802.1Q VLAN tag (portable)
// ============================================================

`timescale 1ns/1ps

module vlan_resolver (
  input  logic [17:0][7:0] header_bytes,
  input  logic [15:0]       ethertype_raw,
  input  logic              fields_valid,

  output logic              vlan_present,
  output logic [11:0]       vlan_id,
  output logic [15:0]       resolved_ethertype,
  output logic [4:0]        l2_header_len,
  output logic              vlan_valid
);

  // VLAN detection
  assign vlan_present = fields_valid && (ethertype_raw == 16'h8100);

  // VLAN ID (lower 12 bits of TCI)
  assign vlan_id = vlan_present
    ? { header_bytes[14][3:0], header_bytes[15] }
    : 12'd0;

  // Resolved ethertype
  assign resolved_ethertype = vlan_present
    ? { header_bytes[16], header_bytes[17] }
    : ethertype_raw;

  // Header length
  assign l2_header_len = vlan_present ? 5'd18 : 5'd14;

  // Valid follows fields_valid
  assign vlan_valid = fields_valid;

endmodule
