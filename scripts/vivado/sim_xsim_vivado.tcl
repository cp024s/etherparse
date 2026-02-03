# ============================================================
# Vivado Behavioral Simulation (xsim)
# ============================================================

create_project eth_parser_sim ./vivado_sim -part xc7a200tfbg484-1 -force

# === Add RTL (same order as syntax check) ===
add_files pkg/eth_parser_pkg.sv

add_files rtl/axis/axis_ingress.sv
add_files rtl/axis/axis_egress.sv
add_files rtl/axis/axis_skid_buffer.sv

add_files rtl/parser/frame_control_fsm.sv
add_files rtl/parser/byte_counter.sv
add_files rtl/parser/header_shift_register.sv
add_files rtl/parser/eth_header_parser.sv
add_files rtl/parser/vlan_resolver.sv
add_files rtl/parser/protocol_classifier.sv

add_files rtl/metadata/metadata_packager.sv
add_files rtl/ethernet_frame_parser.sv

# === Add TESTBENCH ===
add_files -fileset sim_1 tb/integration/parser_pipeline_tb.sv

# === Set tops ===
set_property top ethernet_frame_parser [current_fileset]
set_property top parser_pipeline_tb [get_filesets sim_1]

# === Compile & simulate ===
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation
run all
quit
