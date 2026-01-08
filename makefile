# ============================================================
# Makefile for Ethernet Frame Parser Subsystem
# ============================================================

# ------------------------------------------------------------
# Tools
# ------------------------------------------------------------
IVERILOG := iverilog
VVP      := vvp
GTKWAVE  := gtkwave

# ------------------------------------------------------------
# Project settings
# ------------------------------------------------------------
TOP_TB   := tb/ethernet_frame_parser_tb.sv
OUT      := eth_parser_sim

# Include directories
INCDIRS  := \
	-I pkg \
	-I rtl \
	-I rtl/axis \
	-I rtl/parser \
	-I rtl/metadata

# Source files (order matters: package first)
SRCS := \
	pkg/eth_parser_pkg.sv \
	rtl/axis/axis_ingress.sv \
	rtl/parser/frame_control_fsm.sv \
	rtl/parser/byte_counter.sv \
	rtl/parser/header_shift_register.sv \
	rtl/parser/eth_header_parser.sv \
	rtl/parser/vlan_resolver.sv \
	rtl/parser/protocol_classifier.sv \
	rtl/metadata/metadata_packager.sv \
	rtl/axis/axis_egress.sv \
	rtl/ethernet_frame_parser.sv \
	$(TOP_TB)

# ------------------------------------------------------------
# Default target
# ------------------------------------------------------------
.PHONY: all
all: build run

# ------------------------------------------------------------
# Build
# ------------------------------------------------------------
.PHONY: build
build:
	$(IVERILOG) -g2012 $(INCDIRS) -o $(OUT) $(SRCS)

# ------------------------------------------------------------
# Run simulation
# ------------------------------------------------------------
.PHONY: run
run:
	$(VVP) $(OUT)

# ------------------------------------------------------------
# Run with waveform dump
# ------------------------------------------------------------
.PHONY: wave
wave: build
	$(VVP) $(OUT)
	@echo "Opening waveform..."
	$(GTKWAVE) eth_parser.vcd &

# ------------------------------------------------------------
# Clean generated files
# ------------------------------------------------------------
.PHONY: clean
clean:
	rm -f $(OUT) *.vcd *.vvp *.log

# ------------------------------------------------------------
# Help
# ------------------------------------------------------------
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make build  - Compile the Ethernet parser testbench"
	@echo "  make run    - Run the simulation"
	@echo "  make wave   - Run simulation and open GTKWave"
	@echo "  make clean  - Remove generated files"
