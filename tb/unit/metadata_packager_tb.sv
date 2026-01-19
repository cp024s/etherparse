// ============================================================
// Testbench: metadata_packager_tb
// Purpose : Verify metadata_valid timing and single emission
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module metadata_packager_tb;

  logic clk;
  logic rst_n;

  // Inputs
  logic        frame_start;
  logic        frame_end;
  mac_addr_t   dest_mac;
  mac_addr_t   src_mac;
  ethertype_t  resolved_ethertype;
  logic        vlan_present;
  logic [11:0] vlan_id;
  logic [4:0]  l2_header_len;
  logic        proto_valid;
  logic        is_ipv4, is_ipv6, is_arp, is_unknown;

  // Outputs
  mac_addr_t   meta_dest_mac;
  logic        metadata_valid;

  always #5 clk = ~clk;

  metadata_packager dut (
    .clk                (clk),
    .rst_n              (rst_n),
    .frame_start        (frame_start),
    .frame_end          (frame_end),
    .dest_mac           (dest_mac),
    .src_mac            (src_mac),
    .resolved_ethertype (resolved_ethertype),
    .vlan_present       (vlan_present),
    .vlan_id            (vlan_id),
    .l2_header_len      (l2_header_len),
    .proto_valid        (proto_valid),
    .is_ipv4            (is_ipv4),
    .is_ipv6            (is_ipv6),
    .is_arp             (is_arp),
    .is_unknown         (is_unknown),
    .meta_dest_mac      (meta_dest_mac),
    .metadata_valid     (metadata_valid)
  );

  initial begin
    clk = 0;
    rst_n = 0;

    frame_start = 0;
    frame_end   = 0;
    dest_mac    = 48'hAABBCCDDEEFF;
    src_mac     = 48'h001122334455;
    resolved_ethertype = 16'h0800;
    vlan_present = 0;
    vlan_id      = 0;
    l2_header_len = 14;
    proto_valid  = 0;
    is_ipv4 = 1;
    is_ipv6 = 0;
    is_arp  = 0;
    is_unknown = 0;

    repeat (2) @(posedge clk);
    rst_n = 1;

    $display("=== metadata_packager UNIT TEST ===");

    // Start of frame
    frame_start = 1;
    @(posedge clk);
    frame_start = 0;

    // Protocol becomes valid
    proto_valid = 1;
    @(posedge clk);
    proto_valid = 0;

    // Metadata must assert exactly once
    if (!metadata_valid)
      $fatal(1, "FAIL: metadata_valid not asserted");

    if (meta_dest_mac !== dest_mac)
      $fatal(1, "FAIL: meta_dest_mac mismatch");

    @(posedge clk);
    if (metadata_valid)
      $fatal(1, "FAIL: metadata_valid asserted more than once");

    $display("✔ metadata_packager UNIT TEST PASSED");
    $finish;
  end

endmodule
