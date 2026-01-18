#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"

mkdir -p "$BUILD_DIR"

log() {
  echo -e "\n\033[1;34m[INFO]\033[0m $1"
}

fail() {
  echo -e "\n\033[1;31m[FAIL]\033[0m $1"
  exit 1
}

run_cmd() {
  log "Running: $*"
  "$@" || fail "Command failed: $*"
}
