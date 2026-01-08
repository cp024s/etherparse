// ============================================================
// Package: eth_parser_pkg
// Purpose: Global types, constants, and metadata definition
// ============================================================

package eth_parser_pkg;

  // ----------------------------------------------------------
  // Common constants
  // ----------------------------------------------------------

  // EtherType values
  localparam logic [15:0] ETHERTYPE_IPV4 = 16'h0800;
  localparam logic [15:0] ETHERTYPE_ARP  = 16'h0806;
  localparam logic [15:0] ETHERTYPE_IPV6 = 16'h86DD;
  localparam logic [15:0] ETHERTYPE_VLAN = 16'h8100;

  // L2 header lengths (bytes)
  localparam int L2_HEADER_NO_VLAN  = 14;
  localparam int L2_HEADER_VLAN     = 18;

  // Maximum L2 header we support (single VLAN)
  localparam int L2_HEADER_MAX      = 18;

  // ----------------------------------------------------------
  // Useful typedefs
  // ----------------------------------------------------------

  typedef logic [7:0]  byte_t;
  typedef logic [47:0] mac_addr_t;
  typedef logic [15:0] ethertype_t;

  // ----------------------------------------------------------
  // Ethernet metadata passed to downstream stages
  // ----------------------------------------------------------
  typedef struct packed {
    mac_addr_t   dest_mac;        // Destination MAC address
    mac_addr_t   src_mac;         // Source MAC address
    ethertype_t ethertype;        // Resolved EtherType
    logic        vlan_present;    // 1 if 802.1Q tag present
    logic [11:0] vlan_id;         // VLAN Identifier
    logic [4:0]  l2_header_len;   // 14 or 18 bytes

    // Protocol classification
    logic        is_ipv4;
    logic        is_ipv6;
    logic        is_arp;
    logic        is_unknown;
  } eth_metadata_t;

endpackage
