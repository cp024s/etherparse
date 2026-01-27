// ============================================================
// Testbench: parser_pipeline_tb
// Purpose  : Integrate Ethernet parser pipeline (no AXI)
//            LSB-first byte ordering (canonical)
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
  mac_addr_t  dest_mac;
  mac_addr_t  src_mac;
  ethertype_t ethertype_raw;
  logic       fields_valid;

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
  // Metadata outputs
  // ----------------------------------------------------------
  eth_metadata_t metadata;
  logic          metadata_valid;

  // ----------------------------------------------------------
  // Helper: pack bytes LSB-first
  // ----------------------------------------------------------
  function automatic [63:0] pack8 (
    input byte b0,b1,b2,b3,b4,b5,b6,b7
  );
    pack8 = {b7,b6,b5,b4,b3,b2,b1,b0};
  endfunction

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
    .resolved_ethertype (resolved_ethertype),
    .vlan_present       (vlan_present),
    .vlan_id            (vlan_id),
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
    frame_end = 0;
    beat_accept = 0;
    axis_tdata = 64'd0;

    repeat (3) @(posedge clk);
    rst_n = 1;

    $display("=== Parser Pipeline Integration Test ===");

    // ------------------------------------------------------
    // Start frame
    // ------------------------------------------------------
    frame_start = 1;
    @(posedge clk);
    frame_start = 0;

    // ------------------------------------------------------
    // Beat 0: Dest MAC FF:FF:FF:FF:FF:FF + 00 11
    // ------------------------------------------------------
    beat_accept = 1;
    axis_tdata = pack8(
      8'hFF,8'hFF,8'hFF,8'hFF,
      8'hFF,8'hFF,8'h00,8'h11
    );
    @(posedge clk);

    // ------------------------------------------------------
    // Beat 1: Src MAC 22:33:44:55 + Ethertype 08 00
    // ------------------------------------------------------
    axis_tdata = pack8(
      8'h22,8'h33,8'h44,8'h55,
      8'h08,8'h00,8'h00,8'h00
    );
    @(posedge clk);

    // ------------------------------------------------------
    // Beat 2: Padding
    // ------------------------------------------------------
    axis_tdata = pack8(
      8'h00,8'h00,8'h00,8'h00,
      8'h00,8'h00,8'h00,8'h00
    );
    @(posedge clk);

    beat_accept = 0;

    // ------------------------------------------------------
    // Wait for metadata
    // ------------------------------------------------------
    repeat (5) @(posedge clk);

    if (!metadata_valid)
      $fatal(1, "FAIL: metadata_valid not asserted");

    if (metadata.dest_mac !== 48'hFFFFFFFFFFFF)
      $fatal(1, "FAIL: dest_mac mismatch");

    if (metadata.src_mac !== 48'h001122334455)
      $fatal(1, "FAIL: src_mac mismatch");

    if (!metadata.is_ipv4)
      $fatal(1, "FAIL: IPv4 not detected");

    // ------------------------------------------------------
    // End frame
    // ------------------------------------------------------
    frame_end = 1;
    @(posedge clk);
    frame_end = 0;

    $display("✔ Parser pipeline integration PASSED");
    $finish;
  end

endmodule
