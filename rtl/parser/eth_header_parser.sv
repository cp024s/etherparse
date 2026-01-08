// ============================================================
// Module: eth_header_parser
// Purpose: Parse Ethernet L2 header fields
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module eth_header_parser (
  input  logic       clk,
  input  logic       rst_n,

  // Header input
  input  logic [18*8-1:0] header_bytes,
  input  logic            header_valid,

  // Parsed outputs
  output mac_addr_t   dest_mac,
  output mac_addr_t   src_mac,
  output ethertype_t  ethertype_raw,
  output logic        fields_valid
);

  // ----------------------------------------------------------
  // Parse + latch logic
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dest_mac      <= '0;
      src_mac       <= '0;
      ethertype_raw <= '0;
      fields_valid  <= 1'b0;
    end
    else if (header_valid && !fields_valid) begin
      // Ethernet header layout:
      // Bytes  0–5  : Destination MAC
      // Bytes  6–11 : Source MAC
      // Bytes 12–13 : EtherType

      dest_mac <= {
        header_bytes[0*8 +: 8],
        header_bytes[1*8 +: 8],
        header_bytes[2*8 +: 8],
        header_bytes[3*8 +: 8],
        header_bytes[4*8 +: 8],
        header_bytes[5*8 +: 8]
      };

      src_mac <= {
        header_bytes[6*8 +: 8],
        header_bytes[7*8 +: 8],
        header_bytes[8*8 +: 8],
        header_bytes[9*8 +: 8],
        header_bytes[10*8 +: 8],
        header_bytes[11*8 +: 8]
      };

      ethertype_raw <= {
        header_bytes[12*8 +: 8],
        header_bytes[13*8 +: 8]
      };

      fields_valid <= 1'b1;
    end
  end

endmodule
