#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

log "Running INTEGRATION tests"

# ============================================================
# Parser pipeline (no AXI)
# ============================================================
log "parser_pipeline INTEGRATION TEST"
if run_silent iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/parser" \
  -I "$ROOT_DIR/rtl/metadata" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/parser/header_shift_register.sv" \
  "$ROOT_DIR/rtl/parser/eth_header_parser.sv" \
  "$ROOT_DIR/rtl/parser/vlan_resolver.sv" \
  "$ROOT_DIR/rtl/parser/protocol_classifier.sv" \
  "$ROOT_DIR/rtl/metadata/metadata_packager.sv" \
  "$ROOT_DIR/tb/integration/parser_pipeline_tb.sv" \
  -o "$BUILD_DIR/parser_pipeline_tb" \
  && run_silent vvp "$BUILD_DIR/parser_pipeline_tb"
then
  pass "parser_pipeline INTEGRATION TEST PASSED"
else
  fail "parser_pipeline INTEGRATION TEST FAILED"
fi

# ============================================================
# AXI ingress -> parser integration
# ============================================================
log "axi_ingress_parser INTEGRATION TEST"
if run_silent iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/axis" \
  -I "$ROOT_DIR/rtl/parser" \
  -I "$ROOT_DIR/rtl/metadata" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/axis/axis_ingress.sv" \
  "$ROOT_DIR/rtl/parser/header_shift_register.sv" \
  "$ROOT_DIR/rtl/parser/eth_header_parser.sv" \
  "$ROOT_DIR/rtl/parser/vlan_resolver.sv" \
  "$ROOT_DIR/rtl/parser/protocol_classifier.sv" \
  "$ROOT_DIR/rtl/metadata/metadata_packager.sv" \
  "$ROOT_DIR/tb/integration/axi_ingress_parser_tb.sv" \
  -o "$BUILD_DIR/axi_ingress_parser_tb" \
  && run_silent vvp "$BUILD_DIR/axi_ingress_parser_tb"
then
  pass "axi_ingress_parser INTEGRATION TEST PASSED"
else
  fail "axi_ingress_parser INTEGRATION TEST FAILED"
fi

log "ALL INTEGRATION TESTS PASSED"
