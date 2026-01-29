// ============================================================
// Testbench: eth_header_parser_tb
// Purpose  : Unit test for Ethernet header field extraction
// ============================================================

`timescale 1ns/1ps

module eth_header_parser_tb;

  // DUT inputs
  logic [17:0][7:0] header_bytes;
  logic             header_valid;

  // DUT outputs
  logic [47:0] dest_mac;
  logic [47:0] src_mac;
  logic [15:0] ethertype_raw;
  logic        fields_valid;

  // DUT
  eth_header_parser dut (
    .header_bytes  (header_bytes),
    .header_valid  (header_valid),
    .dest_mac      (dest_mac),
    .src_mac       (src_mac),
    .ethertype_raw (ethertype_raw),
    .fields_valid  (fields_valid)
  );

  integer i;

  initial begin
    // Manual clear (no aggregate init)
    for (i = 0; i < 18; i = i + 1)
      header_bytes[i] = 8'h00;

    header_valid = 1'b0;

    $display("=== eth_header_parser UNIT TEST ===");

    // --------------------------------------------------
    // Destination MAC: FF:FF:FF:FF:FF:FF
    // --------------------------------------------------
    header_bytes[0] = 8'hFF;
    header_bytes[1] = 8'hFF;
    header_bytes[2] = 8'hFF;
    header_bytes[3] = 8'hFF;
    header_bytes[4] = 8'hFF;
    header_bytes[5] = 8'hFF;

    // Source MAC: 00:11:22:33:44:55
    header_bytes[6]  = 8'h00;
    header_bytes[7]  = 8'h11;
    header_bytes[8]  = 8'h22;
    header_bytes[9]  = 8'h33;
    header_bytes[10] = 8'h44;
    header_bytes[11] = 8'h55;

    // Ethertype: IPv4 (0x0800)
    header_bytes[12] = 8'h08;
    header_bytes[13] = 8'h00;

    #1;
    header_valid = 1'b1;
    #1;

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

    $display("✔ eth_header_parser UNIT TEST PASSED");
    $finish;
  end

endmodule
