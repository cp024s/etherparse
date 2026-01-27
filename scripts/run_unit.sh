#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

echo "-------------------------"
echo "    Running UNIT tests"
echo "-------------------------"

AXIS_RTL="$ROOT_DIR/rtl/axis"
PARSER_RTL="$ROOT_DIR/rtl/parser"
META_RTL="$ROOT_DIR/rtl/metadata"
PKG_RTL="$ROOT_DIR/pkg"

# =========================================================
# AXIS: axis_skid_buffer
# =========================================================
log "axis_skid_buffer UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$AXIS_RTL" \
  "$AXIS_RTL/axis_skid_buffer.sv" \
  "$ROOT_DIR/tb/unit/axis_skid_buffer_tb.sv" \
  -o "$BUILD_DIR/axis_skid_buffer_tb" \
  && run_silent vvp "$BUILD_DIR/axis_skid_buffer_tb"
then
  pass "axis_skid_buffer UNIT TEST PASSED"
else
  fail "axis_skid_buffer UNIT TEST FAILED"
fi

# =========================================================
# AXIS: axis_ingress
# =========================================================
log "axis_ingress UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$AXIS_RTL" \
  "$AXIS_RTL/axis_ingress.sv" \
  "$ROOT_DIR/tb/unit/axis_ingress_tb.sv" \
  -o "$BUILD_DIR/axis_ingress_tb" \
  && run_silent vvp "$BUILD_DIR/axis_ingress_tb"
then
  pass "axis_ingress UNIT TEST PASSED"
else
  fail "axis_ingress UNIT TEST FAILED"
fi

# =========================================================
# AXIS: axis_egress
# =========================================================
log "axis_egress UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$AXIS_RTL" \
  "$AXIS_RTL/axis_egress.sv" \
  "$ROOT_DIR/tb/unit/axis_egress_tb.sv" \
  -o "$BUILD_DIR/axis_egress_tb" \
  && run_silent vvp "$BUILD_DIR/axis_egress_tb"
then
  pass "axis_egress UNIT TEST PASSED"
else
  fail "axis_egress UNIT TEST FAILED"
fi

# =========================================================
# PARSER: byte_counter
# =========================================================
log "byte_counter UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$PARSER_RTL" \
  "$PARSER_RTL/byte_counter.sv" \
  "$ROOT_DIR/tb/unit/byte_counter_tb.sv" \
  -o "$BUILD_DIR/byte_counter_tb" \
  && run_silent vvp "$BUILD_DIR/byte_counter_tb"
then
  pass "byte_counter UNIT TEST PASSED"
else
  fail "byte_counter UNIT TEST FAILED"
fi

# =========================================================
# PARSER: frame_control_fsm
# =========================================================
log "frame_control_fsm UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$PARSER_RTL" \
  "$PARSER_RTL/frame_control_fsm.sv" \
  "$ROOT_DIR/tb/unit/frame_control_fsm_tb.sv" \
  -o "$BUILD_DIR/frame_control_fsm_tb" \
  && run_silent vvp "$BUILD_DIR/frame_control_fsm_tb"
then
  pass "frame_control_fsm UNIT TEST PASSED"
else
  fail "frame_control_fsm UNIT TEST FAILED"
fi

# =========================================================
# PARSER: eth_header_parser
# =========================================================
log "eth_header_parser UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$PKG_RTL" \
  -I "$PARSER_RTL" \
  -I "$AXIS_RTL" \
  "$PKG_RTL/eth_parser_pkg.sv" \
  "$AXIS_RTL/axis_ingress.sv" \
  "$AXIS_RTL/axis_skid_buffer.sv" \
  "$AXIS_RTL/axis_egress.sv" \
  "$PARSER_RTL/eth_header_parser.sv" \
  "$ROOT_DIR/tb/unit/eth_header_parser_tb.sv" \
  -o "$BUILD_DIR/eth_header_parser_tb" \
  && run_silent vvp "$BUILD_DIR/eth_header_parser_tb"
