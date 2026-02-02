# ============================================================
# Vivado Synthesis Script
# ============================================================

set proj_name ethernet_parser_synth
set build_dir build/vivado/synth

file mkdir $build_dir
create_project $proj_name $build_dir -part xc7a35tcsg324-1 -force

# Add RTL only (NO testbench)
add_files [glob -nocomplain pkg/*.sv]
add_files [glob -nocomplain rtl/**/*.sv]

set_property top ethernet_frame_parser [current_fileset]

update_compile_order -fileset sources_1

launch_runs synth_1 -jobs 4
wait_on_run synth_1

report_utilization -file $build_dir/utilization.rpt
report_timing_summary -file $build_dir/timing.rpt
