// ============================================================
// Module: metadata_packager
// Purpose: Assemble parsed Ethernet metadata into a single
//          canonical eth_metadata_t struct
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module metadata_packager (
  input  logic         clk,
  input  logic         rst_n,

  // Frame lifecycle (used for future extensions)
  input  logic         frame_start,
  input  logic         frame_end,

  // Parsed fields
  input  mac_addr_t    dest_mac,
  input  mac_addr_t    src_mac,

  input  logic         vlan_present,
  input  logic [11:0]  vlan_id,
  input  ethertype_t   resolved_ethertype,
  input  logic [4:0]   l2_header_len,

  // Protocol classification
  input  logic         proto_valid,
  input  logic         is_ipv4,
  input  logic         is_ipv6,
  input  logic         is_arp,
  input  logic         is_unknown,

  // Canonical metadata output
  output eth_metadata_t metadata,
  output logic          metadata_valid
);

  // ----------------------------------------------------------
  // Metadata register
  // ----------------------------------------------------------

  eth_metadata_t metadata_r;

  // ----------------------------------------------------------
  // Sequential logic
  // ----------------------------------------------------------

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      metadata_r      <= '0;
      metadata_valid  <= 1'b0;
    end
    else begin
      // Default: metadata_valid is a pulse
      metadata_valid <= 1'b0;

      // Emit metadata once protocol is resolved
      if (proto_valid) begin
        metadata_r.dest_mac      <= dest_mac;
        metadata_r.src_mac       <= src_mac;
        metadata_r.ethertype     <= resolved_ethertype;
        metadata_r.vlan_present  <= vlan_present;
        metadata_r.vlan_id       <= vlan_id;
        metadata_r.l2_header_len <= l2_header_len;

        metadata_r.is_ipv4       <= is_ipv4;
        metadata_r.is_ipv6       <= is_ipv6;
        metadata_r.is_arp        <= is_arp;
        metadata_r.is_unknown    <= is_unknown;

        metadata_valid           <= 1'b1;
      end
    end
  end

  // ----------------------------------------------------------
  // Output assignment
  // ----------------------------------------------------------

  assign metadata = metadata_r;

endmodule
