# ============================================================
# Makefile: Ethernet Parser Test Orchestration
# ============================================================

SCRIPTS_DIR := scripts

.PHONY: help unit integration full all clean

help:
	@echo ""
	@echo "Available targets:"
	@echo "  make unit         Run all unit tests"
	@echo "  make integration  Run integration tests"
	@echo "  make full         Run full system test"
	@echo "  make all          Run unit + integration + full"
	@echo "  make clean        Remove build artifacts"
	@echo ""

unit:
	@./$(SCRIPTS_DIR)/run_unit.sh

integration:
	@./$(SCRIPTS_DIR)/run_integration.sh

full:
	@./$(SCRIPTS_DIR)/run_full.sh

all: unit integration full

clean:
	@rm -rf build
	@echo "Cleaned build directory"
