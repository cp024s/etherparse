# ============================================================
# Vivado Implementation Script
# ============================================================

set proj_name ethernet_parser_impl
set build_dir build/vivado/impl

file mkdir $build_dir
create_project $proj_name $build_dir -part xc7a35tcsg324-1 -force

add_files [glob -nocomplain pkg/*.sv]
add_files [glob -nocomplain rtl/**/*.sv]

set_property top ethernet_frame_parser [current_fileset]

update_compile_order -fileset sources_1

launch_runs impl_1 -to_step route_design -jobs 4
wait_on_run impl_1

report_utilization -file $build_dir/utilization_impl.rpt
report_timing_summary -file $build_dir/timing_impl.rpt
