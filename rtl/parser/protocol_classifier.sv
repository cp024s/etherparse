// ============================================================
// Module: protocol_classifier
// Purpose: Classify Ethernet frame based on resolved EtherType
// ============================================================

`timescale 1ns/1ps

import eth_parser_pkg::*;

module protocol_classifier (
  input  logic clk,
  input  logic rst_n,

  // Inputs
  input  logic        vlan_valid,
  input  ethertype_t resolved_ethertype,

  // Protocol classification outputs
  output logic is_ipv4,
  output logic is_ipv6,
  output logic is_arp,
  output logic is_unknown,
  output logic proto_valid
);

  // ----------------------------------------------------------
  // Protocol classification logic
  // ----------------------------------------------------------

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      is_ipv4   <= 1'b0;
      is_ipv6   <= 1'b0;
      is_arp    <= 1'b0;
      is_unknown<= 1'b0;
      proto_valid <= 1'b0;
    end
    else if (vlan_valid && !proto_valid) begin
      // Clear previous classification
      is_ipv4    <= 1'b0;
      is_ipv6    <= 1'b0;
      is_arp     <= 1'b0;
      is_unknown <= 1'b0;

      case (resolved_ethertype)
        ETHERTYPE_IPV4: is_ipv4 <= 1'b1;
        ETHERTYPE_IPV6: is_ipv6 <= 1'b1;
        ETHERTYPE_ARP:  is_arp  <= 1'b1;
        default:        is_unknown <= 1'b1;
      endcase

      proto_valid <= 1'b1;
    end
    else if (!vlan_valid) begin
      // Reset validity when upstream parsing resets
      proto_valid <= 1'b0;
    end
  end

endmodule
