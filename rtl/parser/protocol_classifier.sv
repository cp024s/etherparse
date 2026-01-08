// ============================================================
// Module: protocol_classifier
// Purpose: Classify Ethernet payload protocol
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module protocol_classifier (
  input  logic        clk,
  input  logic        rst_n,

  // Trigger from VLAN resolver
  input  logic        vlan_valid,
  input  ethertype_t  resolved_ethertype,

  // Classification outputs
  output logic is_ipv4,
  output logic is_ipv6,
  output logic is_arp,
  output logic is_unknown,
  output logic proto_valid
);

  // EtherType constants
  localparam ethertype_t ETH_IPV4 = 16'h0800;
  localparam ethertype_t ETH_IPV6 = 16'h86DD;
  localparam ethertype_t ETH_ARP  = 16'h0806;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      is_ipv4    <= 1'b0;
      is_ipv6    <= 1'b0;
      is_arp     <= 1'b0;
      is_unknown <= 1'b0;
      proto_valid<= 1'b0;
    end
    else if (vlan_valid && !proto_valid) begin
      // Default
      is_ipv4    <= 1'b0;
      is_ipv6    <= 1'b0;
      is_arp     <= 1'b0;
      is_unknown <= 1'b0;

      case (resolved_ethertype)
        ETH_IPV4: is_ipv4 <= 1'b1;
        ETH_IPV6: is_ipv6 <= 1'b1;
        ETH_ARP : is_arp  <= 1'b1;
        default : is_unknown <= 1'b1;
      endcase

      proto_valid <= 1'b1;
    end
  end

endmodule
