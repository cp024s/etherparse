# ============================================================
# Vivado Full Flow Script – ALINX AX7203
# Device: xc7vx690tffg1761-2
# ============================================================

# ----------------------------
# Project setup
# ----------------------------
set PROJ_NAME ethernet_parser_ss
set PROJ_DIR  ./build/vivado
set PART      xc7vx690tffg1761-2

file mkdir $PROJ_DIR
create_project $PROJ_NAME $PROJ_DIR -part $PART -force
set_property target_language SystemVerilog [current_project]

# ----------------------------
# Add RTL sources (SYNTHESIZED)
# ----------------------------
add_files -norecurse [glob ./pkg/*.sv]
add_files -norecurse [glob ./rtl/axis/*.sv]
add_files -norecurse [glob ./rtl/parser/*.sv]
add_files -norecurse [glob ./rtl/metadata/*.sv]
add_files -norecurse ./rtl/ethernet_frame_parser.sv

# ----------------------------
# Add constraints
# ----------------------------
add_files -fileset constrs_1 ./constraints/ax7203.xdc

# ----------------------------
# Add simulation-only sources
# ----------------------------
add_files -fileset sim_1 -norecurse [glob ./tb/integration/*.sv]
add_files -fileset sim_1 -norecurse [glob ./tb/assertions/*.sv]

set_property top axi_header_done_payload_tb [get_filesets sim_1]
set_property top ethernet_frame_parser [current_fileset]

# ----------------------------
# Update compile order
# ----------------------------
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# ============================================================
# 2️⃣ RTL LINT / ELAB CHECK
# ============================================================
puts "=== Running RTL elaboration (lint-style check) ==="
synth_design -top ethernet_frame_parser -rtl -flatten_hierarchy none

# ============================================================
# 3️⃣ SIMULATION
# ============================================================
puts "=== Running simulation ==="
launch_simulation
run 1000 ns
close_sim

# ============================================================
# 4️⃣ SYNTHESIS
# ============================================================
puts "=== Running synthesis ==="
synth_design \
  -top ethernet_frame_parser \
  -part $PART \
  -directive default

write_checkpoint -force $PROJ_DIR/post_synth.dcp
report_utilization -file $PROJ_DIR/util_synth.rpt
report_timing_summary -file $PROJ_DIR/timing_synth.rpt

# ============================================================
# 5️⃣ IMPLEMENTATION
# ============================================================
puts "=== Running implementation ==="
opt_design
place_design
route_design

write_checkpoint -force $PROJ_DIR/post_route.dcp
report_utilization -file $PROJ_DIR/util_impl.rpt
report_timing_summary -file $PROJ_DIR/timing_impl.rpt

# ============================================================
# 6️⃣ BITSTREAM
# ============================================================
puts "=== Generating bitstream ==="
write_bitstream -force $PROJ_DIR/ethernet_parser_ss.bit

puts "=== FLOW COMPLETE ==="
