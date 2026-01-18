// ============================================================
// Testbench: metadata_packager_tb
// Purpose  : Unit test for metadata latching semantics
// ============================================================

`timescale 1ns/1ps

module metadata_packager_tb;

  // Clock / Reset
  logic clk;
  logic rst_n;

  always #5 clk = ~clk;

  // Frame control
  logic frame_start;
  logic frame_end;

  // Parsed inputs
  logic [47:0] dest_mac;
  logic [47:0] src_mac;
  logic [15:0] resolved_ethertype;
  logic        vlan_present;
  logic [11:0] vlan_id;
  logic [4:0]  l2_header_len;

  logic proto_valid;
  logic is_ipv4;
  logic is_ipv6;
  logic is_arp;
  logic is_unknown;

  // Metadata outputs
  logic [47:0] meta_dest_mac;
  logic [47:0] meta_src_mac;
  logic [15:0] meta_ethertype;
  logic        meta_vlan_present;
  logic [11:0] meta_vlan_id;
  logic [4:0]  meta_l2_header_len;
  logic        meta_is_ipv4;
  logic        meta_is_ipv6;
  logic        meta_is_arp;
  logic        meta_is_unknown;
  logic        metadata_valid;

  // DUT
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
    .meta_src_mac       (meta_src_mac),
    .meta_ethertype     (meta_ethertype),
    .meta_vlan_present  (meta_vlan_present),
    .meta_vlan_id       (meta_vlan_id),
    .meta_l2_header_len (meta_l2_header_len),
    .meta_is_ipv4       (meta_is_ipv4),
    .meta_is_ipv6       (meta_is_ipv6),
    .meta_is_arp        (meta_is_arp),
    .meta_is_unknown    (meta_is_unknown),
    .metadata_valid     (metadata_valid)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    frame_start = 0;
    frame_end   = 0;
    proto_valid = 0;

    dest_mac = 48'hDEADBEEFCAFE;
    src_mac  = 48'h001122334455;
    resolved_ethertype = 16'h0800;
    vlan_present = 1'b0;
    vlan_id = 12'd0;
    l2_header_len = 5'd14;

    is_ipv4 = 1'b1;
    is_ipv6 = 1'b0;
    is_arp  = 1'b0;
    is_unknown = 1'b0;

    repeat (2) @(posedge clk);
    rst_n = 1;

    $display("=== metadata_packager UNIT TEST ===");

    // Start frame
    frame_start = 1'b1;
    @(posedge clk);
    frame_start = 1'b0;

    // Latch metadata
    proto_valid = 1'b1;
    @(posedge clk);
    proto_valid = 1'b0;

    if (!metadata_valid)
      $fatal(1, "FAIL: metadata_valid not asserted");

    if (meta_dest_mac !== dest_mac)
      $fatal(1, "FAIL: dest_mac not latched correctly");

    // Attempt illegal re-latch
    dest_mac = 48'hFFFFFFFFFFFF;
    proto_valid = 1'b1;
    @(posedge clk);
    proto_valid = 1'b0;

    if (meta_dest_mac !== 48'hDEADBEEFCAFE)
      $fatal(1, "FAIL: metadata re-latched illegally");

    // End frame
    frame_end = 1'b1;
    @(posedge clk);
    frame_end = 1'b0;

    if (metadata_valid)
      $fatal(1, "FAIL: metadata_valid not cleared at frame_end");

    $display("✔ metadata_packager UNIT TEST PASSED");
    $finish;
  end

endmodule
