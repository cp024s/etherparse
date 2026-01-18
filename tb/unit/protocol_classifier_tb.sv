// ============================================================
// Testbench: protocol_classifier_tb
// Purpose  : Unit test for protocol classification
// ============================================================

`timescale 1ns/1ps

module protocol_classifier_tb;

  // DUT inputs
  logic [15:0] resolved_ethertype;
  logic        vlan_valid;

  // DUT outputs
  logic is_ipv4;
  logic is_ipv6;
  logic is_arp;
  logic is_unknown;
  logic proto_valid;

  // DUT
  protocol_classifier dut (
    .resolved_ethertype (resolved_ethertype),
    .vlan_valid         (vlan_valid),
    .is_ipv4            (is_ipv4),
    .is_ipv6            (is_ipv6),
    .is_arp             (is_arp),
    .is_unknown         (is_unknown),
    .proto_valid        (proto_valid)
  );

  integer sum;

  initial begin
    $display("=== protocol_classifier UNIT TEST ===");

    // --------------------------------------------------
    // Case 0: vlan_valid = 0
    // --------------------------------------------------
    vlan_valid = 1'b0;
    resolved_ethertype = 16'h0800;
    #1;

    if (proto_valid !== 1'b0)
      $fatal(1, "FAIL: proto_valid should be 0 when vlan_valid=0");

    sum = is_ipv4 + is_ipv6 + is_arp + is_unknown;
    if (sum !== 0)
      $fatal(1, "FAIL: flags should all be 0 when vlan_valid=0");

    // --------------------------------------------------
    // Case 1: IPv4
    // --------------------------------------------------
    vlan_valid = 1'b1;
    resolved_ethertype = 16'h0800;
    #1;

    if (!proto_valid || !is_ipv4)
      $fatal(1, "FAIL: IPv4 not detected");

    sum = is_ipv4 + is_ipv6 + is_arp + is_unknown;
    if (sum !== 1)
      $fatal(1, "FAIL: IPv4 one-hot violation");

    // --------------------------------------------------
    // Case 2: IPv6
    // --------------------------------------------------
    resolved_ethertype = 16'h86DD;
    #1;

    if (!proto_valid || !is_ipv6)
      $fatal(1, "FAIL: IPv6 not detected");

    sum = is_ipv4 + is_ipv6 + is_arp + is_unknown;
    if (sum !== 1)
      $fatal(1, "FAIL: IPv6 one-hot violation");

    // --------------------------------------------------
    // Case 3: ARP
    // --------------------------------------------------
    resolved_ethertype = 16'h0806;
    #1;

    if (!proto_valid || !is_arp)
      $fatal(1, "FAIL: ARP not detected");

    sum = is_ipv4 + is_ipv6 + is_arp + is_unknown;
    if (sum !== 1)
      $fatal(1, "FAIL: ARP one-hot violation");

    // --------------------------------------------------
    // Case 4: UNKNOWN
    // --------------------------------------------------
    resolved_ethertype = 16'h1234;
    #1;

    if (!proto_valid || !is_unknown)
      $fatal(1, "FAIL: UNKNOWN not detected");

    sum = is_ipv4 + is_ipv6 + is_arp + is_unknown;
    if (sum !== 1)
      $fatal(1, "FAIL: UNKNOWN one-hot violation");

    $display("✔ protocol_classifier UNIT TEST PASSED");
    $finish;
  end

endmodule
