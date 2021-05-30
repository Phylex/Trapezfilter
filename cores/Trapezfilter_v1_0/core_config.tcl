set display_name {Trapezoidal Signal filter for the Moessbauer Laboratory}
set description {Filters the incoming capacitavly coupled signals from the detector and combines the filtered events with the data from the driving unit and a experiment wide timestamp}

set core [ipx::current_core]

# global configuration options
set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $description $core
set_property VENDOR {alexander-becker} $core
set_property VENDOR_DISPLAY_NAME {Alexander Becker} $core
set_property COMPANY_URL {http://nuclear.fail} $core

#parameters of the core
core_parameter ADC_SIGNAL_WIDTH {ADC SIGNAL WIDTH} {Width of the signal delivered by the ADC interface}
core_parameter LED_COUNT {LED COUNT} {Number of leds avaliable to show buffer fill level}
core_parameter FIFO_DEPTH {FIFO DEPTH} {Number of frames that can be stored in the fifo. Should be a power of two}
core_parameter FIFO_COUNTER_WIDTH {FIFO COUNTER WIDTH} {Width of the counter that counts the frames in the fifo}
core_parameter KL_PARAM_WIDTH {K L PARAM WIDTH} {Width of the filterparameters k and l in bits}
core_parameter TF_DELAY_DEPTH {TF DELAY DEPTH} {Depth of the fifo that delays the signal inside the trapezoidal filter}
core_parameter M_PARAM_WIDTH {M PARAM WIDTH} {The width of the filter parameter m in bits}
core_parameter ACCUM_EXT {ACCUMULATOR EXTENSION} {The amount of bits that the last accumulator is made wider by to avoid overflows}
core_parameter FILTER_STATUS_WIDTH {FILTER STATUS WIDTH} {The width of the status word that the filter writes into an axi register for the PS}
core_parameter SPEED_COUNTER_WIDTH {SPEED COUNTER WIDTH} {The width of the speed tick counter in bits}
core_parameter CYCLE_COUNTER_WIDTH {CYCLE COUNTER WIDTH} {The width of the cycle tick counter in bits}
core_parameter TIMER_WIDTH {TIMER WIDTH} {The width of the timer that generates the timestamp}
core_parameter EVENT_FILTER_DEPTH {EVENT FILTER DEPTH} {The depth of the fifo that holds frames that the frame representing the event is selected}
core_parameter EVENT_TIMER_WIDTH {EVENT TIMER WIDTH} {The width of the timer that determins the time until the frame is selected}
core_parameter C_S01_AXI_DATA_WIDTH {AXI 4L DATA WIDTH} {Width of the axi data register that is sent to the ps in one interaction}
core_parameter C_S01_AXI_ADDR_WIDTH {AXI 4L ADDRESS WIDTH} {Width of the address of the axi registers provided by the slave}

# properties of the axi 4l ps interface bus
set bus [ipx::get_bus_interfaces -of_objects $core s01_axi]
set_property NAME S_AXI_PS_INTERFACE $bus
set_property INTERFACE_MODE slave $bus
#set parameter [ipx::add_bus_parameter FREQ_HZ $bus]
#set_property FREQ_HZ 125000000 $bus

set bus [ipx::get_bus_interfaces s01_axi_aclk]
set parameter [ipx::add_bus_parameter ASSOCIATED_BUSIF $bus]
set_property VALUE S_AXI_PS_INTERFACE $parameter
set parameter [ipx::add_bus_parameter FREQ_HZ $bus]
set_property VALUE 125000000 $parameter

# create the simulation set and add the custom files to it
create_fileset -simset MB_signal_filter_sim
set_property SOURCE_SET sources_1 [get_filesets MB_signal_filter_sim]
add_files -fileset MB_signal_filter_sim -norecurse ./cores/Trapezfilter_v1_0/Simulationen/tb_MB_signal_filter_behav.wcfg
add_files -fileset MB_signal_filter_sim -norecurse ./cores/Trapezfilter_v1_0/Simulationen/MB_sim_signal_filter.vhd
add_files -fileset MB_signal_filter_sim -norecurse ./cores/Trapezfilter_v1_0/Simulationen/ADC_sim_interface.vhd
add_files -fileset MB_signal_filter_sim -norecurse ./cores/Trapezfilter_v1_0/Simulationen/tb_MB_signal_filter.vhd
update_compile_order -fileset MB_signal_filter_sim
current_fileset -simset [ get_filesets MB_signal_filter_sim ]
delete_fileset sim_1
file delete -force ./tmp/cores/Trapezfilter.srcs/sim_1
set_property top tb_MB_signal_filter [get_filesets MB_signal_filter_sim]
set_property top_lib xil_defaultlib [get_filesets MB_signal_filter_sim]
update_compile_order -fileset MB_signal_filter_sim
