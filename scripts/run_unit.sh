#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

log "Running UNIT tests"

# -------------------------
# eth_header_parser
# -------------------------
log "eth_header_parser UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/parser" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/parser/eth_header_parser.sv" \
  "$ROOT_DIR/tb/unit/eth_header_parser_tb.sv" \
  -o "$BUILD_DIR/eth_header_parser_tb" \
  && run_silent vvp "$BUILD_DIR/eth_header_parser_tb"
then
  pass "eth_header_parser UNIT TEST PASSED"
else
  fail "eth_header_parser UNIT TEST FAILED"
fi

# -------------------------
# header_shift_register
# -------------------------
log "header_shift_register UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/parser" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/parser/header_shift_register.sv" \
  "$ROOT_DIR/tb/unit/header_shift_register_tb.sv" \
  -o "$BUILD_DIR/header_shift_register_tb" \
  && run_silent vvp "$BUILD_DIR/header_shift_register_tb"
then
  pass "header_shift_register UNIT TEST PASSED"
else
  fail "header_shift_register UNIT TEST FAILED"
fi

# -------------------------
# vlan_resolver
# -------------------------
log "vlan_resolver UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/parser" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/parser/vlan_resolver.sv" \
  "$ROOT_DIR/tb/unit/vlan_resolver_tb.sv" \
  -o "$BUILD_DIR/vlan_resolver_tb" \
  && run_silent vvp "$BUILD_DIR/vlan_resolver_tb"
then
  pass "vlan_resolver UNIT TEST PASSED"
else
  fail "vlan_resolver UNIT TEST FAILED"
fi

# -------------------------
# protocol_classifier
# -------------------------
log "protocol_classifier UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/parser" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/parser/protocol_classifier.sv" \
  "$ROOT_DIR/tb/unit/protocol_classifier_tb.sv" \
  -o "$BUILD_DIR/protocol_classifier_tb" \
  && run_silent vvp "$BUILD_DIR/protocol_classifier_tb"
then
  pass "protocol_classifier UNIT TEST PASSED"
else
  fail "protocol_classifier UNIT TEST FAILED"
fi

# -------------------------
# metadata_packager
# -------------------------
log "metadata_packager UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$ROOT_DIR/pkg" \
  -I "$ROOT_DIR/rtl/metadata" \
  "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
  "$ROOT_DIR/rtl/metadata/metadata_packager.sv" \
  "$ROOT_DIR/tb/unit/metadata_packager_tb.sv" \
  -o "$BUILD_DIR/metadata_packager_tb" \
  && run_silent vvp "$BUILD_DIR/metadata_packager_tb"
then
  pass "metadata_packager UNIT TEST PASSED"
else
  fail "metadata_packager UNIT TEST FAILED"
fi

log "ALL UNIT TESTS PASSED"
