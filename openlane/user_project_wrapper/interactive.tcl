package require openlane
set script_dir [file dirname [file normalize [info script]]]

prep -design $script_dir -tag user_project_wrapper -overwrite
set save_path $script_dir/../..

verilog_elaborate

init_floorplan

place_io_ol

#add_macro_placement core1  300 1000 N
#add_macro_placement sram0  300 2300 N
#add_macro_placement sram1  950 2300 N
#add_macro_placement sram2 1550 2300 N
#add_macro_placement sram3 2200 2300 N

add_macro_placement core1 1400 1200 N
add_macro_placement sram0 1500 2600 N
add_macro_placement sram1 2100 2600 N
add_macro_placement sram2 1500  550 S
add_macro_placement sram3 2100  550 S

manual_macro_placement f

exec -ignorestderr openroad -exit $script_dir/gen_pdn.tcl
set_def $::env(pdn_tmp_file_tag).def

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
