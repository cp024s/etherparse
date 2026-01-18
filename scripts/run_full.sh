#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

log "Running FULL SYSTEM test"

run_cmd iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl" \
  -I "$ROOT_DIR/rtl/axis" \
  -I "$ROOT_DIR/rtl/parser" \
  -I "$ROOT_DIR/rtl/metadata" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/axis/axis_ingress.sv" \
  "$ROOT_DIR/rtl/axis/axis_skid_buffer.sv" \
  "$ROOT_DIR/rtl/parser/frame_control_fsm.sv" \
  "$ROOT_DIR/rtl/parser/byte_counter.sv" \
  "$ROOT_DIR/rtl/parser/header_shift_register.sv" \
  "$ROOT_DIR/rtl/parser/eth_header_parser.sv" \
  "$ROOT_DIR/rtl/parser/vlan_resolver.sv" \
  "$ROOT_DIR/rtl/parser/protocol_classifier.sv" \
  "$ROOT_DIR/rtl/metadata/metadata_packager.sv" \
  "$ROOT_DIR/rtl/axis/axis_egress.sv" \
  "$ROOT_DIR/rtl/ethernet_frame_parser.sv" \
  "$ROOT_DIR/tb/ethernet_frame_parser_tb.sv" \
  -o "$BUILD_DIR/eth_parser_sim"

run_cmd vvp "$BUILD_DIR/eth_parser_sim"

log "FULL SYSTEM TEST PASSED"
