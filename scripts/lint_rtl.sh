#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Verilator RTL lint script
# ------------------------------------------------------------

ROOT_DIR=$(git rev-parse --show-toplevel)
BUILD_DIR="${ROOT_DIR}/build"

mkdir -p "${BUILD_DIR}"

# ------------------------------------------------------------
# RTL files to lint (explicit is better than implicit)
# ------------------------------------------------------------
RTL_FILES=(
  rtl/axis/axis_skid_buffer.sv
)

# ------------------------------------------------------------
# Run Verilator
# ------------------------------------------------------------
verilator --lint-only -Wall \
  -Wno-DECLFILENAME \
  "${RTL_FILES[@]}"

echo "[LINT] RTL lint passed"