then
  pass "eth_header_parser UNIT TEST PASSED"
else
  fail "eth_header_parser UNIT TEST FAILED"
fi

# =========================================================
# PARSER: header_shift_register
# =========================================================
log "header_shift_register UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$PKG_RTL" \
  -I "$PARSER_RTL" \
  -I "$AXIS_RTL" \
  "$PKG_RTL/eth_parser_pkg.sv" \
  "$AXIS_RTL/axis_ingress.sv" \
  "$AXIS_RTL/axis_skid_buffer.sv" \
  "$AXIS_RTL/axis_egress.sv" \
  "$PARSER_RTL/header_shift_register.sv" \
  "$ROOT_DIR/tb/unit/header_shift_register_tb.sv" \
  -o "$BUILD_DIR/header_shift_register_tb" \
  && run_silent vvp "$BUILD_DIR/header_shift_register_tb"
then
  pass "header_shift_register UNIT TEST PASSED"
else
  fail "header_shift_register UNIT TEST FAILED"
fi

# =========================================================
# PARSER: vlan_resolver
# =========================================================
log "vlan_resolver UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$PKG_RTL" \
  -I "$PARSER_RTL" \
  -I "$AXIS_RTL" \
  "$PKG_RTL/eth_parser_pkg.sv" \
  "$AXIS_RTL/axis_ingress.sv" \
  "$AXIS_RTL/axis_skid_buffer.sv" \
  "$AXIS_RTL/axis_egress.sv" \
  "$PARSER_RTL/vlan_resolver.sv" \
  "$ROOT_DIR/tb/unit/vlan_resolver_tb.sv" \
  -o "$BUILD_DIR/vlan_resolver_tb" \
  && run_silent vvp "$BUILD_DIR/vlan_resolver_tb"
then
  pass "vlan_resolver UNIT TEST PASSED"
else
  fail "vlan_resolver UNIT TEST FAILED"
fi

# =========================================================
# PARSER: protocol_classifier
# =========================================================
log "protocol_classifier UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$PKG_RTL" \
  -I "$PARSER_RTL" \
  -I "$AXIS_RTL" \
  "$PKG_RTL/eth_parser_pkg.sv" \
  "$AXIS_RTL/axis_ingress.sv" \
  "$AXIS_RTL/axis_skid_buffer.sv" \
  "$AXIS_RTL/axis_egress.sv" \
  "$PARSER_RTL/protocol_classifier.sv" \
  "$ROOT_DIR/tb/unit/protocol_classifier_tb.sv" \
  -o "$BUILD_DIR/protocol_classifier_tb" \
  && run_silent vvp "$BUILD_DIR/protocol_classifier_tb"
then
  pass "protocol_classifier UNIT TEST PASSED"
else
  fail "protocol_classifier UNIT TEST FAILED"
fi

# =========================================================
# METADATA: metadata_packager
# =========================================================
log "metadata_packager UNIT TEST"
if run_silent iverilog -g2012 \
  -I "$PKG_RTL" \
  -I "$META_RTL" \
  -I "$AXIS_RTL" \
  "$PKG_RTL/eth_parser_pkg.sv" \
  "$AXIS_RTL/axis_ingress.sv" \
  "$AXIS_RTL/axis_skid_buffer.sv" \
  "$AXIS_RTL/axis_egress.sv" \
  "$META_RTL/metadata_packager.sv" \
  "$ROOT_DIR/tb/unit/metadata_packager_tb.sv" \
  -o "$BUILD_DIR/metadata_packager_tb" \
  && run_silent vvp "$BUILD_DIR/metadata_packager_tb"
then
  pass "metadata_packager UNIT TEST PASSED"
else
  fail "metadata_packager UNIT TEST FAILED"
fi

echo "-------------------------"
echo "    ALL UNIT TESTS PASSED"
echo "-------------------------"
