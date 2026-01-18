// ============================================================
// Module: metadata_packager
// Purpose: One-shot metadata latch per frame (portable)
// ============================================================

`timescale 1ns/1ps

module metadata_packager (
  input  logic        clk,
  input  logic        rst_n,

  // Frame control
  input  logic        frame_start,
  input  logic        frame_end,

  // Parsed inputs
  input  logic [47:0] dest_mac,
  input  logic [47:0] src_mac,
  input  logic [15:0] resolved_ethertype,
  input  logic        vlan_present,
  input  logic [11:0] vlan_id,
  input  logic [4:0]  l2_header_len,

  input  logic        proto_valid,
  input  logic        is_ipv4,
  input  logic        is_ipv6,
  input  logic        is_arp,
  input  logic        is_unknown,

  // Metadata outputs (flattened)
  output logic [47:0] meta_dest_mac,
  output logic [47:0] meta_src_mac,
  output logic [15:0] meta_ethertype,
  output logic        meta_vlan_present,
  output logic [11:0] meta_vlan_id,
  output logic [4:0]  meta_l2_header_len,
  output logic        meta_is_ipv4,
  output logic        meta_is_ipv6,
  output logic        meta_is_arp,
  output logic        meta_is_unknown,
  output logic        metadata_valid
);

  logic latched;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      latched        <= 1'b0;
      metadata_valid <= 1'b0;

      meta_dest_mac       <= 48'h0;
      meta_src_mac        <= 48'h0;
      meta_ethertype      <= 16'h0;
      meta_vlan_present   <= 1'b0;
      meta_vlan_id        <= 12'h0;
      meta_l2_header_len  <= 5'h0;
      meta_is_ipv4        <= 1'b0;
      meta_is_ipv6        <= 1'b0;
      meta_is_arp         <= 1'b0;
      meta_is_unknown     <= 1'b0;
    end
    else begin
      // New frame clears latch
      if (frame_start) begin
        latched        <= 1'b0;
        metadata_valid <= 1'b0;
      end

      // Latch metadata once per frame
      if (proto_valid && !latched) begin
        meta_dest_mac      <= dest_mac;
        meta_src_mac       <= src_mac;
        meta_ethertype     <= resolved_ethertype;
        meta_vlan_present  <= vlan_present;
        meta_vlan_id       <= vlan_id;
        meta_l2_header_len <= l2_header_len;

        meta_is_ipv4       <= is_ipv4;
        meta_is_ipv6       <= is_ipv6;
        meta_is_arp        <= is_arp;
        meta_is_unknown    <= is_unknown;

        metadata_valid <= 1'b1;
        latched        <= 1'b1;
      end

      // Clear at frame end
      if (frame_end) begin
        metadata_valid <= 1'b0;
      end
    end
  end

endmodule
