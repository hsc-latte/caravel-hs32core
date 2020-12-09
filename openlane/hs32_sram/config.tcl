set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) hs32_sram

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "10"

set ::env(DESIGN_IS_CORE) 0

set ::env(PDN_CFG) $script_dir/pdn.tcl

set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg
set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 1100 1100"

set ::env(FP_HORIZONTAL_HALO) 5
set ::env(FP_VERTICAL_HALO) 14
#set ::env(FP_PDN_VOFFSET) 5
#set ::env(FP_PDN_VPITCH) 20
#set ::env(FP_PDN_HPITCH) 50

#set ::env(MACRO_PLACEMENT_CFG) $script_dir/macro_placement.cfg

set ::env(PL_TARGET_DENSITY) 0.5

set ::env(GLB_RT_MINLAYER) 2
set ::env(GLB_RT_MAXLAYER) 5
set ::env(GLB_RT_ALLOW_CONGESTION) 1

set ::env(DIODE_INSERTION_STRATEGY) 1

# Disable DRC
set ::env(MAGIC_DRC_USE_GDS) 0

set ::env(VERILOG_FILES) "\
	$script_dir/../../verilog/rtl/defines.v\
	$script_dir/../../verilog/rtl/hs32_user_proj/hs32_sram.v"

set ::env(VERILOG_FILES_BLACKBOX) "\
	$script_dir/../../verilog/rtl/sram_1rw1r_32_256_8_sky130.v"

set ::env(EXTRA_LEFS) "\
	$script_dir/../../lef/sram_1rw1r_32_256_8_sky130_lp1.lef"

set ::env(EXTRA_GDS_FILES) "\
	$script_dir/../../gds/sram_1rw1r_32_256_8_sky130_lp1.gds"
