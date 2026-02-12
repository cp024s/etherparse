# ============================================================
# AX7203 – BASE CONSTRAINTS
# Board : ALINX AX7203
# FPGA : XC7A200T-2FBG484
# Source: AX7203 User Manual
# ============================================================

# ------------------------------------------------------------
# 1. SYSTEM CLOCK (200 MHz DIFFERENTIAL)
# ------------------------------------------------------------
# Manual Section: 2.3
# Pins:
#   SYS_CLK_P -> R4
#   SYS_CLK_N -> T4
# ------------------------------------------------------------

set_property PACKAGE_PIN R4 [get_ports sys_clk_p]
set_property PACKAGE_PIN T4 [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {sys_clk_p sys_clk_n}]

create_clock -name sys_clk_200m -period 5.000 [get_ports sys_clk_p]


# ------------------------------------------------------------
# 2. RESET BUTTON (ACTIVE LOW)
# ------------------------------------------------------------
# Manual Section: 2.8
# RESET_N -> T6
# ------------------------------------------------------------

set_property PACKAGE_PIN T6 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# Async reset – exclude from timing
set_false_path -from [get_ports rst_n]


# ------------------------------------------------------------
# 3. USER LEDs (CARRIER BOARD)
# ------------------------------------------------------------
# Manual Section: 3.13
# Active LOW LEDs
# ------------------------------------------------------------

set_property PACKAGE_PIN B13 [get_ports led1]
set_property PACKAGE_PIN C13 [get_ports led2]
set_property PACKAGE_PIN D14 [get_ports led3]
set_property PACKAGE_PIN D15 [get_ports led4]

set_property IOSTANDARD LVCMOS33 [get_ports {led1 led2 led3 led4}]


# ------------------------------------------------------------
# 4. SAFETY DEFAULTS
# ------------------------------------------------------------

# Prevent Vivado from inventing clock relationships
set_clock_groups -asynchronous \
  -group [get_clocks sys_clk_200m]
