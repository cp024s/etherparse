create_project eth_parser_sim ./vivado_sim -part xc7a200tfbg484-1 -force

# === Add RTL in correct order ===
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

# === Set top ===
set_property top ethernet_frame_parser [current_fileset]

# === Elaboration / syntax check only ===
update_compile_order -fileset sources_1
check_syntax
