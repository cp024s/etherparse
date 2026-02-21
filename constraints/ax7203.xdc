# ============================================================
# AX7203 Ethernet Bring-up Constraints (PHY1)
# Device: xc7a200tfbg484-1
# ============================================================

# ============================================================
# 200 MHz Differential Clock (Bank34 → 2.5V)
# ============================================================

set_property PACKAGE_PIN R4 [get_ports sys_clk_p]
set_property PACKAGE_PIN T4 [get_ports sys_clk_n]

set_property IOSTANDARD LVDS_25 [get_ports {sys_clk_p sys_clk_n}]
set_property DIFF_TERM TRUE [get_ports {sys_clk_p sys_clk_n}]

create_clock -period 5.000 -name sys_clk -waveform {0 2.5} [get_ports sys_clk_p]

# ============================================================
# Reset Button (BANK34 → 2.5V)
# Manual Page 22
# ============================================================

set_property PACKAGE_PIN T6 [get_ports rst_n]
set_property IOSTANDARD LVCMOS25 [get_ports rst_n]
set_property PULLUP true [get_ports rst_n]

set_false_path -from [get_ports rst_n]

# ============================================================
# User LEDs (BANK13 → 3.3V)
# Manual Page 55
# ============================================================

set_property PACKAGE_PIN B13 [get_ports {led[0]}]
set_property PACKAGE_PIN C13 [get_ports {led[1]}]
set_property PACKAGE_PIN D14 [get_ports {led[2]}]
set_property PACKAGE_PIN D15 [get_ports {led[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
set_property DRIVE 8 [get_ports {led[*]}]
set_property SLEW SLOW [get_ports {led[*]}]

# ============================================================
# ================= RGMII - PHY1 =============================
# BANK16 → 3.3V (Manual Page 33, Page 37)
# ============================================================

# TX Clock (FPGA → PHY)
set_property PACKAGE_PIN E18 [get_ports rgmii_tx_clk]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_tx_clk]

# TX Data
set_property PACKAGE_PIN C20 [get_ports {rgmii_txd[0]}]
set_property PACKAGE_PIN D20 [get_ports {rgmii_txd[1]}]
set_property PACKAGE_PIN A19 [get_ports {rgmii_txd[2]}]
set_property PACKAGE_PIN A18 [get_ports {rgmii_txd[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_txd[*]}]

# TX Control (TXEN)
set_property PACKAGE_PIN F18 [get_ports rgmii_tx_ctl]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_tx_ctl]

# RX Clock (PHY → FPGA)
set_property PACKAGE_PIN B17 [get_ports rgmii_rx_clk]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_rx_clk]

# RX Data
set_property PACKAGE_PIN A16 [get_ports {rgmii_rxd[0]}]
set_property PACKAGE_PIN B18 [get_ports {rgmii_rxd[1]}]
set_property PACKAGE_PIN C18 [get_ports {rgmii_rxd[2]}]
set_property PACKAGE_PIN C19 [get_ports {rgmii_rxd[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_rxd[*]}]

# RX Control (RXDV)
set_property PACKAGE_PIN A15 [get_ports rgmii_rx_ctl]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_rx_ctl]

# PHY Reset (BANK16)
set_property PACKAGE_PIN D16 [get_ports phy_reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports phy_reset_n]

# ============================================================
# ================= RGMII TIMING CONSTRAINTS =================
# Target: PHY1 (RGMII-ID assumed)
# Speed : 1G (125 MHz)
# ============================================================

# ------------------------------------------------------------
# 1) Define RX clock coming from PHY
# ------------------------------------------------------------
create_clock -name rgmii_rx_clk \
             -period 8.000 \
             [get_ports rgmii_rx_clk]

# ------------------------------------------------------------
# 2) RGMII RX input delays (PHY inserts internal delay)
# Conservative safe window for RGMII-ID
# ------------------------------------------------------------
set_input_delay -clock rgmii_rx_clk -max 2.0 \
    [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]

set_input_delay -clock rgmii_rx_clk -min 0.0 \
    [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]

# ------------------------------------------------------------
# 3) Define TX clock (generated from internal GTX clock)
# ------------------------------------------------------------
create_generated_clock -name rgmii_tx_clk \
    -source [get_ports rgmii_tx_clk] \
    [get_ports rgmii_tx_clk]

# ------------------------------------------------------------
# 4) RGMII TX output delays
# ------------------------------------------------------------
set_output_delay -clock rgmii_tx_clk -max 2.0 \
    [get_ports {rgmii_txd[*] rgmii_tx_ctl}]

set_output_delay -clock rgmii_tx_clk -min -0.5 \
    [get_ports {rgmii_txd[*] rgmii_tx_ctl}]