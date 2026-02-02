# ============================================================
# Vivado Bitstream Generation Script
# ============================================================

set proj_name ethernet_parser_bitstream
set build_dir build/vivado/bitstream

file mkdir $build_dir
create_project $proj_name $build_dir -part xc7a35tcsg324-1 -force

add_files [glob -nocomplain pkg/*.sv]
add_files [glob -nocomplain rtl/**/*.sv]

set_property top ethernet_frame_parser [current_fileset]

update_compile_order -fileset sources_1

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

write_bitstream -force $build_dir/ethernet_frame_parser.bit
