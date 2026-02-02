# ============================================================
# Vivado RTL Simulation Script
# ============================================================

set proj_name ethernet_parser_sim
set build_dir build/vivado/sim

file mkdir $build_dir
create_project $proj_name $build_dir -part xc7a35tcsg324-1 -force

# Add RTL
add_files [glob -nocomplain pkg/*.sv]
add_files [glob -nocomplain rtl/**/*.sv]

# Add testbench
add_files -fileset sim_1 [glob -nocomplain tb/integration/*.sv]

set_property top ethernet_frame_parser_stress_tb [get_filesets sim_1]

update_compile_order -fileset sim_1

launch_simulation
run all
