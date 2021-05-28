library ieee;
  use ieee.NUMERIC_STD.all;
  use ieee.std_logic_1164.all;

library std;
  use std.textio.all;
library work;
  use work.filtertypes.all;

entity tb_signal_filter is
end entity;

architecture rtl_sim of tb_signal_filter is

  constant s_word_width: natural := 14;
  constant tf_buffer_length: natural := 100;
  constant tf_max_multiplier_word_width: natural := 11;
  constant speed_counter_width: natural := 10;
  constant cycle_counter_width: natural := 18;
  constant timer_width: natural := 40;
  constant event_filter_buffer_depth: natural := 5;
  constant event_filter_timer_width: natural := event_filter_timer_width;
  constant kl_param_width : natural := KL_PARAM_WIDTH;
  constant accum_2_ext : natural := accum_2_ext;

  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  signal k: unsigned(KL_PARAM_WIDTH-1 downto 0);
  signal l: unsigned(KL_PARAM_WIDTH-1 downto 0);
  signal m: signed(tf_max_multiplier_word_width - 1 downto 0);
  signal data_in: signed(s_word_width - 1 downto 0);
  signal peak_filter_threshhold: signed(s_word_width + tf_max_multiplier_word_width + accum_2_ext - 1 downto 0);
  signal event_filter_accum_time: unsigned(event_filter_timer_width - 1 downto 0);
  signal cycle_tick: std_logic;
  signal speed_tick: std_logic;
  signal event_out: std_logic_vector(s_word_width + tf_max_multiplier_word_width + accum_2_ext
                                     + speed_counter_width + cycle_counter_width
                                     + timer_width - 1 downto 0);
  signal event_out_flag: std_logic;
  signal clk: std_logic;
  signal rst: std_logic;
  
  -- File input
  constant line_width: natural := 10;
  file input_file: text;
  file output_file: text;

begin

  signal_filter_inst: entity work.signal_filter
    generic map (
      s_word_width                 => s_word_width,
      tf_buffer_length             => tf_buffer_length,
	  KL_PARAM_WIDTH			   => kl_param_width,
      tf_max_multiplier_word_width => tf_max_multiplier_word_width,
	  accum_2_extension			   => accum_2_ext,
      speed_counter_width          => speed_counter_width,
      cycle_counter_width          => cycle_counter_width,
      timer_width                  => timer_width,
      event_filter_buffer_depth    => event_filter_buffer_depth,
      event_filter_timer_width     => event_filter_timer_width
    )
    port map (
      k                            => k,
      l                            => l,
      m                            => m,
      data_in                      => data_in,
      peak_filter_threshhold       => peak_filter_threshhold,
      event_filter_accum_time      => event_filter_accum_time,
      cycle_tick                   => cycle_tick,
      speed_tick                   => speed_tick,
      event_out                    => event_out,
      event_out_flag               => event_out_flag,
      clk                          => clk,
      rst                          => rst
    );

  stimulus : process
    variable in_line    :   line;
    variable readnat : natural;
    variable readval : integer;
    variable conversion: unsigned(0 downto 0);
    variable space: character;
  begin
    file_open(input_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\tests\filter_integration_test_13_bit.dat", read_mode);
    readline(input_file, in_line);
    read(in_line, readnat);
    k <= to_unsigned(readnat, KL_PARAM_WIDTH);
    readline(input_file, in_line);
    read(in_line, readnat);
    l <= to_unsigned(readnat, KL_PARAM_WIDTH);
    readline(input_file, in_line);
    read(in_line, readval);
    m <= to_signed(readval, m'length);
    readline(input_file, in_line);
    read(in_line, readval);
    peak_filter_threshhold <= to_signed(readval, peak_filter_threshhold'length);
    readline(input_file, in_line);
    read(in_line, readval);
    event_filter_accum_time <= to_unsigned(readval, event_filter_accum_time'length);
    while not endfile(input_file) loop
      wait until rising_edge(clk);
      readline(input_file, in_line);
      read(in_line, readval);
      data_in <= to_signed(readval, s_word_width);
      read(in_line, space);
      read(in_line, readval);
      conversion := to_unsigned(readval, 1);
      cycle_tick <= conversion(0);
      read(in_line, space);
      read(in_line, readval);
      conversion := to_unsigned(readval, 1);
      speed_tick <= conversion(0);
    end loop;
    file_close(input_file);
  end process;

  clock_p: process is
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;
  
  reset_p: process is
  begin
    rst <= '1';
    wait for RST_HOLD_DURATION;
    wait until rising_edge(clk);
    rst <= '0';
    wait;
  end process;

end architecture;

