# ============================================================
# Vivado Unified Flow Script
# Board: ALINX AX7203
# Device: xc7a200tfbg484-1
# ============================================================

# ----------------------------
# Args
# ----------------------------
set MODE [lindex $argv 0]
if {$MODE eq ""} {
  puts "ERROR: No mode specified (sim/synth/impl/bit/all)"
  exit 1
}

# ----------------------------
# Project config
# ----------------------------
set PROJ_NAME ethernet_parser_ss
set PROJ_DIR  build/vivado
set PART      xc7a200tfbg484-1

file mkdir $PROJ_DIR
create_project $PROJ_NAME $PROJ_DIR -part $PART -force

# ❗ DO NOT set target_language
# Vivado infers SystemVerilog from .sv files

# ----------------------------
# RTL sources (synthesizable)
# ----------------------------
add_files -norecurse [glob ./pkg/*.sv]
add_files -norecurse [glob ./rtl/axis/*.sv]
add_files -norecurse [glob ./rtl/parser/*.sv]
add_files -norecurse [glob ./rtl/metadata/*.sv]
add_files -norecurse ./rtl/ethernet_frame_parser.sv

# ----------------------------
# Constraints
# ----------------------------
add_files -fileset constrs_1 ./constraints/ax7203.xdc

# ----------------------------
# Simulation-only sources
# ----------------------------
add_files -fileset sim_1 -norecurse [glob ./tb/integration/*.sv]
add_files -fileset sim_1 -norecurse [glob ./tb/assertions/*.sv]

set_property top axi_header_done_payload_tb [get_filesets sim_1]
set_property top ethernet_frame_parser [current_fileset]

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
synth_design -top ethernet_frame_parser -part $PART
write_checkpoint -force $PROJ_DIR/post_synth.dcp
report_utilization -file $PROJ_DIR/util_synth.rpt
report_timing_summary -file $PROJ_DIR/timing_synth.rpt

if {$MODE eq "synth"} { exit 0 }

puts "=== Running implementation ==="
opt_design
place_design
route_design
write_checkpoint -force $PROJ_DIR/post_route.dcp
report_utilization -file $PROJ_DIR/util_impl.rpt
report_timing_summary -file $PROJ_DIR/timing_impl.rpt

if {$MODE eq "impl"} { exit 0 }

puts "=== Generating bitstream ==="
write_bitstream -force $PROJ_DIR/ethernet_parser_ss.bit

puts "=== FLOW COMPLETE ==="
