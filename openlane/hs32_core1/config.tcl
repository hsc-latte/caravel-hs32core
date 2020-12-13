set script_dir [file dirname [file normalize [info script]]]

set ::env(ROUTING_CORES) 16

set ::env(PDK) sky130A
set ::env(STD_CELL_LIBRARY) sky130_fd_sc_hd

set ::env(DESIGN_NAME) hs32_core1

set ::env(DESIGN_IS_CORE) 0
set ::env(GLB_RT_MINLAYER) 2
set ::env(GLB_RT_MAXLAYER) 5
#set ::env(GLB_RT_ALLOW_CONGESTION) 1

set ::env(SYNTH_STRATEGY) 1
set ::env(DIODE_INSERTION_STRATEGY) 1

set ::env(VERILOG_FILES) "\
	$script_dir/../../verilog/rtl/defines.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/hs32_core1.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/hs32_bram_ctl.v \
	$script_dir/../../verilog/rtl/hs32cpu/cpu/hs32_cpu.v \
	$script_dir/../../verilog/rtl/hs32cpu/frontend/mmio.v"

set	::env(VERILOG_INCLUDE_DIRS) "\
	$script_dir/../../verilog/rtl/hs32cpu/"

set ::env(CLOCK_PORT) "wb_clk_i"
set ::env(CLOCK_PERIOD) "25"

set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg
set ::env(FP_SIZING) absolute
set ::env(FP_PDN_CORE_RING) 0
set ::env(DIE_AREA) "0 0 1100 1100"
set ::env(PL_TARGET_DENSITY) 0.40
