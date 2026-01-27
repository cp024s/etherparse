# ================================
# Vivado Synthesis Script (FIXED)
# ================================

set SCRIPT_DIR [file dirname [info script]]
set ROOT_DIR   [file normalize "$SCRIPT_DIR/.."]

puts "SCRIPT_DIR = $SCRIPT_DIR"
puts "ROOT_DIR   = $ROOT_DIR"

create_project eth_parser_synth "$ROOT_DIR/vivado_synth" -part xc7a35tcpg236-1 -force

set_property include_dirs [list \
    "$ROOT_DIR/pkg" \
    "$ROOT_DIR/rtl" \
    "$ROOT_DIR/rtl/axis" \
    "$ROOT_DIR/rtl/parser" \
    "$ROOT_DIR/rtl/metadata" \
] [current_fileset]

add_files [list \
    "$ROOT_DIR/pkg/eth_parser_pkg.sv" \
    "$ROOT_DIR/rtl/axis/axis_skid_buffer.sv" \
    "$ROOT_DIR/rtl/axis/axis_ingress.sv" \
    "$ROOT_DIR/rtl/axis/axis_egress.sv" \
    "$ROOT_DIR/rtl/parser/byte_counter.sv" \
    "$ROOT_DIR/rtl/parser/frame_control_fsm.sv" \
    "$ROOT_DIR/rtl/parser/header_shift_register.sv" \
    "$ROOT_DIR/rtl/parser/eth_header_parser.sv" \
    "$ROOT_DIR/rtl/parser/vlan_resolver.sv" \
    "$ROOT_DIR/rtl/parser/protocol_classifier.sv" \
    "$ROOT_DIR/rtl/metadata/metadata_packager.sv" \
    "$ROOT_DIR/rtl/ethernet_frame_parser.sv" \
]

set_property top ethernet_frame_parser [current_fileset]

synth_design -top ethernet_frame_parser -part xc7a35tcpg236-1
report_utilization -file "$ROOT_DIR/vivado_synth/util.rpt"
report_timing_summary -file "$ROOT_DIR/vivado_synth/timing.rpt"
