// ============================================================
// Module: ethernet_frame_parser
// Purpose: Top-level Ethernet frame parsing pipeline
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
  logic [DATA_WIDTH-1:0] ing_tdata;
  logic                  ing_tvalid;
  logic                  ing_tready;
  logic                  ing_tlast;
  logic [0:0]            ing_tuser;

  axis_ingress #(
    .DATA_WIDTH (DATA_WIDTH),
    .USER_WIDTH (1)
  ) u_ingress (
    .clk      (clk),
    .rst_n    (rst_n),
    .s_tdata  (s_axis_tdata),
    .s_tvalid (s_axis_tvalid),
    .s_tready (s_axis_tready),
    .s_tlast  (s_axis_tlast),
    .s_tuser  (1'b0),
    .m_tdata  (ing_tdata),
    .m_tvalid (ing_tvalid),
    .m_tready (ing_tready),
    .m_tlast  (ing_tlast),
    .m_tuser  (ing_tuser)
  );

  // ==========================================================
  // AXI skid buffer (elastic boundary)
  // ==========================================================
  logic [DATA_WIDTH-1:0] skid_tdata;
  logic                  skid_tvalid;
  logic                  skid_tready;
  logic                  skid_tlast;
  logic [0:0]            skid_tuser;

axis_skid_buffer #(
  .DATA_W (DATA_WIDTH),
  .USER_W (1)
) u_skid (
  .clk            (clk),
  .rst_n          (rst_n),

  // Slave AXI4-Stream (from ingress)
  .s_axis_tdata   (ing_tdata),
  .s_axis_tuser   (ing_tuser),
  .s_axis_tlast   (ing_tlast),
  .s_axis_tvalid  (ing_tvalid),
  .s_axis_tready  (ing_tready),

  // Master AXI4-Stream (to parser / egress)
  .m_axis_tdata   (skid_tdata),
  .m_axis_tuser   (skid_tuser),
  .m_axis_tlast   (skid_tlast),
  .m_axis_tvalid  (skid_tvalid),
  .m_axis_tready  (skid_tready)
);



  // ==========================================================
  // Beat accept
  // ==========================================================
  logic beat_accept;
  assign beat_accept = skid_tvalid & skid_tready;

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
    .tlast       (skid_tlast),
    .header_done (header_done),
    .frame_start (frame_start),
    .frame_end   (frame_end),
    .in_header   (in_header),
    .in_payload  (in_payload)
  );

  // ==========================================================
  // Byte counter (OBSERVATIONAL, FUTURE USE)
  // ==========================================================
  logic [15:0] byte_count;

  byte_counter u_byte_counter (
    .clk         (clk),
    .rst_n       (rst_n),
    .beat_accept (beat_accept),
    .frame_start (frame_start),
    .frame_end   (frame_end),
    .byte_count  (byte_count)
  );

  // ==========================================================
  // Header capture
  // ==========================================================
  logic [17:0][7:0] header_bytes;
  logic             header_valid;

  header_shift_register #(
    .DATA_WIDTH (DATA_WIDTH)
  ) u_hdr_shift (
    .clk          (clk),
    .rst_n        (rst_n),
    .beat_accept  (beat_accept),
    .frame_start  (frame_start),
    .axis_tdata   (skid_tdata),
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

  protocol_classifier u_proto (
    .resolved_ethertype (resolved_ethertype),
    .vlan_valid         (vlan_valid),
    .is_ipv4            (is_ipv4),
    .is_ipv6            (is_ipv6),
    .is_arp             (is_arp),
    .is_unknown         (is_unknown),
    .proto_valid        ()
  );

  // ==========================================================
  // Latch header_done (cannot be missed)
  // ==========================================================
  logic header_done_latched;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      header_done_latched <= 1'b0;
    else begin
      if (header_done)
        header_done_latched <= 1'b1;
      if (frame_end)
        header_done_latched <= 1'b0;
    end
  end

  // ==========================================================
  // Metadata packaging
  // ==========================================================
  metadata_packager u_meta (
    .clk                (clk),
    .rst_n              (rst_n),
    .frame_end          (frame_end),
    .header_done        (header_done_latched),
    .dest_mac           (dest_mac),
    .src_mac            (src_mac),
    .vlan_present       (vlan_present),
    .vlan_id            (vlan_id),
    .resolved_ethertype (resolved_ethertype),
    .l2_header_len      (l2_header_len),
    .is_ipv4            (is_ipv4),
    .is_ipv6            (is_ipv6),
    .is_arp             (is_arp),
    .is_unknown         (is_unknown),
    .metadata           (m_axis_tuser),
    .metadata_valid     (m_axis_tuser_valid)
  );

  // ==========================================================
  // AXI egress
  // ==========================================================
  axis_egress #(
    .DATA_WIDTH (DATA_WIDTH),
    .USER_WIDTH (1)
  ) u_egress (
    .clk      (clk),
    .rst_n    (rst_n),
    .s_tdata  (skid_tdata),
    .s_tvalid (skid_tvalid),
    .s_tready (skid_tready),
    .s_tlast  (skid_tlast),
    .s_tuser  (skid_tuser),
    .m_tdata  (m_axis_tdata),
    .m_tvalid (m_axis_tvalid),
    .m_tready (m_axis_tready),
    .m_tlast  (m_axis_tlast),
    .m_tuser  ()
  );

endmodule
