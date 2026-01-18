#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

log "Running INTEGRATION tests"

INTEGRATION_TESTS=(
  "parser_pipeline_tb"
  "axi_ingress_parser_tb"
)

for test in "${INTEGRATION_TESTS[@]}"; do
  log "INTEGRATION TEST: $test"

  run_cmd iverilog -g2012 \
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
    "$ROOT_DIR/tb/integration/${test}.sv" \
    -o "$BUILD_DIR/${test}"

  run_cmd vvp "$BUILD_DIR/${test}"
done

log "ALL INTEGRATION TESTS PASSED"
