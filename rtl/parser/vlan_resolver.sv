// ============================================================
// Module: vlan_resolver
// Purpose: Detect and resolve single 802.1Q VLAN tag
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module vlan_resolver (
  input  eth_header_bytes_t header_bytes,
  input  ethertype_t        ethertype_raw,
  input  logic              fields_valid,

  output logic              vlan_present,
  output logic [11:0]       vlan_id,
  output ethertype_t        resolved_ethertype,
  output logic [4:0]        l2_header_len,
  output logic              vlan_valid
);

  always_comb begin
    // Defaults
    vlan_present       = 1'b0;
    vlan_id            = 12'h000;
    resolved_ethertype = ethertype_raw;
    l2_header_len      = L2_HEADER_NO_VLAN;
    vlan_valid         = 1'b0;

    if (fields_valid) begin
      // Check for 802.1Q VLAN tag
      if (ethertype_raw == ETHERTYPE_VLAN) begin
        vlan_present = 1'b1;

        // VLAN ID is lower 12 bits of TCI (bytes 14–15)
        vlan_id = {
          header_bytes[14][3:0],
          header_bytes[15]
        };

        // Actual ethertype follows VLAN tag (bytes 16–17)
        resolved_ethertype = {
          header_bytes[16],
          header_bytes[17]
        };

        l2_header_len = L2_HEADER_VLAN;
      end

      vlan_valid = 1'b1;
    end
  end

endmodule
