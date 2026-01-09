// ============================================================
// Module: metadata_packager
// Purpose: Assemble Ethernet metadata as soon as parsing completes
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module metadata_packager (
  input  logic        clk,
  input  logic        rst_n,

  // Parsing status
  input  logic        fields_valid,
  input  logic        vlan_valid,
  input  logic        proto_valid,

  // Header fields
  input  mac_addr_t   dest_mac,
  input  mac_addr_t   src_mac,

  // VLAN
  input  logic        vlan_present,
  input  logic [11:0] vlan_id,
  input  ethertype_t  resolved_ethertype,
  input  logic [4:0]  l2_header_len,

  // Protocol
  input  logic        is_ipv4,
  input  logic        is_ipv6,
  input  logic        is_arp,
  input  logic        is_unknown,

  // Output metadata
  output eth_metadata_t metadata,
  output logic          metadata_valid
);

  logic fired;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      metadata       <= '0;
      metadata_valid <= 1'b0;
      fired          <= 1'b0;
    end
    else if (!fired && fields_valid && vlan_valid && proto_valid) begin
      metadata.dest_mac        <= dest_mac;
      metadata.src_mac         <= src_mac;
      metadata.vlan_present    <= vlan_present;
      metadata.vlan_id         <= vlan_id;
      metadata.ethertype       <= resolved_ethertype;
      metadata.l2_header_len   <= l2_header_len;
      metadata.is_ipv4         <= is_ipv4;
      metadata.is_ipv6         <= is_ipv6;
      metadata.is_arp          <= is_arp;
      metadata.is_unknown      <= is_unknown;

      metadata_valid <= 1'b1;
      fired          <= 1'b0; // stays valid for frame lifetime
    end
  end

endmodule
