// ============================================================
// Module: metadata_packager
// Purpose: Latch parsed Ethernet metadata once per frame
//          (FIXED: race-free proto_valid handling)
// ============================================================

`timescale 1ns/1ps

module metadata_packager (
  input  logic        clk,
  input  logic        rst_n,

  // Frame lifecycle
  input  logic        frame_start,
  input  logic        frame_end,

  // Parsed fields
  input  logic [47:0] dest_mac,
  input  logic [47:0] src_mac,
  input  logic [15:0] resolved_ethertype,
  input  logic        vlan_present,
  input  logic [11:0] vlan_id,
  input  logic [4:0]  l2_header_len,

  // Protocol classification
  input  logic        proto_valid,
  input  logic        is_ipv4,
  input  logic        is_ipv6,
  input  logic        is_arp,
  input  logic        is_unknown,

  // Output metadata
  output logic [47:0] meta_dest_mac,
  output logic        metadata_valid
);

  // ----------------------------------------------------------
  // Internal state
  // ----------------------------------------------------------
  logic latched;
  logic proto_valid_d;

  // ----------------------------------------------------------
  // Register proto_valid to avoid combinational race
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      proto_valid_d <= 1'b0;
    else
      proto_valid_d <= proto_valid;
  end

  // ----------------------------------------------------------
  // Metadata latch logic
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      latched        <= 1'b0;
      metadata_valid <= 1'b0;
      meta_dest_mac <= '0;
    end
    else begin
      // Clear state at start of frame
      if (frame_start) begin
        latched        <= 1'b0;
        metadata_valid <= 1'b0;
      end

      // Latch metadata ONCE per frame
      else if (proto_valid_d && !latched) begin
        meta_dest_mac <= dest_mac;
        metadata_valid <= 1'b1;
        latched        <= 1'b1;
      end

      // Metadata remains valid until next frame_start
    end
  end

endmodule
