package require openlane
set script_dir [file dirname [file normalize [info script]]]

prep -design $script_dir -tag user_project_wrapper -overwrite
set save_path $script_dir/../..

verilog_elaborate

init_floorplan

place_io_ol

set ::env(FP_DEF_TEMPATE) $script_dir/../../def/user_project_wrapper_empty.def

apply_def_template

#add_macro_placement core0 1550  400 N
add_macro_placement core1  300 1500 N
add_macro_placement sram0  300 2800 N
add_macro_placement sram1  950 2800 N
add_macro_placement sram2 1550 2800 N
add_macro_placement sram3 2200 2800 N

#add_macro_placement sram4 1700 1600 S;  # RX buffer for core1
#add_macro_placement sram5 2250 1600 N;  # RX buffer for core0


manual_macro_placement f

set ::env(_SPACING) 1.7
set ::env(_WIDTH) 3

set power_domains [list {vccd1 vssd1} {vccd2 vssd2} {vdda1 vssa1} {vdda2 vssa2}]

set ::env(_VDD_NET_NAME) vccd1
set ::env(_GND_NET_NAME) vssd1
set ::env(_V_OFFSET) 14
set ::env(_H_OFFSET) $::env(_V_OFFSET)
set ::env(_V_PITCH) 180
set ::env(_H_PITCH) 180
set ::env(_V_PDN_OFFSET) 0
set ::env(_H_PDN_OFFSET) 0

set ::env(CONNECT_GRIDS) 1
foreach domain $power_domains {
	set ::env(_VDD_NET_NAME) [lindex $domain 0]
	set ::env(_GND_NET_NAME) [lindex $domain 1]
	gen_pdn
	
	set ::env(CONNECT_GRIDS) 0
	set ::env(_V_OFFSET) \
	[expr $::env(_V_OFFSET) + 2*($::env(_WIDTH)+$::env(_SPACING))]
	set ::env(_H_OFFSET) \
	[expr $::env(_H_OFFSET) + 2*($::env(_WIDTH)+$::env(_SPACING))]
	set ::env(_V_PDN_OFFSET) [expr $::env(_V_PDN_OFFSET)+6*$::env(_WIDTH)]
	set ::env(_H_PDN_OFFSET) [expr $::env(_H_PDN_OFFSET)+6*$::env(_WIDTH)]
}

add_route_obs
global_routing
detailed_routing

write_powered_verilog -power vccd1 -ground vssd1
set_netlist $::env(lvs_result_file_tag).powered.v
run_magic
run_magic_spice_export

save_views       -lef_path $::env(magic_result_file_tag).lef \
                 -def_path $::env(tritonRoute_result_file_tag).def \
                 -gds_path $::env(magic_result_file_tag).gds \
                 -mag_path $::env(magic_result_file_tag).mag \
                 -save_path $save_path \
                 -tag $::env(RUN_TAG)

run_magic_drc

run_lvs; # requires run_magic_spice_export

run_antenna_check
