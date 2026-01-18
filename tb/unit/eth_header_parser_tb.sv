// ============================================================
// Testbench: eth_header_parser_tb
// Purpose  : Unit test for Ethernet header parsing (BYTE ARRAY)
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module eth_header_parser_tb;

  byte_t header_bytes [0:17];
  logic  header_valid;

  mac_addr_t   dest_mac;
  mac_addr_t   src_mac;
  ethertype_t  ethertype_raw;
  logic        fields_valid;

  eth_header_parser dut (
    .header_bytes (header_bytes),
    .header_valid (header_valid),
    .dest_mac     (dest_mac),
    .src_mac      (src_mac),
    .ethertype_raw(ethertype_raw),
    .fields_valid (fields_valid)
  );

  initial begin
    header_valid = 0;

    // Ethernet II IPv4 header
    header_bytes[0]  = 8'hFF;
    header_bytes[1]  = 8'hFF;
    header_bytes[2]  = 8'hFF;
    header_bytes[3]  = 8'hFF;
    header_bytes[4]  = 8'hFF;
    header_bytes[5]  = 8'hFF;

    header_bytes[6]  = 8'h00;
    header_bytes[7]  = 8'h11;
    header_bytes[8]  = 8'h22;
    header_bytes[9]  = 8'h33;
    header_bytes[10] = 8'h44;
    header_bytes[11] = 8'h55;

    header_bytes[12] = 8'h08;
    header_bytes[13] = 8'h00;

    header_bytes[14] = 0;
    header_bytes[15] = 0;
    header_bytes[16] = 0;
    header_bytes[17] = 0;

    #1;
    header_valid = 1;
    #1;
    header_valid = 0;

    if (!fields_valid)
      $fatal(1, "FAIL: fields_valid not asserted");

    if (dest_mac !== 48'hFFFFFFFFFFFF)
      $fatal(1, "FAIL: dest_mac incorrect: %h", dest_mac);

    if (src_mac !== 48'h001122334455)
      $fatal(1, "FAIL: src_mac incorrect: %h", src_mac);

    if (ethertype_raw !== 16'h0800)
      $fatal(1, "FAIL: ethertype incorrect: %h", ethertype_raw);

    $display("✔ eth_header_parser unit test PASSED");
    $finish;
  end

endmodule
