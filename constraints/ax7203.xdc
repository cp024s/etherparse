# ============================================================
# AX7203 - Minimal Safe Bring-up Constraints
# Device: xc7a200tfbg484-1
# ============================================================

# ===============================
# 200 MHz Differential Clock
# ===============================
set_property PACKAGE_PIN R4 [get_ports sys_clk_p]
set_property PACKAGE_PIN T4 [get_ports sys_clk_n]
set_property IOSTANDARD LVDS_25 [get_ports {sys_clk_p sys_clk_n}]

# ------------------------------------------------------------
# Reset button (KEY1)
# ------------------------------------------------------------
set_property PACKAGE_PIN J21 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property PULLUP true [get_ports rst_n]

create_clock -period 5.000 -name sys_clk -waveform {0 2.5} [get_ports sys_clk_p]

# ===============================
# User LEDs (LVCMOS33)
# ===============================
set_property PACKAGE_PIN B13 [get_ports led[0]]
set_property PACKAGE_PIN C13 [get_ports led[1]]
set_property PACKAGE_PIN D14 [get_ports led[2]]
set_property PACKAGE_PIN D15 [get_ports led[3]]

set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
set_property DRIVE 8 [get_ports {led[*]}]
set_property SLEW SLOW [get_ports {led[*]}]

# ===============================
# Reset false path (if async)
# ===============================
set_false_path -from [get_ports rst_n]
