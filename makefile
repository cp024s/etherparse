# ============================================================
# Ethernet Parser SS - Unified Makefile
# Supports:
#  - Icarus simulation
#  - Vivado batch / tcl / gui via MODE override
#  - OS auto-detection
# ============================================================

# ----------------------------
# OS Detection
# ----------------------------
OS ?= auto

ifeq ($(OS),auto)
  ifeq ($(OS),Windows_NT)
    DETECTED_OS := windows
  else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
      DETECTED_OS := linux
    else ifeq ($(UNAME_S),Darwin)
      DETECTED_OS := mac
    else
      DETECTED_OS := unknown
    endif
  endif
else
  DETECTED_OS := $(OS)
endif

# ----------------------------
# Tool Mapping
# ----------------------------
ifeq ($(DETECTED_OS),windows)
  VIVADO := vivado.bat
  RM     := del /Q
  MKDIR  := mkdir
else
  VIVADO := vivado
  RM     := rm -rf
  MKDIR  := mkdir -p
endif

# ----------------------------
# Vivado Mode (override from CLI)
# ----------------------------
MODE ?= batch

# ----------------------------
# Paths
# ----------------------------
BUILD_DIR  := build
TCL_SCRIPT := scripts/vivado_flow.tcl

# ----------------------------
# Help
# ----------------------------
.PHONY: help
help:
	@echo ""
	@echo "Detected OS : $(DETECTED_OS)"
	@echo "Vivado MODE : $(MODE)"
	@echo ""
	@echo "Targets:"
	@echo "  sim-iverilog   - Run Icarus simulation"
	@echo "  vivado-gui     - Launch Vivado GUI"
	@echo "  vivado-sim     - Vivado XSim (batch/tcl/gui)"
	@echo "  vivado-synth   - Vivado synthesis"
	@echo "  vivado-impl    - Vivado implementation"
	@echo "  vivado-bit     - Generate bitstream"
	@echo "  vivado-all     - Full Vivado flow"
	@echo ""
	@echo "Examples:"
	@echo "  make vivado-impl"
	@echo "  make vivado-impl MODE=tcl"
	@echo "  make vivado-all  MODE=gui"

# ============================================================
# Icarus Simulation
# ============================================================
.PHONY: sim-iverilog
sim-iverilog:
	$(MKDIR) $(BUILD_DIR)
	iverilog -g2012 \
	  -I pkg -I rtl -I tb \
	  pkg/eth_parser_pkg.sv \
	  rtl/axis/*.sv \
	  rtl/parser/*.sv \
	  rtl/metadata/*.sv \
	  rtl/ethernet_frame_parser.sv \
	  tb/integration/axi_header_done_payload_tb.sv \
	  -o $(BUILD_DIR)/icarus_sim.out
	vvp $(BUILD_DIR)/icarus_sim.out

# ============================================================
# Vivado GUI (interactive only)
# ============================================================
.PHONY: vivado-gui
vivado-gui:
	$(VIVADO)

# ============================================================
# Vivado Batch / TCL / GUI Targets
# ============================================================
.PHONY: vivado-sim
vivado-sim:
	$(VIVADO) -mode $(MODE) -source $(TCL_SCRIPT) -tclargs sim

.PHONY: vivado-synth
vivado-synth:
	$(VIVADO) -mode $(MODE) -source $(TCL_SCRIPT) -tclargs synth

.PHONY: vivado-impl
vivado-impl:
	$(VIVADO) -mode $(MODE) -source $(TCL_SCRIPT) -tclargs impl

.PHONY: vivado-bit
vivado-bit:
	$(VIVADO) -mode $(MODE) -source $(TCL_SCRIPT) -tclargs bit

.PHONY: vivado-all
vivado-all:
	$(VIVADO) -mode $(MODE) -source $(TCL_SCRIPT) -tclargs all

# ============================================================
# Cleanup
# ============================================================
.PHONY: clean
clean:
	$(RM) $(BUILD_DIR)
	rm -rf .Xil *.jou *.log *.str
	rm -rf *.txt
	rm -rf vivado_sim/
	clear