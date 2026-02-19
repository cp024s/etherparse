# ============================================================
# Vivado Unified Flow Script
# Board : ALINX AX7203
# Device: xc7a200tfbg484-1
# ============================================================

# ============================================================
# Args
# ============================================================

set MODE       [lindex $argv 0]
set TOP_MODULE [lindex $argv 1]
set XDC_FILE   [lindex $argv 2]

if {$MODE eq ""} {
  puts "ERROR: No mode specified (sim/synth/impl/bit/all)"
  exit 1
}

if {$TOP_MODULE eq ""} {
  set TOP_MODULE top_ax7203
}

if {$XDC_FILE eq ""} {
  set XDC_FILE ./constraints/ax7203.xdc
}

puts "--------------------------------------------"
puts "Flow Mode     : $MODE"
puts "Top Module    : $TOP_MODULE"
puts "Constraints   : $XDC_FILE"
puts "--------------------------------------------"

# ============================================================
# Project config
# ============================================================

set PROJ_NAME ethernet_parser_ss
set PROJ_DIR  build/vivado
set PART      xc7a200tfbg484-1

file mkdir $PROJ_DIR
create_project $PROJ_NAME $PROJ_DIR -part $PART -force

# ------------------------------------------------------------
# CRITICAL: Force manual compile order (prevents top override)
# ------------------------------------------------------------
set_property source_mgmt_mode None [current_project]



# ------------------------------------------------------------
# RTL sources (STRICT, NO WILDCARDS)
# ------------------------------------------------------------

# Packages
add_files -norecurse ./pkg/eth_parser_pkg.sv

# AXI infrastructure
add_files -norecurse ./rtl/axis/axis_ingress.sv
add_files -norecurse ./rtl/axis/axis_skid_buffer.sv
add_files -norecurse ./rtl/axis/axis_egress.sv

# Parser blocks
add_files -norecurse ./rtl/parser/frame_control_fsm.sv
add_files -norecurse ./rtl/parser/byte_counter.sv
add_files -norecurse ./rtl/parser/header_shift_register.sv
add_files -norecurse ./rtl/parser/eth_header_parser.sv
add_files -norecurse ./rtl/parser/vlan_resolver.sv
add_files -norecurse ./rtl/parser/protocol_classifier.sv

# Metadata
add_files -norecurse ./rtl/metadata/metadata_packager.sv

# Core parser
add_files -norecurse ./rtl/ethernet_frame_parser.sv

# ------------------------------------------------------------
# MAC Vendor Files (1G RGMII)
# ------------------------------------------------------------

add_files -norecurse ./rtl/mac/vendor/eth_mac_1g_rgmii_fifo.v
add_files -norecurse ./rtl/mac/vendor/eth_mac_1g_rgmii.v
add_files -norecurse ./rtl/mac/vendor/eth_mac_1g_fifo.v
add_files -norecurse ./rtl/mac/vendor/eth_mac_1g.v

add_files -norecurse ./rtl/mac/vendor/axis_gmii_rx.v
add_files -norecurse ./rtl/mac/vendor/axis_gmii_tx.v

add_files -norecurse ./rtl/mac/vendor/axis_eth_fcs.v
add_files -norecurse ./rtl/mac/vendor/axis_eth_fcs_insert.v
add_files -norecurse ./rtl/mac/vendor/axis_eth_fcs_check.v

add_files -norecurse ./rtl/mac/vendor/lfsr.v
add_files -norecurse ./rtl/mac/vendor/rgmii_phy_if.v
add_files -norecurse ./rtl/mac/vendor/gmii_phy_if.v
add_files -norecurse ./rtl/mac/vendor/iddr.v
add_files -norecurse ./rtl/mac/vendor/oddr.v

# MAC wrapper
add_files -norecurse ./rtl/mac/mac_1g_rgmii_wrapper.sv

# ------------------------------------------------------------
# ILA IP (CLI-generated)
# ------------------------------------------------------------

puts "=== Creating ILA IP ==="

create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0

set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {5} \
    CONFIG.C_PROBE0_WIDTH {1} \
    CONFIG.C_PROBE1_WIDTH {1} \
    CONFIG.C_PROBE2_WIDTH {1} \
    CONFIG.C_PROBE3_WIDTH {1} \
    CONFIG.C_PROBE4_WIDTH {64} \
] [get_ips ila_0]

generate_target all [get_ips ila_0]

# THIS IS WHAT YOU WERE MISSING
synth_ip [get_ips ila_0]

update_compile_order -fileset sources_1

# BOARD TOP (ONLY PLACE WITH CLOCKING)
add_files -norecurse ./rtl/top_ax7203.sv

# ------------------------------------------------------------
# Constraints
# ------------------------------------------------------------
add_files -fileset constrs_1 $XDC_FILE


# ------------------------------------------------------------
# Simulation-only sources
# ------------------------------------------------------------
add_files -fileset sim_1 -norecurse ./tb/integration/axi_header_done_payload_tb.sv
add_files -fileset sim_1 -norecurse ./tb/assertions/parser_runtime_checks.sv

# Simulation top
set_property top axi_header_done_payload_tb [get_filesets sim_1]

# Synthesis / implementation top
set_property top $TOP_MODULE [current_fileset]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# ============================================================
# FLOW CONTROL
# ============================================================

if {$MODE eq "sim"} {
  puts "=== Running Vivado simulation ==="
  launch_simulation
  run 1000 ns
  close_sim
  exit 0
}

puts "=== Running synthesis ==="
synth_design -top $TOP_MODULE -part $PART
write_checkpoint -force $PROJ_DIR/post_synth.dcp
report_utilization -file $PROJ_DIR/util_synth.rpt
report_timing_summary -file $PROJ_DIR/timing_synth.rpt

if {$MODE eq "synth"} { exit 0 }

puts "=== Running implementation ==="
opt_design
place_design
route_design

# Generate debug probe file for ILA
write_debug_probes -force $PROJ_DIR/debug.ltx

write_checkpoint -force $PROJ_DIR/post_route.dcp
report_utilization -file $PROJ_DIR/util_impl.rpt
report_timing_summary -file $PROJ_DIR/timing_impl.rpt

if {$MODE eq "impl"} { exit 0 }

puts "=== Generating bitstream ==="
write_bitstream -force $PROJ_DIR/ethernet_parser_ss.bit
#this is supposed to be the change

puts "=== FLOW COMPLETE ==="
