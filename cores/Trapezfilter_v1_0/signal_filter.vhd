library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library work;
  use work.filtertypes.all;

entity signal_filter is
  -- parameters
  generic(  s_word_width: natural;
            tf_buffer_length: natural;
            KL_PARAM_WIDTH: natural;
            tf_max_multiplier_word_width: natural;
            accum_2_extension: natural;
            speed_counter_width: natural;
            cycle_counter_width: natural;
            timer_width: natural;
            event_filter_buffer_depth: natural;
            event_filter_timer_width: natural
          );
  port   (  -- parameters from software
    signal k: in unsigned(KL_PARAM_WIDTH-1 downto 0) := (others => '0');
    signal l: in unsigned(KL_PARAM_WIDTH-1 downto 0) := (others => '0');
    signal m: in signed(tf_max_multiplier_word_width - 1 downto 0) := (others => '0');
    signal peak_filter_threshhold: in signed(s_word_width + tf_max_multiplier_word_width + accum_2_extension - 1 downto 0) := (others => '0');
    signal event_filter_accum_time: in unsigned(event_filter_timer_width-1 downto 0) := (others => '0');

    -- signal in
    signal data_in: in signed(s_word_width-1 downto 0) := (others => '0');
    signal cycle_tick: in std_logic := '0';
    signal speed_tick: in std_logic := '0';

    -- signal out
    signal event_out: out std_logic_vector(s_word_width + tf_max_multiplier_word_width + accum_2_extension
                                 + speed_counter_width + cycle_counter_width
                                 + timer_width - 1 downto 0) := (others => '0');
    signal event_out_flag: out std_logic := '0';

    -- control inputs
    signal clk: in std_logic := '0';
    signal rst: in std_logic := '1'
  );
end signal_filter;

architecture signal_filter_arch of signal_filter is
  subtype sig_t is signed(s_word_width + tf_max_multiplier_word_width + accum_2_extension -1 downto 0);
  subtype event_t is std_logic_vector(sig_t'length + speed_counter_width + cycle_counter_width + timer_width - 1 downto 0);
  subtype event_timer_t is unsigned(event_filter_timer_width - 1 downto 0);
  signal filtered_signal: sig_t;
  signal pd_syncd_signal: sig_t;
  signal pf_syncd_signal: sig_t;
  signal tf_syncd_cyclet: std_logic;
  signal pd_syncd_cyclet: std_logic;
  signal pf_syncd_cyclet: std_logic;
  signal tf_syncd_speedt: std_logic;
  signal pd_syncd_speedt: std_logic;
  signal pf_syncd_speedt: std_logic;
  signal detected_peak: std_logic;
  signal filtered_peaks: std_logic;
  signal event_flag: std_logic;
  signal generated_events: event_t;
begin
  trapezoidal_filter: entity work.trapezoidal_filter
    generic map (word_width => s_word_width,
                buffer_length => tf_buffer_length,
                max_multiplier_word_width => tf_max_multiplier_word_width,
                param_width => KL_PARAM_WIDTH,
    )
    port map (
      clk               => clk,
      clr               => rst,
      k                 => k,
      l                 => l,
      m                 => m,
      data_in           => data_in,
      cycle_tick        => cycle_tick,
      speed_tick        => speed_tick,
      data_out          => filtered_signal,
      syncd_cycle_tick  => tf_syncd_cyclet,
      syncd_speed_tick  => tf_syncd_speedt
    );

  peakfinder: entity work.peakfinder
    generic map (
      word_width => sig_t'length
    )
    port map (
      clk => clk,
      clr => rst,
      in_signal => filtered_signal,
      in_cycle_tick => tf_syncd_cyclet,
      in_speed_tick => tf_syncd_speedt,
      peak => detected_peak,
      syncd_sig => pd_syncd_signal,
      syncd_cycle_tick => pd_syncd_cyclet,
      syncd_speed_tick => pd_syncd_speedt
    );

  peakdiskriminator: entity work.peak_diskriminator
    generic map (
      word_width => sig_t'length
    )
    port map (
      clk => clk,
      clr => rst,
      peak_flag => detected_peak,
      data_stream => pd_syncd_signal,
      cycle_tick => pd_syncd_cyclet,
      speed_tick => pd_syncd_speedt,
      syncd_cycle_tick => pf_syncd_cyclet,
      syncd_speed_tick => pf_syncd_speedt,
      peak_threshhold => peak_filter_threshhold,
      filtered_peaks => pf_syncd_signal,
      filtered_flag => filtered_peaks
    );
  
  event_assembly: entity work.event_assembly
    generic map (
      signal_word_width => sig_t'length,
      speed_tick_counter_width => speed_counter_width,
      cycle_tick_counter_width => cycle_counter_width,
      timestamp_word_width => timer_width
    )
    port map (
      clk => clk,
      rst => rst,
      signal_in => pf_syncd_signal,
      peak_in => filtered_peaks,
      cycle_tick => pf_syncd_cyclet,
      speed_tick => pf_syncd_speedt,
      event_out => generated_events,
      event_ind => event_flag
    );
  
  event_filter: entity work.event_filter
    generic map (
      peakval_left => event_t'length-1,
      peakval_right => event_t'length - sig_t'length -1,
      packet_width => event_t'length,
      buffer_depth => event_filter_buffer_depth,
      timer_width => event_timer_t'length
    )
    port map (
      in_event => generated_events,
      event_in_flag => event_flag,
      clk => clk,
      clr => rst,
      totzeit => event_filter_accum_time,
      out_event => event_out,
      event_out_flag => event_out_flag
    );
end signal_filter_arch;
