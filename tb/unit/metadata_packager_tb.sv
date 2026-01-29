// ============================================================
// Testbench: metadata_packager_tb
// Purpose : Unit test for struct-based metadata_packager
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module metadata_packager_tb;

  // ----------------------------------------------------------
  // Clock / Reset
  // ----------------------------------------------------------
  logic clk;
  logic rst_n;

  always #5 clk = ~clk;

  // ----------------------------------------------------------
  // Inputs
  // ----------------------------------------------------------
  mac_addr_t   dest_mac;
  mac_addr_t   src_mac;
  logic        vlan_present;
  logic [11:0] vlan_id;
  ethertype_t  resolved_ethertype;
  logic [4:0]  l2_header_len;

  logic        proto_valid;
  logic        is_ipv4;
  logic        is_ipv6;
  logic        is_arp;
  logic        is_unknown;

  // ----------------------------------------------------------
  // Outputs
  // ----------------------------------------------------------
  eth_metadata_t metadata;
  logic          metadata_valid;

  // ----------------------------------------------------------
  // DUT
  // ----------------------------------------------------------
  metadata_packager dut (
    .clk                (clk),
    .rst_n              (rst_n),
    .frame_start        (1'b1),
    .frame_end          (1'b1),

    .dest_mac           (dest_mac),
    .src_mac            (src_mac),
    .vlan_present       (vlan_present),
    .vlan_id            (vlan_id),
    .resolved_ethertype (resolved_ethertype),
    .l2_header_len      (l2_header_len),

    .proto_valid        (proto_valid),
    .is_ipv4            (is_ipv4),
    .is_ipv6            (is_ipv6),
    .is_arp             (is_arp),
    .is_unknown         (is_unknown),

    .metadata           (metadata),
    .metadata_valid     (metadata_valid)
  );

  // ----------------------------------------------------------
  // Test sequence
  // ----------------------------------------------------------
  initial begin
    clk = 0;
    rst_n = 0;

    dest_mac           = '0;
    src_mac            = '0;
    vlan_present       = 0;
    vlan_id            = '0;
    resolved_ethertype = '0;
    l2_header_len      = '0;

    proto_valid = 0;
    is_ipv4     = 0;
    is_ipv6     = 0;
    is_arp      = 0;
    is_unknown  = 0;

    repeat (3) @(posedge clk);
    rst_n = 1;

    $display("=== metadata_packager UNIT TEST ===");

    // ------------------------------------------------------
    // Drive valid metadata
    // ------------------------------------------------------
    dest_mac           = 48'hAAAAAAAAAAAA;
    src_mac            = 48'hBBBBBBBBBBBB;
    vlan_present       = 1'b1;
    vlan_id            = 12'h123;
    resolved_ethertype = 16'h0800;
    l2_header_len      = 5'd18;

    is_ipv4     = 1'b1;
    is_ipv6     = 1'b0;
    is_arp      = 1'b0;
    is_unknown  = 1'b0;

    // ------------------------------------------------------
    // Assert proto_valid (metadata must be emitted THIS cycle)
    // ------------------------------------------------------
    @(posedge clk);
    proto_valid = 1'b1;

    @(posedge clk);
    if (!metadata_valid)
      $fatal(1, "FAIL: metadata_valid not asserted");

    proto_valid = 1'b0;

    // ------------------------------------------------------
    // Checks
    // ------------------------------------------------------
    if (metadata.dest_mac !== dest_mac)
      $fatal(1, "FAIL: dest_mac mismatch");

    if (metadata.src_mac !== src_mac)
      $fatal(1, "FAIL: src_mac mismatch");

    if (!metadata.vlan_present || metadata.vlan_id !== vlan_id)
      $fatal(1, "FAIL: VLAN fields incorrect");

    if (metadata.ethertype !== resolved_ethertype)
      $fatal(1, "FAIL: ethertype mismatch");

    if (!metadata.is_ipv4 || metadata.is_unknown)
      $fatal(1, "FAIL: protocol flags incorrect");

    $display("✔ metadata_packager UNIT TEST PASSED");
    #20;
    $finish;
  end

endmodule
