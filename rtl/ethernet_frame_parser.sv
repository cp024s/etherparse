// ============================================================
// Module: ethernet_frame_parser
// Purpose: Complete AXI-stream Ethernet frame parser (TOP)
// Board : ALINX AX7203
// ============================================================

`timescale 1ns/1ps
import eth_parser_pkg::*;

module ethernet_frame_parser #(
  parameter int DATA_WIDTH = 64,
  parameter int USER_WIDTH = 1
)(
  // Fabric clock + reset (from top only)
  input  logic clk,
  input  logic rst,

  // AXI Stream input
  input  logic [DATA_WIDTH-1:0] s_axis_tdata,
  input  logic                  s_axis_tvalid,
  output logic                  s_axis_tready,
  input  logic                  s_axis_tlast,

  // AXI Stream output
  output logic [DATA_WIDTH-1:0] m_axis_tdata,
  output logic                  m_axis_tvalid,
  input  logic                  m_axis_tready,
  output logic                  m_axis_tlast,

  // Parsed metadata
  //output eth_metadata_t         m_axis_tuser,
  //output logic                  m_axis_tuser_valid

  // ==========================================================
  // Parsed metadata
  // ==========================================================
  output eth_metadata_t         m_axis_tuser,
  output logic                  m_axis_tuser_valid
);


  // ==========================================================
  // Parameters
  // ==========================================================
  localparam int HEADER_BYTES = 14;

  // ==========================================================
  // Parsed Ethernet fields
  // ==========================================================
  mac_addr_t   dest_mac;
  mac_addr_t   src_mac;
  ethertype_t  ethertype_raw;
  logic        fields_valid;

  // ==========================================================
  // AXI ingress
  // ==========================================================
  logic [DATA_WIDTH-1:0] in_tdata;
  logic                 in_tvalid, in_tready, in_tlast;

  axis_ingress #(
    .DATA_WIDTH(DATA_WIDTH),
    .USER_WIDTH(USER_WIDTH)
  ) u_ingress (
    .clk      (clk),
    .rst_n    (~rst),

    .s_tdata  (s_axis_tdata),
    .s_tvalid (s_axis_tvalid),
    .s_tready (s_axis_tready),
    .s_tlast  (s_axis_tlast),
    .s_tuser  ('0),

    .m_tdata  (in_tdata),
    .m_tvalid (in_tvalid),
    .m_tready (in_tready),
    .m_tlast  (in_tlast),
    .m_tuser  ()
  );

  // ==========================================================
  // Skid buffer
  // ==========================================================
  logic [DATA_WIDTH-1:0] skid_tdata;
  logic                 skid_tvalid, skid_tready, skid_tlast;

axis_skid_buffer #(
  .DATA_WIDTH(DATA_WIDTH)
) u_skid (
  .clk      (clk),
  .rst_n    (~rst),

  .s_tdata  (in_tdata),
  .s_tvalid (in_tvalid),
  .s_tready (in_tready),
  .s_tlast  (in_tlast),
  .s_tuser  ('0),

  .m_tdata  (skid_tdata),
  .m_tvalid (skid_tvalid),
  .m_tready (skid_tready),
  .m_tlast  (skid_tlast),
  .m_tuser  ()
);


  // ==========================================================
  // Beat accept
  // ==========================================================
  logic beat_accept;
  assign beat_accept = skid_tvalid && skid_tready;

  // ==========================================================
  // Frame control FSM
  // ==========================================================
  logic frame_start, frame_end;
  logic in_header, in_payload;
  logic header_done;

  frame_control_fsm u_fsm (
    .clk         (clk),
    .rst_n       (~rst),
    .beat_accept (beat_accept),
    .tlast       (skid_tlast),
    .header_done (header_done),
    .frame_start (frame_start),
    .frame_end   (frame_end),
    .in_header   (in_header),
    .in_payload  (in_payload)
  );

  // ==========================================================
  // Byte counter
  // ==========================================================
  byte_counter #(
    .DATA_WIDTH   (DATA_WIDTH),
    .HEADER_BYTES (HEADER_BYTES)
  ) u_byte_cnt (
    .clk         (clk),
    .rst_n       (~rst),
    .beat_accept (beat_accept),
    .frame_start (frame_start),
    .header_done (header_done)
  );

  // ==========================================================
  // Header shift register (single source of truth)
  // ==========================================================
  logic [HEADER_BYTES*8-1:0] header_bytes;
  logic                      header_valid;

  header_shift_register #(
    .DATA_WIDTH   (DATA_WIDTH),
    .HEADER_BYTES (HEADER_BYTES)
  ) u_hdr_shift (
    .clk          (clk),
    .rst_n        (~rst),
    .beat_accept  (beat_accept),
    .frame_start  (frame_start),
    .axis_tdata   (skid_tdata),
    .header_bytes (header_bytes),
    .header_valid (header_valid)
  );

  // ==========================================================
  // Ethernet header parser
  // ==========================================================
  eth_header_parser u_eth (
    .header_bytes  (header_bytes),
    .header_valid  (header_valid),
    .dest_mac      (dest_mac),
    .src_mac       (src_mac),
    .ethertype_raw (ethertype_raw),
    .fields_valid  (fields_valid)
  );

  // ==========================================================
  // VLAN resolver
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
  // Protocol classifier
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
  // Metadata packager
  // ==========================================================
  eth_metadata_t metadata_bus;

  metadata_packager u_meta (
    .clk            (clk),
    .rst_n          (~rst),
    .frame_start    (frame_start),
    .frame_end      (frame_end),

    .dest_mac       (dest_mac),
    .src_mac        (src_mac),
    .vlan_present   (vlan_present),
    .vlan_id        (vlan_id),

    .proto_valid    (proto_valid),
    .is_ipv4        (is_ipv4),
    .is_ipv6        (is_ipv6),
    .is_arp         (is_arp),
    .is_unknown     (is_unknown),

    .metadata       (metadata_bus),
    .metadata_valid (m_axis_tuser_valid)
  );

  assign m_axis_tuser = metadata_bus;

  // ==========================================================
  // AXI egress
  // ==========================================================
  axis_egress #(
    .DATA_WIDTH(DATA_WIDTH),
    .USER_WIDTH(USER_WIDTH)
  ) u_egress (
    .clk      (clk),
    .rst_n    (~rst),

    .s_tdata  (skid_tdata),
    .s_tvalid (skid_tvalid),
    .s_tready (skid_tready),
    .s_tlast  (skid_tlast),
    .s_tuser  ('0),

    .m_tdata  (m_axis_tdata),
    .m_tvalid (m_axis_tvalid),
    .m_tready (m_axis_tready),
    .m_tlast  (m_axis_tlast),
    .m_tuser  ()
  );

endmodule
