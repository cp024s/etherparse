# 100 MHz system clock
create_clock -name sys_clk -period 10.000 [get_ports clk]

# Reset (async, active-low)
set_false_path -from [get_ports rst_n]

set_property PACKAGE_PIN <PIN> [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]

set_property PACKAGE_PIN <PIN> [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]
