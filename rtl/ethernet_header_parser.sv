// ============================================================
// Module: ethernet_frame_parser
// Purpose: Top-level Ethernet frame parsing and metadata tagging
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module ethernet_frame_parser #(
  parameter int DATA_WIDTH = 64
)(
  input  logic                  clk,
  input  logic                  rst_n,

  // AXI4-Stream input
  input  logic [DATA_WIDTH-1:0] s_axis_tdata,
  input  logic                  s_axis_tvalid,
  output logic                  s_axis_tready,
  input  logic                  s_axis_tlast,

  // AXI4-Stream output
  output logic [DATA_WIDTH-1:0] m_axis_tdata,
  output logic                  m_axis_tvalid,
  input  logic                  m_axis_tready,
  output logic                  m_axis_tlast,

  // Metadata output
  output eth_metadata_t         m_axis_tuser,
  output logic                  m_axis_tuser_valid
);

  // ==========================================================
  // AXI handshake
  // ==========================================================

  logic beat_accept;

  assign s_axis_tready = m_axis_tready;
  assign m_axis_tvalid = s_axis_tvalid;
  assign m_axis_tdata  = s_axis_tdata;
  assign m_axis_tlast  = s_axis_tlast;

  assign beat_accept = s_axis_tvalid && s_axis_tready;

  // ==========================================================
  // Frame control
  // ==========================================================

  logic frame_start;
  logic frame_end;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_start <= 1'b0;
      frame_end   <= 1'b0;
    end
    else begin
      frame_start <= beat_accept && s_axis_tvalid && !frame_end;
      frame_end   <= beat_accept && s_axis_tlast;
    end
  end

  // ==========================================================
  // Header capture
  // ==========================================================

  eth_header_bytes_t header_bytes;
  logic              header_valid;

  header_shift_register #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_header_capture (
    .clk          (clk),
    .rst_n        (rst_n),
    .beat_accept  (beat_accept),
    .frame_start  (frame_start),
    .axis_tdata   (s_axis_tdata),
    .header_bytes (header_bytes),
    .header_valid (header_valid)
  );

  // ==========================================================
  // Ethernet header parsing
  // ==========================================================

  mac_addr_t   dest_mac;
  mac_addr_t   src_mac;
  ethertype_t  ethertype_raw;
  logic        fields_valid;

  eth_header_parser u_eth_hdr (
    .header_bytes (header_bytes),
    .header_valid (header_valid),
    .dest_mac     (dest_mac),
    .src_mac      (src_mac),
    .ethertype_raw(ethertype_raw),
    .fields_valid (fields_valid)
  );

  // ==========================================================
  // VLAN resolution
  // ==========================================================

  logic        vlan_present;
  logic [11:0] vlan_id;
  ethertype_t  resolved_ethertype;
  logic [4:0]  l2_header_len;
  logic        vlan_valid;

  vlan_resolver u_vlan (
    .header_bytes      (header_bytes),
    .ethertype_raw     (ethertype_raw),
    .fields_valid      (fields_valid),
    .vlan_present      (vlan_present),
    .vlan_id           (vlan_id),
    .resolved_ethertype(resolved_ethertype),
    .l2_header_len     (l2_header_len),
    .vlan_valid        (vlan_valid)
  );

  // ==========================================================
  // Protocol classification
  // ==========================================================

  logic is_ipv4, is_ipv6, is_arp, is_unknown;
  logic proto_valid;

  protocol_classifier u_proto (
    .resolved_ethertype(resolved_ethertype),
    .vlan_valid         (vlan_valid),
    .is_ipv4            (is_ipv4),
    .is_ipv6            (is_ipv6),
    .is_arp             (is_arp),
    .is_unknown         (is_unknown),
    .proto_valid        (proto_valid)
  );

  // ==========================================================
  // Metadata packaging
  // ==========================================================

  metadata_packager u_metadata (
    .clk              (clk),
    .rst_n            (rst_n),
    .frame_start      (frame_start),
    .frame_end        (frame_end),
    .fields_valid     (fields_valid),
    .dest_mac         (dest_mac),
    .src_mac          (src_mac),
    .vlan_valid       (vlan_valid),
    .vlan_present     (vlan_present),
    .vlan_id          (vlan_id),
    .resolved_ethertype(resolved_ethertype),
    .l2_header_len    (l2_header_len),
    .proto_valid      (proto_valid),
    .is_ipv4          (is_ipv4),
    .is_ipv6          (is_ipv6),
    .is_arp           (is_arp),
    .is_unknown       (is_unknown),
    .metadata         (m_axis_tuser),
    .metadata_valid   (m_axis_tuser_valid)
  );

endmodule
