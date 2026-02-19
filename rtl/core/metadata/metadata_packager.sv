// ============================================================
// Module: metadata_packager
// Purpose: Emit metadata once per frame (schema-correct)
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module metadata_packager (
  input  logic        clk,
  input  logic        rst_n,

  input  logic        frame_start,
  input  logic        frame_end,

  input  mac_addr_t   dest_mac,
  input  mac_addr_t   src_mac,
  input  logic        vlan_present,
  input  logic [11:0] vlan_id,

  input  logic        proto_valid,
  input  logic        is_ipv4,
  input  logic        is_ipv6,
  input  logic        is_arp,
  input  logic        is_unknown,

  output eth_metadata_t metadata,
  output logic          metadata_valid
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      metadata       <= '0;
      metadata_valid <= 1'b0;
    end else begin
      metadata_valid <= 1'b0;

      // Emit metadata ONCE per frame
      if (frame_end && proto_valid) begin
        metadata.dest_mac     <= dest_mac;
        metadata.src_mac      <= src_mac;
        metadata.vlan_present <= vlan_present;
        metadata.vlan_id      <= vlan_id;

        metadata.is_ipv4      <= is_ipv4;
        metadata.is_ipv6      <= is_ipv6;
        metadata.is_arp       <= is_arp;
        metadata.is_unknown   <= is_unknown;

        metadata_valid <= 1'b1;
      end
    end
  end

endmodule
