# ============================================================
# Makefile: Ethernet Parser Test Orchestration
# ============================================================
# Philosophy:
# - Makefile orchestrates
# - scripts/ do the real work
# - build/ holds all artifacts
# ============================================================

SHELL := /usr/bin/env bash
SCRIPTS_DIR := scripts

.PHONY: help lint unit integration stress sim full all clean

# ------------------------------------------------------------
# Help
# ------------------------------------------------------------
help:
	@echo ""
	@echo "Available targets:"
	@echo "  make lint         RTL lint (Verilator)"
	@echo "  make unit         Run all unit tests"
	@echo "  make integration  Run integration tests"
	@echo "  make stress       Run stress tests"
	@echo "  make sim          Run full simulation flow"
	@echo "  make full         Run lint + unit + integration"
	@echo "  make all          Run lint + unit + integration + stress"
	@echo "  make clean        Remove build artifacts"
	@echo ""

# ------------------------------------------------------------
# Quality gates
# ------------------------------------------------------------
lint:
	@$(SCRIPTS_DIR)/lint_rtl.sh

unit:
	@$(SCRIPTS_DIR)/run_unit.sh

integration:
	@$(SCRIPTS_DIR)/run_integration.sh

stress:
	@$(SCRIPTS_DIR)/run_stress.sh

# ------------------------------------------------------------
# Composite flows
# ------------------------------------------------------------
sim: lint unit integration

full: lint unit integration

all: lint unit integration stress

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------
clean:
	@rm -rf build *.jou *.log dfx_runtime.txt .Xil vivado_sim/
	clear
	@echo "Cleaned build directory and tool artifacts"
