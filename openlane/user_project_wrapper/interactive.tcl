package require openlane
set script_dir [file dirname [file normalize [info script]]]

prep -design $script_dir -tag user_project_wrapper -overwrite
set save_path $script_dir/../..

verilog_elaborate

init_floorplan

place_io_ol

set ::env(FP_DEF_TEMPATE) $script_dir/../../def/user_project_wrapper_empty.def

apply_def_template

add_macro_placement core0 1550  400 N
add_macro_placement core1  300 1600 N
add_macro_placement sram0  300 2800 N
add_macro_placement sram1  950 2800 N
add_macro_placement sram2 1550 2800 N
add_macro_placement sram3 2200 2800 N

add_macro_placement sram4 1700 1600 S;  # RX buffer for core1
add_macro_placement sram5 2250 1600 N;  # RX buffer for core0


manual_macro_placement f

exec -ignorestderr openroad -exit $script_dir/gen_pdn.tcl
set_def $::env(pdn_tmp_file_tag).def

global_routing
add_route_obs
detailed_routing

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
