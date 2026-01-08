// ============================================================
// Module: vlan_resolver
// Purpose: Resolve VLAN presence and true EtherType
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module vlan_resolver #(
  parameter int L2_HEADER_MAX_BYTES = 18
)(
  input  logic clk,
  input  logic rst_n,

  input  logic        fields_valid,
  input  ethertype_t ethertype_raw,
  input  logic [L2_HEADER_MAX_BYTES*8-1:0] header_bytes,

  output logic        vlan_present,
  output logic [11:0] vlan_id,
  output ethertype_t resolved_ethertype,
  output logic [4:0]  l2_header_len,
  output logic        vlan_valid
);

  logic [15:0] vlan_tci;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      vlan_present       <= 1'b0;
      vlan_id            <= 12'd0;
      resolved_ethertype <= 16'd0;
      l2_header_len      <= L2_HEADER_NO_VLAN;
      vlan_valid         <= 1'b0;
    end
    else if (fields_valid && !vlan_valid) begin
      if (ethertype_raw == ETHERTYPE_VLAN) begin
        vlan_present <= 1'b1;

        // TCI is bytes 14–15
        vlan_tci <= {
          header_bytes[119:112], // byte 14
          header_bytes[127:120]  // byte 15
        };

        vlan_id <= vlan_tci[11:0];

        // Real EtherType is bytes 16–17
        resolved_ethertype <= {
          header_bytes[135:128], // byte 16
          header_bytes[143:136]  // byte 17
        };

        l2_header_len <= L2_HEADER_VLAN;
      end
      else begin
        vlan_present       <= 1'b0;
        vlan_id            <= 12'd0;
        resolved_ethertype <= ethertype_raw;
        l2_header_len      <= L2_HEADER_NO_VLAN;
      end

      vlan_valid <= 1'b1;
    end
    else if (!fields_valid) begin
      vlan_valid <= 1'b0;
    end
  end

endmodule
