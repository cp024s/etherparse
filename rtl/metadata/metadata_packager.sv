// ============================================================
// Module: metadata_packager
// Purpose: Latch and emit Ethernet metadata once per frame
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module metadata_packager (
  input  logic        clk,
  input  logic        rst_n,

  // Frame lifecycle
  input  logic        frame_start,
  input  logic        frame_end,

  // Parsed header fields
  input  mac_addr_t   dest_mac,
  input  mac_addr_t   src_mac,
  input  ethertype_t  resolved_ethertype,
  input  logic        vlan_present,
  input  logic [11:0] vlan_id,
  input  logic [4:0]  l2_header_len,

  // Protocol classification
  input  logic        proto_valid,
  input  logic        is_ipv4,
  input  logic        is_ipv6,
  input  logic        is_arp,
  input  logic        is_unknown,

  // Outputs
  output mac_addr_t   meta_dest_mac,
  output logic        metadata_valid
);

  // ----------------------------------------------------------
  // Internal state
  // ----------------------------------------------------------
  logic metadata_sent;

  // ----------------------------------------------------------
  // Metadata generation logic
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      metadata_valid <= 1'b0;
      metadata_sent  <= 1'b0;
      meta_dest_mac  <= '0;
    end
    else begin
      // Reset metadata state at start of every frame
      if (frame_start) begin
        metadata_valid <= 1'b0;
        metadata_sent  <= 1'b0;
      end

      // Emit metadata exactly once per frame
      if (proto_valid && !metadata_sent) begin
        meta_dest_mac  <= dest_mac;
        metadata_valid <= 1'b1;
        metadata_sent  <= 1'b1;
      end
      else begin
        metadata_valid <= 1'b0;
      end
    end
  end

endmodule
