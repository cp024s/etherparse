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
  // AXI ingress
  // ==========================================================
  logic [DATA_WIDTH-1:0] axis_tdata;
  logic                  axis_tvalid;
  logic                  axis_tready;
  logic                  axis_tlast;
  logic                  beat_accept;

  axis_ingress #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_ingress (
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
  // Byte counter
  // ==========================================================
  byte_counter #(
    .DATA_WIDTH(DATA_WIDTH),
    .L2_HEADER_MAX_BYTES(18)
  ) u_byte_cnt (
    .clk          (clk),
    .rst_n        (rst_n),
    .beat_accept  (beat_accept),
    .frame_start  (frame_start),
    .frame_end    (frame_end),
    .header_done  (header_done)
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
    .clk           (clk),
    .rst_n         (rst_n),
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
  // Metadata packaging (RAW)
  // ==========================================================
  eth_metadata_t metadata_raw;
  logic          metadata_raw_valid;

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
    .metadata           (metadata_raw),
    .metadata_valid     (metadata_raw_valid)
  );

// ==========================================================
// METADATA ALIGNMENT (EGRESS-CORRECT)
// ==========================================================

eth_metadata_t metadata_latched;
logic          metadata_pending;

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    metadata_latched <= '0;
    metadata_pending <= 1'b0;
  end else begin
    // Capture metadata when parsing completes
    if (metadata_raw_valid) begin
      metadata_latched <= metadata_raw;
      metadata_pending <= 1'b1;
    end

    // Clear ONLY after metadata is emitted on AXI egress
    if (metadata_pending &&
        m_axis_tvalid &&
        m_axis_tready &&
        m_axis_tlast) begin
      metadata_pending <= 1'b0;
    end
  end
end

assign m_axis_tuser       = metadata_latched;
assign m_axis_tuser_valid =
  metadata_pending &&
  m_axis_tvalid &&
  m_axis_tready &&
  m_axis_tlast;


  // ==========================================================
  // AXI egress
  // ==========================================================
  axis_egress #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_egress (
    .clk            (clk),
    .rst_n          (rst_n),
    .axis_tdata_in  (axis_tdata),
    .axis_tvalid_in (axis_tvalid),
    .axis_tready_in (axis_tready),
    .axis_tlast_in  (axis_tlast),
    .m_axis_tdata   (m_axis_tdata),
    .m_axis_tvalid  (m_axis_tvalid),
    .m_axis_tready  (m_axis_tready),
    .m_axis_tlast   (m_axis_tlast)
  );

endmodule
