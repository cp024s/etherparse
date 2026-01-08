// ============================================================
// Module: vlan_resolver
// Purpose: Resolve optional VLAN tag and final EtherType
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module vlan_resolver (
  input  logic        clk,
  input  logic        rst_n,

  // Trigger from Ethernet header parser
  input  logic        fields_valid,
  input  ethertype_t  ethertype_raw,
  input  logic [18*8-1:0] header_bytes,

  // Outputs
  output logic        vlan_present,
  output logic [11:0] vlan_id,
  output ethertype_t  resolved_ethertype,
  output logic [4:0]  l2_header_len,
  output logic        vlan_valid
);

  // VLAN TPID
  localparam ethertype_t VLAN_TPID = 16'h8100;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      vlan_present      <= 1'b0;
      vlan_id           <= '0;
      resolved_ethertype<= '0;
      l2_header_len     <= '0;
      vlan_valid        <= 1'b0;
    end
    else if (fields_valid && !vlan_valid) begin
      // ------------------------------------------------------
      // VLAN frame
      // ------------------------------------------------------
      if (ethertype_raw == VLAN_TPID) begin
        // VLAN TCI is bytes 14–15
        vlan_present <= 1'b1;
        vlan_id <= {
          header_bytes[14*8 +: 4],   // lower 4 bits of byte 14
          header_bytes[15*8 +: 8]    // byte 15
        };

        // Encapsulated EtherType is bytes 16–17
        resolved_ethertype <= {
          header_bytes[16*8 +: 8],
          header_bytes[17*8 +: 8]
        };

        l2_header_len <= 5'd18;
      end
      // ------------------------------------------------------
      // Non-VLAN frame
      // ------------------------------------------------------
      else begin
        vlan_present       <= 1'b0;
        vlan_id            <= 12'd0;
        resolved_ethertype <= ethertype_raw;
        l2_header_len      <= 5'd14;
      end

      vlan_valid <= 1'b1;
    end
  end

endmodule
