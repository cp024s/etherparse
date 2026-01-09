// ============================================================
// Testbench: eth_header_parser_tb
// Purpose  : Unit test for Ethernet header parsing
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module eth_header_parser_tb;

  // ----------------------------------------------------------
  // Clock / Reset
  // ----------------------------------------------------------
  logic clk;
  logic rst_n;

  always #5 clk = ~clk;

  // ----------------------------------------------------------
  // DUT inputs
  // ----------------------------------------------------------
  logic [18*8-1:0] header_bytes;
  logic            header_valid;

  // ----------------------------------------------------------
  // DUT outputs
  // ----------------------------------------------------------
  mac_addr_t   dest_mac;
  mac_addr_t   src_mac;
  ethertype_t  ethertype_raw;
  logic        fields_valid;

  // ----------------------------------------------------------
  // DUT
  // ----------------------------------------------------------
  eth_header_parser dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .header_bytes  (header_bytes),
    .header_valid  (header_valid),
    .dest_mac      (dest_mac),
    .src_mac       (src_mac),
    .ethertype_raw(ethertype_raw),
    .fields_valid  (fields_valid)
  );

  // ----------------------------------------------------------
  // Test sequence
  // ----------------------------------------------------------
  initial begin
    clk = 0;
    rst_n = 0;
    header_valid = 0;
    header_bytes = '0;

    repeat (3) @(posedge clk);
    rst_n = 1;

    // ======================================================
    // TEST 1: Basic Ethernet II header (IPv4)
    // ======================================================
    $display("=== eth_header_parser TEST 1: IPv4 ===");

    /*
      Ethernet header layout:
      [0:5]   Destination MAC
      [6:11]  Source MAC
      [12:13] Ethertype
    */

// Clear first
header_bytes = '0;

// Byte 0 = MSB = bit [143:136]
header_bytes[143 -: 8] = 8'hFF;
header_bytes[135 -: 8] = 8'hFF;
header_bytes[127 -: 8] = 8'hFF;
header_bytes[119 -: 8] = 8'hFF;
header_bytes[111 -: 8] = 8'hFF;
header_bytes[103 -: 8] = 8'hFF;

// Src MAC
header_bytes[95  -: 8] = 8'h00;
header_bytes[87  -: 8] = 8'h11;
header_bytes[79  -: 8] = 8'h22;
header_bytes[71  -: 8] = 8'h33;
header_bytes[63  -: 8] = 8'h44;
header_bytes[55  -: 8] = 8'h55;

// Ethertype = IPv4
header_bytes[47  -: 8] = 8'h08;
header_bytes[39  -: 8] = 8'h00;


    header_valid = 1'b1;
    @(posedge clk);
    header_valid = 1'b0;

    @(posedge clk);

    // --------------------------------------------------
    // Checks
    // --------------------------------------------------
    if (!fields_valid)
      $fatal(1, "FAIL: fields_valid not asserted");

    if (dest_mac !== 48'hFFFFFFFFFFFF)
      $fatal(1, "FAIL: dest_mac incorrect: %h", dest_mac);

    if (src_mac !== 48'h001122334455)
      $fatal(1, "FAIL: src_mac incorrect: %h", src_mac);

    if (ethertype_raw !== 16'h0800)
      $fatal(1, "FAIL: ethertype incorrect: %h", ethertype_raw);

    $display("✔ TEST 1 PASSED");

    // ======================================================
    // DONE
    // ======================================================
    $display("=== eth_header_parser ALL TESTS PASSED ===");
    #20;
    $finish;
  end

endmodule
