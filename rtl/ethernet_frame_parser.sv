// ============================================================
// Module: ethernet_frame_parser
// Purpose:
//  Top-level Ethernet frame parser with clean AXIS ownership
//  and out-of-band metadata generation.
//
//  Architecture:
//    axis_ingress
//      → axis_skid_buffer        (sole elasticity owner)
//        → frame_control_fsm
//          → byte_counter
//            → header_shift_register
//              → eth_header_parser
//                → vlan_resolver
//                  → protocol_classifier
//                    → metadata_packager
//        → axis_egress
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

  // Metadata output (sideband)
  output eth_metadata_t         m_axis_tuser,
  output logic                  m_axis_tuser_valid
);

  // ==========================================================
  // AXIS ingress (pure pass-through)
  // ==========================================================
  logic [DATA_WIDTH-1:0] ing_tdata;
  logic                  ing_tvalid;
  logic                  ing_tready;
  logic                  ing_tlast;

  axis_ingress #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_ingress (
    .clk      (clk),
    .rst_n    (rst_n),
    .s_tdata  (s_axis_tdata),
    .s_tvalid (s_axis_tvalid),
    .s_tready (s_axis_tready),
    .s_tlast  (s_axis_tlast),
    .m_tdata  (ing_tdata),
    .m_tvalid (ing_tvalid),
    .m_tready (ing_tready),
    .m_tlast  (ing_tlast),
    .m_tuser  ()
  );

  // ==========================================================
  // AXIS skid buffer (sole elasticity owner)
  // ==========================================================
  logic [DATA_WIDTH-1:0] axis_tdata;
  logic                  axis_tvalid;
  logic                  axis_tready;
  logic                  axis_tlast;

  axis_skid_buffer #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_skid (
    .clk      (clk),
    .rst_n    (rst_n),
    .s_tdata  (ing_tdata),
    .s_tvalid (ing_tvalid),
    .s_tready (ing_tready),
    .s_tlast  (ing_tlast),
    .m_tdata  (axis_tdata),
    .m_tvalid (axis_tvalid),
    .m_tready (axis_tready),
    .m_tlast  (axis_tlast)
  );

  // ==========================================================
  // Beat accept (single definition)
  // ==========================================================
  logic beat_accept;
  assign beat_accept = axis_tvalid && axis_tready;

  // ==========================================================
  // Frame control FSM
  // ==========================================================
  logic frame_start;
  logic frame_end;
  logic in_header;
  logic in_payload;
  logic header_done;

  frame_control_fsm u_fsm (
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
  // Byte counter (header_done generation)
  // ==========================================================
  byte_counter #(
    .DATA_WIDTH   (DATA_WIDTH),
    .HEADER_BYTES (18)
  ) u_byte_cnt (
    .clk         (clk),
    .rst_n       (rst_n),
    .beat_accept (beat_accept),
    .frame_start (frame_start),
    .header_done (header_done)
  );

  // ==========================================================
  // Header capture
  // ==========================================================
  logic [17:0][7:0] header_bytes;
  logic             header_valid;

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
  // Ethernet header parsing
  // ==========================================================
  mac_addr_t   dest_mac;
  mac_addr_t   src_mac;
  ethertype_t  ethertype_raw;
  logic        fields_valid;

  eth_header_parser u_eth_hdr (
    .header_bytes  (header_bytes),
    .header_valid  (header_valid),
    .dest_mac      (dest_mac),
    .src_mac       (src_mac),
    .ethertype_raw (ethertype_raw),
    .fields_valid  (fields_valid)
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
    .header_bytes       (header_bytes),
    .ethertype_raw      (ethertype_raw),
    .fields_valid       (fields_valid),
    .vlan_present       (vlan_present),
    .vlan_id            (vlan_id),
    .resolved_ethertype (resolved_ethertype),
    .l2_header_len      (l2_header_len),
    .vlan_valid         (vlan_valid)
  );

  // ==========================================================
  // Protocol classification
  // ==========================================================
  logic is_ipv4, is_ipv6, is_arp, is_unknown;
  logic proto_valid;

  protocol_classifier u_proto (
    .resolved_ethertype (resolved_ethertype),
    .vlan_valid         (vlan_valid),
    .is_ipv4            (is_ipv4),
    .is_ipv6            (is_ipv6),
    .is_arp             (is_arp),
    .is_unknown         (is_unknown),
    .proto_valid        (proto_valid)
  );

  // ==========================================================
  // Metadata packaging (sideband, race-free)
  // ==========================================================
  eth_metadata_t metadata_bus;

  metadata_packager u_meta (
    .clk                (clk),
    .rst_n              (rst_n),
    .frame_start        (frame_start),
    .frame_end          (frame_end),
    .dest_mac           (dest_mac),
    .src_mac            (src_mac),
    .resolved_ethertype (resolved_ethertype),
    .vlan_present       (vlan_present),
    .vlan_id            (vlan_id),
    .l2_header_len      (l2_header_len),
    .proto_valid        (proto_valid),
    .is_ipv4            (is_ipv4),
    .is_ipv6            (is_ipv6),
    .is_arp             (is_arp),
    .is_unknown         (is_unknown),
    .meta_dest_mac      (metadata_bus.dest_mac),
    .metadata_valid     (m_axis_tuser_valid)
  );

  assign metadata_bus.src_mac       = src_mac;
  assign metadata_bus.ethertype     = resolved_ethertype;
  assign metadata_bus.vlan_present  = vlan_present;
  assign metadata_bus.vlan_id       = vlan_id;
  assign metadata_bus.l2_header_len = l2_header_len;
  assign metadata_bus.is_ipv4       = is_ipv4;
  assign metadata_bus.is_ipv6       = is_ipv6;
  assign metadata_bus.is_arp        = is_arp;
  assign metadata_bus.is_unknown    = is_unknown;

  assign m_axis_tuser = metadata_bus;

  // ==========================================================
  // AXIS egress (pure pass-through)
  // ==========================================================
  axis_egress #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_egress (
    .clk      (clk),
    .rst_n    (rst_n),
    .s_tdata  (axis_tdata),
    .s_tvalid (axis_tvalid),
    .s_tready (axis_tready),
    .s_tlast  (axis_tlast),
    .s_tuser  ('0),
    .m_tdata  (m_axis_tdata),
    .m_tvalid (m_axis_tvalid),
    .m_tready (m_axis_tready),
    .m_tlast  (m_axis_tlast),
    .m_tuser  ()
  );

endmodule
