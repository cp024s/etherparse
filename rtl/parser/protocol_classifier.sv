// ============================================================
// Module: protocol_classifier
// Purpose: Classify Ethernet payload protocol
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module protocol_classifier (
  input  ethertype_t resolved_ethertype,
  input  logic       vlan_valid,

  output logic       is_ipv4,
  output logic       is_ipv6,
  output logic       is_arp,
  output logic       is_unknown,
  output logic       proto_valid
);

  always_comb begin
    // Defaults
    is_ipv4    = 1'b0;
    is_ipv6    = 1'b0;
    is_arp     = 1'b0;
    is_unknown = 1'b0;
    proto_valid = 1'b0;

    if (vlan_valid) begin
      proto_valid = 1'b1;

      case (resolved_ethertype)
        ETHERTYPE_IPV4: is_ipv4 = 1'b1;
        ETHERTYPE_IPV6: is_ipv6 = 1'b1;
        ETHERTYPE_ARP : is_arp  = 1'b1;
        default       : is_unknown = 1'b1;
      endcase
    end
  end

endmodule
