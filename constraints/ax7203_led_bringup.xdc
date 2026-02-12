###############################################################
# 1. Differential System Clock
###############################################################

set_property PACKAGE_PIN R4  [get_ports sys_clk_p]
set_property PACKAGE_PIN T4  [get_ports sys_clk_n]
set_property IOSTANDARD LVDS [get_ports {sys_clk_p sys_clk_n}]

create_clock -name sys_clk -period 10.000 \
    [get_ports sys_clk_p]

###############################################################
# 2. Reset (Active-Low Push Button Example)
###############################################################

set_property PACKAGE_PIN M19 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property PULLUP true [get_ports rst_n]

###############################################################
# 3. User LEDs (Example AX7203 Pins)
###############################################################

set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports led[*]]

###############################################################
# 4. Reset Timing Exclusion (Async Reset)
###############################################################

set_false_path -from [get_ports rst_n]

###############################################################
# 5. Basic DRC Clean Settings
###############################################################

set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
