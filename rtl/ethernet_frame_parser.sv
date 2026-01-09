// ============================================================
// Module: ethernet_frame_parser
// Purpose: Top-level integration of Ethernet frame parser
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module ethernet_frame_parser #(
  parameter int DATA_WIDTH = 64
)(
  input  logic                   clk,
  input  logic                   rst_n,

  // AXI4-Stream input
  input  logic [DATA_WIDTH-1:0]  s_axis_tdata,  
  input  logic                   s_axis_tvalid,
  output logic                   s_axis_tready,
  input  logic                   s_axis_tlast,

  // AXI4-Stream output
  output logic [DATA_WIDTH-1:0]  m_axis_tdata,
  output logic                   m_axis_tvalid,
  input  logic                   m_axis_tready,
  output logic                   m_axis_tlast,

  // Ethernet metadata output
  output eth_metadata_t          m_axis_tuser,
  output logic                   m_axis_tuser_valid
);

  // ----------------------------------------------------------
  // Internal AXI signals
  // ----------------------------------------------------------
  logic [DATA_WIDTH-1:0] axis_tdata;
  logic                  axis_tvalid;
  logic                  axis_tready;
  logic                  axis_tlast;
  logic                  beat_accept;

  // ----------------------------------------------------------
  // Frame control signals
  // ----------------------------------------------------------
  logic frame_start;
  logic frame_end;
  logic in_header;
  logic in_payload;

  // ----------------------------------------------------------
  // Byte counter signals
  // ----------------------------------------------------------
  logic [$clog2(18+DATA_WIDTH/8+1)-1:0] byte_count;
  logic header_done;

  // ----------------------------------------------------------
  // Header capture
  // ----------------------------------------------------------
  logic [18*8-1:0] header_bytes;
  logic            header_valid;

  // ----------------------------------------------------------
  // Ethernet header parsing
  // ----------------------------------------------------------
  mac_addr_t   dest_mac;
  mac_addr_t   src_mac;
  ethertype_t ethertype_raw;
  logic        fields_valid;

  // ----------------------------------------------------------
  // VLAN resolution
  // ----------------------------------------------------------
  logic        vlan_present;
  logic [11:0] vlan_id;
  ethertype_t resolved_ethertype;
  logic [4:0]  l2_header_len;
  logic        vlan_valid;

  // ----------------------------------------------------------
  // Protocol classification
  // ----------------------------------------------------------
  logic is_ipv4, is_ipv6, is_arp, is_unknown;
  logic proto_valid;

  // ----------------------------------------------------------
  // Metadata
  // ----------------------------------------------------------
  eth_metadata_t metadata;
  logic          metadata_valid;

  // ==========================================================
  // AXI ingress
  // ==========================================================
  axis_ingress #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_axis_ingress (
    .clk           (clk),
    .rst_n         (rst_n),
    .s_axis_tdata  (s_axis_tdata),
    .s_axis_tvalid (s_axis_tvalid),
    .s_axis_tready (s_axis_tready),
    .s_axis_tlast  (s_axis_tlast),
    .axis_tdata    (axis_tdata),
    .axis_tvalid   (axis_tvalid),
    .axis_tready   (axis_tready),
    .axis_tlast    (axis_tlast),
    .beat_accept   (beat_accept)
  );

  // ==========================================================
  // Byte counter (authoritative header_done source)
  // ==========================================================
  byte_counter #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_byte_counter (
    .clk         (clk),
    .rst_n       (rst_n),
    .beat_accept (beat_accept),
    .frame_start (frame_start),
    .frame_end   (frame_end),
    .byte_count  (byte_count),
    .header_done (header_done)
  );

  // ==========================================================
  // Frame control FSM
  // ==========================================================
  frame_control_fsm u_frame_ctrl (
    .clk         (clk),
    .rst_n       (rst_n),
    .beat_accept (beat_accept),
    .tlast       (axis_tlast),
    .header_done (header_done),
    .frame_start (frame_start),
    .frame_end   (frame_end),
    .in_header   (in_header),
    .in_payload  (in_payload)
  );

  // ==========================================================
  // Header shift register (BYTE-ACCURATE, NO in_l2_header)
  // ==========================================================
  header_shift_register #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_hdr_shift (
    .clk          (clk),
    .rst_n        (rst_n),
    .beat_accept  (beat_accept),
    .frame_start  (frame_start),
    .axis_tdata   (axis_tdata),
    .header_bytes (header_bytes),
    .header_valid (header_valid)
  );

  // ==========================================================
  // Ethernet header parser
  // ==========================================================
  eth_header_parser u_eth_hdr (
    .clk           (clk),
    .rst_n         (rst_n),
    .header_bytes  (header_bytes),
    .header_valid  (header_valid),
    .dest_mac      (dest_mac),
    .src_mac       (src_mac),
    .ethertype_raw(ethertype_raw),
    .fields_valid  (fields_valid)
  );

  // ==========================================================
  // VLAN resolver
  // ==========================================================
  vlan_resolver u_vlan (
    .clk               (clk),
    .rst_n             (rst_n),
    .fields_valid      (fields_valid),
    .ethertype_raw     (ethertype_raw),
    .header_bytes      (header_bytes),
    .vlan_present      (vlan_present),
    .vlan_id           (vlan_id),
    .resolved_ethertype(resolved_ethertype),
    .l2_header_len     (l2_header_len),
    .vlan_valid        (vlan_valid)
  );

  // ==========================================================
  // Protocol classifier
  // ==========================================================
  protocol_classifier u_proto (
    .clk                (clk),
    .rst_n              (rst_n),
    .vlan_valid         (vlan_valid),
    .resolved_ethertype (resolved_ethertype),
    .is_ipv4            (is_ipv4),
    .is_ipv6            (is_ipv6),
    .is_arp             (is_arp),
    .is_unknown         (is_unknown),
    .proto_valid        (proto_valid)
  );

  // ==========================================================
  // Metadata packager
  // ==========================================================
  metadata_packager u_metadata (
    .clk               (clk),
    .rst_n             (rst_n),
    .frame_start       (frame_start),
    .frame_end         (frame_end),
    .fields_valid      (fields_valid),
    .dest_mac          (dest_mac),
    .src_mac           (src_mac),
    .vlan_valid        (vlan_valid),
    .vlan_present      (vlan_present),
    .vlan_id           (vlan_id),
    .resolved_ethertype(resolved_ethertype),
    .l2_header_len     (l2_header_len),
    .proto_valid       (proto_valid),
    .is_ipv4           (is_ipv4),
    .is_ipv6           (is_ipv6),
    .is_arp            (is_arp),
    .is_unknown        (is_unknown),
    .metadata          (metadata),
    .metadata_valid    (metadata_valid)
  );

  // ==========================================================
  // AXI egress
  // ==========================================================
  axis_egress #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_axis_egress (
    .clk               (clk),
    .rst_n             (rst_n),
    .axis_tdata_in     (axis_tdata),
    .axis_tvalid_in    (axis_tvalid),
    .axis_tready_in    (axis_tready),
    .axis_tlast_in     (axis_tlast),
    .m_axis_tdata      (m_axis_tdata),
    .m_axis_tvalid     (m_axis_tvalid),
    .m_axis_tready     (m_axis_tready),
    .m_axis_tlast      (m_axis_tlast),
    .metadata_in       (metadata),
    .metadata_valid_in (metadata_valid),
    .metadata_out      (m_axis_tuser),
    .metadata_valid_out(m_axis_tuser_valid),

  );

endmodule
