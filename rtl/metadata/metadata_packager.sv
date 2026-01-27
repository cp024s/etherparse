// ============================================================
// Module: metadata_packager
// Purpose: Assemble parsed Ethernet metadata into a single
//          canonical eth_metadata_t struct
// ============================================================

`timescale 1ns/1ps
/* verilator lint_off IMPORTSTAR */
import eth_parser_pkg::*;
/* verilator lint_on IMPORTSTAR */

module metadata_packager (
  input  logic         clk,
  input  logic         rst_n,

  // Frame lifecycle
  input  logic         frame_start,
  /* verilator lint_off UNUSED */
  input  logic         frame_end,
  /* verilator lint_on UNUSED */

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

  // Output
  output eth_metadata_t metadata,
  output logic          metadata_valid
);

  eth_metadata_t metadata_r;
  logic          metadata_emitted;

  // ----------------------------------------------------------
  // Sequential logic
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      metadata_r        <= '0;
      metadata_valid    <= 1'b0;
      metadata_emitted  <= 1'b0;
    end
    else begin
      metadata_valid <= 1'b0;

      // Reset per frame
      if (frame_start)
        metadata_emitted <= 1'b0;

      // Latch metadata once per frame
      if (proto_valid && !metadata_emitted) begin
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

        metadata_valid   <= 1'b1;
        metadata_emitted <= 1'b1;
      end
    end
  end

  assign metadata = metadata_r;

`ifndef SYNTHESIS
  // ----------------------------------------------------------
  // Immediate assertions (Verilator-safe)
  // ----------------------------------------------------------
  always_ff @(posedge clk) begin
    if (metadata_valid) begin
      assert (metadata_emitted)
        else $fatal("METADATA: metadata_valid without emit flag");

      assert (!$isunknown(metadata))
        else $fatal("METADATA: metadata contains X");
    end
  end
`endif

endmodule
