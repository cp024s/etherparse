# ============================================================
# AX7203 – Base Timing & Reset Constraints
# ============================================================

# ------------------------------------------------------------
# 1. SYSTEM CLOCK
# ------------------------------------------------------------
# NOTE:
# AX7203 provides a DIFFERENTIAL system oscillator.
# You MUST replace <SYS_CLK_P_PIN> / <SYS_CLK_N_PIN>
# with actual package pins from the AX7203 manual.
# ------------------------------------------------------------

set_property PACKAGE_PIN <SYS_CLK_P_PIN> [get_ports sys_clk_p]
set_property PACKAGE_PIN <SYS_CLK_N_PIN> [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {sys_clk_p sys_clk_n}]

# AX7203 system oscillator is typically 200 MHz
create_clock -name sys_clk_200m -period 5.000 [get_ports sys_clk_p]

# ------------------------------------------------------------
# 2. RESET (ASYNC, ACTIVE-LOW)
# ------------------------------------------------------------

set_property PACKAGE_PIN <RST_N_PIN> [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# Reset is async → remove from timing
set_false_path -from [get_ports rst_n]

# ------------------------------------------------------------
# 3. SAFETY DEFAULTS (IMPORTANT)
# ------------------------------------------------------------

# Do NOT allow Vivado to silently infer clock groups
set_clock_groups -asynchronous \
  -group [get_clocks sys_clk_200m]

# End of file
