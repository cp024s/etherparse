# ============================================================
# AX7203 – Phase-1 Base Constraints
# Board   : ALINX AX7203
# Purpose : Clock + Reset bring-up ONLY
# Status  : Pin values must be filled from AX7203 manual
# ============================================================

# ------------------------------------------------------------
# 1. SYSTEM DIFFERENTIAL CLOCK
# ------------------------------------------------------------
# AX7203 provides an on-board differential oscillator
# Expected frequency: 200 MHz (verify in manual)
# ------------------------------------------------------------

# >>> REPLACE THESE PINS FROM MANUAL <<<
set_property PACKAGE_PIN <SYS_CLK_P_PIN> [get_ports sys_clk_p]
set_property PACKAGE_PIN <SYS_CLK_N_PIN> [get_ports sys_clk_n]

# Differential I/O standard (VERIFY in manual)
set_property IOSTANDARD DIFF_SSTL15 [get_ports {sys_clk_p sys_clk_n}]

# Create system clock
create_clock -name sys_clk_200m -period 5.000 [get_ports sys_clk_p]


# ------------------------------------------------------------
# 2. RESET (ASYNC, ACTIVE-LOW)
# ------------------------------------------------------------
# Typically connected to a push button or supervisor IC
# ------------------------------------------------------------

# >>> REPLACE THIS PIN FROM MANUAL <<<
set_property PACKAGE_PIN <RST_N_PIN> [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# Reset is asynchronous – exclude from timing
set_false_path -from [get_ports rst_n]


# ------------------------------------------------------------
# 3. CLOCK SAFETY (IMPORTANT)
# ------------------------------------------------------------
# Prevent Vivado from inferring unsafe clock relationships
# ------------------------------------------------------------

set_clock_groups -asynchronous \
  -group [get_clocks sys_clk_200m]


# ============================================================
# END OF PHASE-1 CONSTRAINTS
# ============================================================


# ------------------------------------------------------------
# PENDING / NOT YET CONSTRAINED (INTENTIONAL)
# ------------------------------------------------------------
#
# - AXI Stream data ports (s_axis_*, m_axis_*)
# - Ethernet PHY / SGMII pins
# - LEDs / UART / GPIO
# - JTAG (handled externally)
#
# These will be added AFTER:
#   ✔ Clock is verified
#   ✔ FPGA config is proven
#   ✔ Simple runtime demo works
#
# ------------------------------------------------------------
