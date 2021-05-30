library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

package filtertypes is
  constant AXI_4L_REGISTER_WIDTH :natural := 32;
  constant axis_data_width : natural := 32;
  constant adc_input_width : integer := 14;
  -- the accumulator has to be a bit bigger as it accumulates the signal over time
  constant accum_1_ext : integer := 5;
  constant mul_const_width : integer := 11;
  constant tf_delay_buffer_depth : natural := 128;
  constant KL_PARAM_WIDTH: natural := 7;
  -- same for the second accumulator as for the first
  constant accum_2_ext: integer := 3;
  constant timer_width : integer := 40;
  constant cycle_counter_width : integer := 18;
  constant speed_counter_width : integer := 10;
  constant event_filter_timer_width : natural := 8;
  constant event_filter_buffer_depth: natural := 10;
  -- definitions for signals not only used in the filter
  constant const_event_width: natural :=  adc_input_width + mul_const_width + accum_2_ext + speed_counter_width + cycle_counter_width + timer_width;
  constant filtered_signal_width: natural := adc_input_width + mul_const_width + accum_2_ext;
  constant merged_param_width: natural := event_filter_timer_width + 2*KL_PARAM_WIDTH+ mul_const_width + 1 + filtered_signal_width;
  
  -- constant for the FIFO
  constant FB_DEPTH :natural := 2048;
  constant FB_COUNT_WIDTH :natural := 12;
  constant FB_FULL_WARNING :natural := 900;
  constant FB_EMPTY_WARNING :natural := 100;
  constant FILTER_STATUS_WIDTH: natural := 3;
  constant AXI_ADDR_WIDTH: natural := 5;
end package filtertypes;