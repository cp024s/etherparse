# ============================================================
# Clock Wizard IP Generation Script
# 200 MHz input → 125 MHz + 125 MHz (90°)
# ============================================================

create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_wiz_0

set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {200.0} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {125.0} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125.0} \
    CONFIG.CLKOUT2_REQUESTED_PHASE {90.0} \
    CONFIG.NUM_OUT_CLKS {2} \
] [get_ips clk_wiz_0]

generate_target all [get_ips clk_wiz_0]
synth_ip [get_ips clk_wiz_0]