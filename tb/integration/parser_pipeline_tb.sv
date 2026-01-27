// ============================================================
// Testbench: parser_pipeline_tb
// Purpose  : Integrate Ethernet parser pipeline (no AXI)
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module parser_pipeline_tb;

  // ----------------------------------------------------------
  // Clock / Reset
  // ----------------------------------------------------------
  logic clk;
  logic rst_n;

  always #5 clk = ~clk;

  // ----------------------------------------------------------
  // Stimulus control
  // ----------------------------------------------------------
  logic frame_start;
  logic frame_end;
  logic beat_accept;

  // ----------------------------------------------------------
  // Data path
  // ----------------------------------------------------------
  logic [63:0] axis_tdata;

  // ----------------------------------------------------------
  // Header shift register outputs
  // ----------------------------------------------------------
  logic [17:0][7:0] header_bytes;
  logic             header_valid;

  // ----------------------------------------------------------
  // Parsed header fields
  // ----------------------------------------------------------
  mac_addr_t   dest_mac;
  mac_addr_t   src_mac;
  ethertype_t  ethertype_raw;
  logic        fields_valid;

  // ----------------------------------------------------------
  // VLAN resolver
  // ----------------------------------------------------------
  logic        vlan_present;
  logic [11:0] vlan_id;
  ethertype_t  resolved_ethertype;
  logic [4:0]  l2_header_len;
  logic        vlan_valid;

  // ----------------------------------------------------------
  // Protocol classifier
  // ----------------------------------------------------------
  logic is_ipv4, is_ipv6, is_arp, is_unknown;
  logic proto_valid;

  // ----------------------------------------------------------
  // Metadata output (CANONICAL)
  // ----------------------------------------------------------
  eth_metadata_t metadata;
  logic          metadata_valid;

  // ----------------------------------------------------------
  // DUT instances
  // ----------------------------------------------------------

  header_shift_register u_shift (
    .clk          (clk),
    .rst_n        (rst_n),
    .beat_accept  (beat_accept),
    .frame_start  (frame_start),
    .axis_tdata   (axis_tdata),
    .header_bytes (header_bytes),
    .header_valid (header_valid)
  );

  eth_header_parser u_hdr (
    .header_bytes  (header_bytes),
    .header_valid  (header_valid),
    .dest_mac      (dest_mac),
    .src_mac       (src_mac),
    .ethertype_raw (ethertype_raw),
    .fields_valid  (fields_valid)
  );

  vlan_resolver u_vlan (
    .header_bytes       (header_bytes),
    .ethertype_raw      (ethertype_raw),
    .fields_valid       (fields_valid),
    .vlan_present       (vlan_present),
    .vlan_id            (vlan_id),
    .resolved_ethertype (resolved_ethertype),
    .l2_header_len      (l2_header_len),
    .vlan_valid         (vlan_valid)
  );

  protocol_classifier u_proto (
    .resolved_ethertype (resolved_ethertype),
    .vlan_valid         (vlan_valid),
    .is_ipv4            (is_ipv4),
    .is_ipv6            (is_ipv6),
    .is_arp             (is_arp),
    .is_unknown         (is_unknown),
    .proto_valid        (proto_valid)
  );

  metadata_packager u_meta (
    .clk                (clk),
    .rst_n              (rst_n),
    .frame_start        (frame_start),
    .frame_end          (frame_end),
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
    frame_start = 0;
    frame_end   = 0;
    beat_accept = 0;
    axis_tdata  = 64'd0;

    repeat (3) @(posedge clk);
    rst_n = 1;

    $display("=== Parser Pipeline Integration Test ===");

    // Start frame
    frame_start = 1;
    @(posedge clk);
    frame_start = 0;

    // Beat 0: dest MAC + part src
    beat_accept = 1;
    axis_tdata  = 64'hFFFFFFFFFFFF0011;
    @(posedge clk);

    // Beat 1: rest src + ethertype (IPv4)
    axis_tdata  = 64'h2233445508000000;
    @(posedge clk);

    // Beat 2: padding
    axis_tdata  = 64'h0000000000000000;
    @(posedge clk);
    beat_accept = 0;

    // Wait for metadata_valid
    repeat (5) @(posedge clk);

    if (!metadata_valid)
      $fatal(1, "FAIL: metadata_valid not asserted");

    if (metadata.dest_mac !== 48'hFFFFFFFFFFFF)
      $fatal(1, "FAIL: dest_mac mismatch");

    if (metadata.src_mac !== 48'h001122334455)
      $fatal(1, "FAIL: src_mac mismatch");

    if (metadata.ethertype !== 16'h0800)
      $fatal(1, "FAIL: ethertype mismatch");

    if (!metadata.is_ipv4)
      $fatal(1, "FAIL: IPv4 not detected");

    $display("✔ Parser pipeline integration PASSED");
    $finish;
  end

endmodule
