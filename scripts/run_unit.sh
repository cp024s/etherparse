#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

log "Running UNIT tests"

UNIT_TESTS=(
  "eth_header_parser"
  "header_shift_register"
  "vlan_resolver"
  "protocol_classifier"
  "metadata_packager"
)

for test in "${UNIT_TESTS[@]}"; do
  log "UNIT TEST: $test"

  run_cmd iverilog -g2012 \
    -I "$ROOT_DIR/pkg" \
    -I "$ROOT_DIR/rtl/parser" \
    -I "$ROOT_DIR/rtl/metadata" \
    "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
    "$ROOT_DIR/rtl/parser/${test}.sv" \
    "$ROOT_DIR/tb/unit/${test}_tb.sv" \
    -o "$BUILD_DIR/${test}_tb"

  run_cmd vvp "$BUILD_DIR/${test}_tb"
done

log "ALL UNIT TESTS PASSED"
