#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

log "Running UNIT tests"

log "UNIT TEST: eth_header_parser"
run_cmd iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/parser" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/parser/eth_header_parser.sv" \
  "$ROOT_DIR/tb/unit/eth_header_parser_tb.sv" \
  -o "$BUILD_DIR/eth_header_parser_tb"
run_cmd vvp "$BUILD_DIR/eth_header_parser_tb"

log "UNIT TEST: header_shift_register"
run_cmd iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/parser" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/parser/header_shift_register.sv" \
  "$ROOT_DIR/tb/unit/header_shift_register_tb.sv" \
  -o "$BUILD_DIR/header_shift_register_tb"
run_cmd vvp "$BUILD_DIR/header_shift_register_tb"

log "UNIT TEST: vlan_resolver"
run_cmd iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/parser" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/parser/vlan_resolver.sv" \
  "$ROOT_DIR/tb/unit/vlan_resolver_tb.sv" \
  -o "$BUILD_DIR/vlan_resolver_tb"
run_cmd vvp "$BUILD_DIR/vlan_resolver_tb"

log "UNIT TEST: protocol_classifier"
run_cmd iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/parser" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/parser/protocol_classifier.sv" \
  "$ROOT_DIR/tb/unit/protocol_classifier_tb.sv" \
  -o "$BUILD_DIR/protocol_classifier_tb"
run_cmd vvp "$BUILD_DIR/protocol_classifier_tb"

log "UNIT TEST: metadata_packager"
run_cmd iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/metadata" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/metadata/metadata_packager.sv" \
  "$ROOT_DIR/tb/unit/metadata_packager_tb.sv" \
  -o "$BUILD_DIR/metadata_packager_tb"
run_cmd vvp "$BUILD_DIR/metadata_packager_tb"

log "ALL UNIT TESTS PASSED"
