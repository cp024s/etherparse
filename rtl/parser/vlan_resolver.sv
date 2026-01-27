// ============================================================
// Module: vlan_resolver
// Purpose: Detect and resolve single 802.1Q VLAN tag (portable)
// ============================================================

`timescale 1ns/1ps

module vlan_resolver (
  /* verilator lint_off UNUSED */
  input logic [17:0][7:0] header_bytes,
  /* verilator lint_on UNUSED */

  input  logic [15:0]       ethertype_raw,
  input  logic              fields_valid,

  output logic              vlan_present,
  output logic [11:0]       vlan_id,
  output logic [15:0]       resolved_ethertype,
  output logic [4:0]        l2_header_len,
  output logic              vlan_valid
);

  // ----------------------------------------------------------
  // Combinational resolution
  // ----------------------------------------------------------
  always_comb begin
    // Defaults
    vlan_present        = 1'b0;
    vlan_id             = 12'd0;
    resolved_ethertype  = ethertype_raw;
    l2_header_len       = 5'd14;
    vlan_valid          = fields_valid;

    // VLAN detection (single 802.1Q only)
    if (fields_valid && ethertype_raw == 16'h8100) begin
      vlan_present        = 1'b1;
      vlan_id             = { header_bytes[14][3:0], header_bytes[15] };
      resolved_ethertype  = { header_bytes[16], header_bytes[17] };
      l2_header_len       = 5'd18;
    end

`ifndef SYNTHESIS
    // --------------------------------------------------------
    // Immediate assertions (Verilator-safe)
    // --------------------------------------------------------
    if (fields_valid) begin
      assert (vlan_valid == fields_valid)
        else $fatal("VLAN_RESOLVER: vlan_valid mismatch");

      if (vlan_present) begin
        assert (ethertype_raw == 16'h8100)
          else $fatal("VLAN_RESOLVER: unsupported VLAN ethertype");

        assert (l2_header_len == 5'd18)
          else $fatal("VLAN_RESOLVER: wrong L2 header length for VLAN");

        assert (!$isunknown(vlan_id))
          else $fatal("VLAN_RESOLVER: vlan_id is X");

        assert (!$isunknown(resolved_ethertype))
          else $fatal("VLAN_RESOLVER: resolved_ethertype is X");
      end
      else begin
        assert (l2_header_len == 5'd14)
          else $fatal("VLAN_RESOLVER: wrong L2 header length (no VLAN)");

        assert (resolved_ethertype == ethertype_raw)
          else $fatal("VLAN_RESOLVER: ethertype mismatch without VLAN");
      end
    end
`endif
  end

endmodule
