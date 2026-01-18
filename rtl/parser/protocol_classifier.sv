// ============================================================
// Module: protocol_classifier
// Purpose: Classify Ethernet payload protocol (portable)
// ============================================================

`timescale 1ns/1ps

module protocol_classifier (
  input  logic [15:0] resolved_ethertype,
  input  logic        vlan_valid,

  output logic        is_ipv4,
  output logic        is_ipv6,
  output logic        is_arp,
  output logic        is_unknown,
  output logic        proto_valid
);

  // proto_valid strictly follows vlan_valid
  assign proto_valid = vlan_valid;

  // Protocol decode (only valid when vlan_valid=1)
  assign is_ipv4    = vlan_valid && (resolved_ethertype == 16'h0800);
  assign is_ipv6    = vlan_valid && (resolved_ethertype == 16'h86DD);
  assign is_arp     = vlan_valid && (resolved_ethertype == 16'h0806);
  assign is_unknown = vlan_valid &&
                      (resolved_ethertype != 16'h0800) &&
                      (resolved_ethertype != 16'h86DD) &&
                      (resolved_ethertype != 16'h0806);

endmodule
