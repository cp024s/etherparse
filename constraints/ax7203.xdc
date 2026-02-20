# ============================================================
# AX7203 Ethernet Bring-up Constraints (PHY1)
# Device: xc7a200tfbg484-1
# ============================================================

# ============================================================
# 200 MHz Differential Clock (BANK34, 1.5V DDR bank)
# ============================================================

set_property PACKAGE_PIN R4 [get_ports sys_clk_p]
set_property PACKAGE_PIN T4 [get_ports sys_clk_n]

# Correct standard for 1.5V bank differential clock
set_property IOSTANDARD DIFF_SSTL15 [get_ports {sys_clk_p sys_clk_n}]

# Enable internal termination (recommended)
set_property DIFF_TERM TRUE [get_ports {sys_clk_p sys_clk_n}]

create_clock -period 5.000 -name sys_clk -waveform {0 2.5} [get_ports sys_clk_p]

# ============================================================
# Reset Button (BANK34 → 1.5V)
# Manual Page 22
# ============================================================

set_property PACKAGE_PIN T6 [get_ports rst_n]
set_property IOSTANDARD LVCMOS15 [get_ports rst_n]
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