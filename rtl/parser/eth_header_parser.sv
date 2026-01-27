// ============================================================
// Module: eth_header_parser
// Purpose: Parse Ethernet II header fields (BYTE-ACCURATE)
// ============================================================

`timescale 1ns/1ps

/* verilator lint_off IMPORTSTAR */
import eth_parser_pkg::*;
/* verilator lint_on IMPORTSTAR */

module eth_header_parser (
  input  logic             clk,
  input  logic             rst_n,

  input  logic [17:0][7:0] header_bytes,
  input  logic             header_valid,

  output mac_addr_t        dest_mac,
  output mac_addr_t        src_mac,
  output ethertype_t       ethertype_raw,
  output logic             fields_valid
);

  // ----------------------------------------------------------
  // Sequential capture (synth-safe)
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dest_mac      <= '0;
      src_mac       <= '0;
      ethertype_raw <= '0;
      fields_valid  <= 1'b0;
    end
    else begin
      fields_valid <= 1'b0;

      if (header_valid) begin
        dest_mac <= {
          header_bytes[0],
          header_bytes[1],
          header_bytes[2],
          header_bytes[3],
          header_bytes[4],
          header_bytes[5]
        };

        src_mac <= {
          header_bytes[6],
          header_bytes[7],
          header_bytes[8],
          header_bytes[9],
          header_bytes[10],
          header_bytes[11]
        };

        ethertype_raw <= {
          header_bytes[12],
          header_bytes[13]
        };

        fields_valid <= 1'b1;
      end
    end
  end

`ifndef SYNTHESIS
  // ----------------------------------------------------------
  // Immediate assertions (Verilator-safe)
  // ----------------------------------------------------------
  always_comb begin
    if (header_valid) begin
      assert (!$isunknown(header_bytes))
        else $fatal("ETH HEADER PARSER: header_bytes contain X");
    end
  end
`endif

endmodule
