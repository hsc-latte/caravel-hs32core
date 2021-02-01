set script_dir [file dirname [file normalize [info script]]]

set ::env(ROUTING_CORES) 12

set ::env(PDK) sky130A
set ::env(STD_CELL_LIBRARY) sky130_fd_sc_hd

set ::env(DESIGN_NAME) hs32_core1

set ::env(DESIGN_IS_CORE) 0
set ::env(GLB_RT_MINLAYER) 2
set ::env(GLB_RT_MAXLAYER) 5
set ::env(GLB_RT_OBS) "met5 0 0 1200 1200"
#set ::env(GLB_RT_ALLOW_CONGESTION) 1

set ::env(SYNTH_STRATEGY) 1
set ::env(DIODE_INSERTION_STRATEGY) 0

set ::env(VERILOG_FILES) "\
	$script_dir/../../verilog/rtl/defines.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/hs32_core1.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/hs32_bram_ctl.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/hs32_aic.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/io_filter.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/dev_gpio.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/dev_timer.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/dev_wb.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/dev_intercon.v \
	$script_dir/../../verilog/rtl/hs32_user_proj/dev_exsram.v \
	$script_dir/../../verilog/rtl/hs32cpu/cpu/hs32_cpu.v"

set	::env(VERILOG_INCLUDE_DIRS) "\
	$script_dir/../../verilog/rtl/hs32cpu/"

set ::env(CLOCK_PORT) "wb_clk_i"
set ::env(CLOCK_PERIOD) "23"

set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg
set ::env(FP_SIZING) absolute
set ::env(FP_PDN_CORE_RING) 0
set ::env(DIE_AREA) "0 0 1200 1200"
set ::env(PL_TARGET_DENSITY) 0.40
