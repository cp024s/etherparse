// ============================================================
// Module: eth_header_parser
// Purpose: Decode Ethernet L2 header fields from captured bytes
// ============================================================

`timescale 1ns/1ps

module eth_header_parser #(
  parameter int L2_HEADER_MAX_BYTES = 18
)(
  input  logic clk,
  input  logic rst_n,

  // Input from header shift register
  input  logic [L2_HEADER_MAX_BYTES*8-1:0] header_bytes,
  input  logic                             header_valid,

  // Decoded outputs
  output logic [47:0] dest_mac,
  output logic [47:0] src_mac,
  output logic [15:0] ethertype_raw,
  output logic        fields_valid
);

  // ----------------------------------------------------------
  // Header field extraction
  // ----------------------------------------------------------
  //
  // Ethernet fields are big-endian on the wire.
  // header_bytes[7:0]   = byte 0
  // header_bytes[15:8]  = byte 1
  // ...
  //

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dest_mac     <= '0;
      src_mac      <= '0;
      ethertype_raw<= '0;
      fields_valid <= 1'b0;
    end
    else if (header_valid && !fields_valid) begin
      // Destination MAC: bytes 0-5
      dest_mac <= {
        header_bytes[  7:0],
        header_bytes[ 15:8],
        header_bytes[ 23:16],
        header_bytes[ 31:24],
        header_bytes[ 39:32],
        header_bytes[ 47:40]
      };

      // Source MAC: bytes 6-11
      src_mac <= {
        header_bytes[ 55:48],
        header_bytes[ 63:56],
        header_bytes[ 71:64],
        header_bytes[ 79:72],
        header_bytes[ 87:80],
        header_bytes[ 95:88]
      };

      // EtherType / TPID: bytes 12-13
      ethertype_raw <= {
        header_bytes[103:96],
        header_bytes[111:104]
      };

      fields_valid <= 1'b1;
    end
    else if (!header_valid) begin
      // Clear valid when header capture resets
      fields_valid <= 1'b0;
    end
  end

endmodule
