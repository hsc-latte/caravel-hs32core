set script_dir [file dirname [file normalize [info script]]]

set ::env(ROUTING_CORES) 16

set ::env(DESIGN_NAME) user_project_wrapper
set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

set ::env(PDN_CFG) $script_dir/pdn.tcl
set ::env(FP_PDN_CORE_RING) 1
set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 2920 3520"

set ::unit 2.4
set ::env(FP_IO_VEXTEND) [expr 2*$::unit]
set ::env(FP_IO_HEXTEND) [expr 2*$::unit]
set ::env(FP_IO_VLENGTH) $::unit
set ::env(FP_IO_HLENGTH) $::unit

set ::env(FP_IO_VTHICKNESS_MULT) 4
set ::env(FP_IO_HTHICKNESS_MULT) 4

set ::env(CLOCK_PORT) "user_clock2"
set ::env(CLOCK_NET) "core1.wb_clk_i"

set ::env(CLOCK_PERIOD) "20"

set ::env(PL_OPENPHYSYN_OPTIMIZATIONS) 0
set ::env(DIODE_INSERTION_STRATEGY) 1

# Because of sram
set ::env(MAGIC_DRC_USE_GDS) 0

# Need to fix a FastRoute bug for this to work, but it's good
# for a sense of "isolation"
set ::env(MAGIC_ZEROIZE_ORIGIN) 0
set ::env(MAGIC_WRITE_FULL_LEF) 1

set ::env(VERILOG_FILES) "\
	$script_dir/../../verilog/rtl/defines.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/hs32_wrapper.v"

set ::env(VERILOG_FILES_BLACKBOX) "\
	$script_dir/../../verilog/rtl/defines.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/hs32_core1.v \
    $script_dir/../../verilog/rtl/sram_1rw1r_32_256_8_sky130.v"

set ::env(EXTRA_LEFS) "\
	$script_dir/../../lef/hs32_core1.lef \
    $script_dir/../../macros/lef/sram_1rw1r_32_256_8_sky130_lp1.lef"

set ::env(EXTRA_GDS_FILES) "\
	$script_dir/../../gds/hs32_core1.gds \
    $script_dir/../../macros/gds/sram_1rw1r_32_256_8_sky130.gds"
