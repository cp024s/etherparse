# 100 MHz system clock
create_clock -name sys_clk -period 10.000 [get_ports clk]

# Reset (async, active-low)
set_false_path -from [get_ports rst_n]
