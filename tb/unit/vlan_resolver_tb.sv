// ============================================================
// Testbench: vlan_resolver_tb
// Purpose  : Unit test for VLAN detection and resolution
// ============================================================

`timescale 1ns/1ps

module vlan_resolver_tb;

  // DUT inputs
  logic [17:0][7:0] header_bytes;
  logic [15:0]      ethertype_raw;
  logic             fields_valid;

  // DUT outputs
  logic             vlan_present;
  logic [11:0]      vlan_id;
  logic [15:0]      resolved_ethertype;
  logic [4:0]       l2_header_len;
  logic             vlan_valid;

  // DUT
  vlan_resolver dut (
    .header_bytes       (header_bytes),
    .ethertype_raw      (ethertype_raw),
    .fields_valid       (fields_valid),
    .vlan_present       (vlan_present),
    .vlan_id            (vlan_id),
    .resolved_ethertype (resolved_ethertype),
    .l2_header_len      (l2_header_len),
    .vlan_valid         (vlan_valid)
  );

  integer i;

  initial begin
    // Clear inputs
    for (i = 0; i < 18; i = i + 1)
      header_bytes[i] = 8'h00;

    ethertype_raw = 16'h0000;
    fields_valid  = 1'b0;

    // ======================================================
    // TEST 1: Non-VLAN IPv4 Ethernet II
    // ======================================================
    $display("=== vlan_resolver TEST 1: Non-VLAN IPv4 ===");

    ethertype_raw = 16'h0800; // IPv4
    fields_valid  = 1'b1;
    #1;

    if (!vlan_valid)
      $fatal(1, "FAIL: vlan_valid not asserted");

    if (vlan_present !== 1'b0)
      $fatal(1, "FAIL: vlan_present should be 0");

    if (resolved_ethertype !== 16'h0800)
      $fatal(1, "FAIL: resolved_ethertype incorrect");

    if (l2_header_len !== 5'd14)
      $fatal(1, "FAIL: l2_header_len should be 14");

    // ======================================================
    // TEST 2: VLAN-tagged IPv4
    // VLAN ID = 100 (0x064)
    // ======================================================
    $display("=== vlan_resolver TEST 2: VLAN IPv4 ===");

    // VLAN ethertype
    ethertype_raw = 16'h8100;

    // VLAN TCI = 0x0064 → VLAN ID = 100
    header_bytes[14] = 8'h00;
    header_bytes[15] = 8'h64;

    // Inner ethertype = IPv4
    header_bytes[16] = 8'h08;
    header_bytes[17] = 8'h00;

    fields_valid = 1'b1;
    #1;

    if (!vlan_valid)
      $fatal(1, "FAIL: vlan_valid not asserted");

    if (vlan_present !== 1'b1)
      $fatal(1, "FAIL: vlan_present not detected");

    if (vlan_id !== 12'd100)
      $fatal(1, "FAIL: vlan_id incorrect: %0d", vlan_id);

    if (resolved_ethertype !== 16'h0800)
      $fatal(1, "FAIL: resolved_ethertype incorrect");

    if (l2_header_len !== 5'd18)
      $fatal(1, "FAIL: l2_header_len should be 18");

    $display("✔ vlan_resolver UNIT TEST PASSED");
    $finish;
  end

endmodule
