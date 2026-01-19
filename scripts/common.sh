#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"

mkdir -p "$BUILD_DIR"

# Colors
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

log() {
  echo -e "${BLUE}[INFO]${RESET} $1"
}

pass() {
  echo -e "${GREEN}✔ $1${RESET}"
}

fail() {
  echo -e "${RED}✖ $1${RESET}"
  exit 1
}

# Run a command silently, fail if it fails
run_silent() {
  "$@" > /dev/null 2>&1 || return 1
}
