# ==============================================================================
# Script for generating the block design that will generate the block design
# for the Moessbauer laboratory
# 07.05.2019 
# Alexander Becker
# ==============================================================================

# Create basic Red Pitaya Block Design
#set project_name 4_averager
set part_name xc7z010clg400-1
set bd_path tmp/$project_name/$project_name.srcs/sources_1/bd/system

file delete -force tmp/$project_name

create_project $project_name tmp/$project_name -part $part_name

create_bd_design system
# open_bd_design {$bd_path/system.bd}

# Load RedPitaya ports
source cfg/ports.tcl

# Set Path for the custom IP cores
set_property IP_REPO_PATHS tmp/cores [current_project]
update_ip_catalog


# Load any additional Verilog files in the project folder
set files [glob -nocomplain projects/$project_name/*.v projects/$project_name/*.sv projects/$project_name/*.vhd]
if {[llength $files] > 0} {
  add_files -norecurse $files
}
#update_compile_order -fileset sources_1


# ====================================================================================
# IP cores
# Zynq processing system with RedPitaya specific preset
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_IMPORT_BOARD_PRESET {cfg/red_pitaya.xml}] [get_bd_cells processing_system7_0]
endgroup

# Buffers for differential IOs - Dasychain
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_1
set_property -dict [list CONFIG.C_SIZE {2}] [get_bd_cells util_ds_buf_1]

create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_2
set_property -dict [list CONFIG.C_SIZE {2}] [get_bd_cells util_ds_buf_2]
set_property -dict [list CONFIG.C_BUF_TYPE {OBUFDS}] [get_bd_cells util_ds_buf_2]
endgroup

# MB filter instantiation
create_bd_cell -type ip -vlnv alexander-becker:user:Trapezfilter MB_filter

# ====================================================================================
# Connections 

connect_bd_net [get_bd_ports daisy_p_i] [get_bd_pins util_ds_buf_1/IBUF_DS_P]
connect_bd_net [get_bd_ports daisy_n_i] [get_bd_pins util_ds_buf_1/IBUF_DS_N]
connect_bd_net [get_bd_ports daisy_p_o] [get_bd_pins util_ds_buf_2/OBUF_DS_P]
connect_bd_net [get_bd_ports daisy_n_o] [get_bd_pins util_ds_buf_2/OBUF_DS_N]
connect_bd_net [get_bd_pins util_ds_buf_1/IBUF_OUT] [get_bd_pins util_ds_buf_2/OBUF_IN]

apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
connect_bd_net [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK0]

# Connect the AXI slave port of the mb filter to the zynq
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins MB_filter/S_AXI_PS_INTERFACE]
set_property CONFIG.FREQ_HZ 125000000 [get_bd_intf_pins /MB_filter/S_AXI_PS_INTERFACE]

# connect the speed tick and the cycle tick
connect_bd_net [get_bd_ports cycle_tick_in] [get_bd_pins MB_filter/cycle_tick]
connect_bd_net [get_bd_ports speed_tick_in] [get_bd_pins MB_filter/speed_tick]

# connect the leds to the filter level indicator
connect_bd_net [get_bd_ports led_o] [get_bd_pins MB_filter/fifo_fill]

# connect the ADC inputs to the buffer
connect_bd_net [get_bd_ports adc_clk_p_i] [get_bd_pins MB_filter/adc_clk_a]
connect_bd_net [get_bd_ports adc_clk_n_i] [get_bd_pins MB_filter/adc_clk_b]
connect_bd_net [get_bd_ports adc_dat_a_i] [get_bd_pins MB_filter/adc_data_a]
connect_bd_net [get_bd_ports adc_dat_b_i] [get_bd_pins MB_filter/adc_data_b]
connect_bd_net [get_bd_ports adc_csn_o] [get_bd_pins MB_filter/adc_csn]

set_property offset 0x42000000 [get_bd_addr_segs {processing_system7_0/Data/SEG_MB_filter_reg0}]
set_property range 4K [get_bd_addr_segs {processing_system7_0/Data/SEG_MB_filter_reg0}]

# ====================================================================================
# Generate output products and wrapper, add constraint 

regenerate_bd_layout

generate_target all [get_files  $bd_path/system.bd]

make_wrapper -files [get_files $bd_path/system.bd] -top
add_files -norecurse $bd_path/hdl/system_wrapper.v


# Load RedPitaya constraint files
set files [glob -nocomplain cfg/*.xdc]
if {[llength $files] > 0} {
  add_files -norecurse -fileset constrs_1 $files
}

#set_property top system_wrapper [current_fileset]
set_property VERILOG_DEFINE {TOOL_VIVADO} [current_fileset]
set_property STRATEGY Flow_PerfOptimized_High [get_runs synth_1]
set_property STRATEGY Performance_NetDelay_high [get_runs impl_1]
