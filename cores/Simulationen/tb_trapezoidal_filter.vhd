library ieee;
  use ieee.NUMERIC_STD.all;
  use ieee.std_logic_1164.all;

library std;
  use std.textio.all;

entity tb_trapezoidal_filter is
end entity;

architecture rtl_sim of tb_trapezoidal_filter is

  constant word_width: natural := 14;
  constant buffer_length: natural := 100;
  constant max_multiplier_word_width: natural := 10;
  -- these are the constants that define the delay
  -- cycles needed to synchronize the tick inputs
  -- with the signal.
  constant tick_delay: natural := 2+3;

  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  
  -- parameters from software
  signal k: natural range 0 to buffer_length;
  signal l: natural range 0 to buffer_length;
  signal m: signed(max_multiplier_word_width - 1 downto 0);
  
  -- data input and output
  signal data_in: signed(word_width - 1 downto 0);
  signal data_out: signed(word_width + max_multiplier_word_width downto 0);
  signal speed_tick: std_logic;
  signal cycle_tick: std_logic;
  signal syncd_cycle_tick: std_logic;
  signal syncd_speed_tick: std_logic;
  
  -- control inputs
  signal clk: std_logic;
  signal clr: std_logic;
  
  -- Files
  constant line_width: natural := 10;
  file input_file: text;
  file output_file: text;
begin

  -- instantiate dut
  trapezoidal_filter_inst: entity work.trapezoidal_filter
    generic map (
      word_width                => word_width,
      buffer_length             => buffer_length,
      max_multiplier_word_width => max_multiplier_word_width
    )
    port map (
      k                         => k,
      l                         => l,
      m                         => m,
      data_in                   => data_in,
      data_out                  => data_out,
      clk                       => clk,
      clr                       => clr,
      cycle_tick                => cycle_tick,
      speed_tick                => speed_tick,
      syncd_cycle_tick          => syncd_cycle_tick,
      syncd_speed_tick          => syncd_speed_tick
    );
  
  -- set parameters for test
  k <= 30;
  l <= 100;
  m <= to_signed(500, max_multiplier_word_width);
  cycle_tick <= '0';
  speed_tick <= '0';
  -- read stimulus from file
  stimulus : process
    variable in_line    :   line;
    variable out_line   :   line;
    variable sig_f_file :   integer := 0;
  begin
    file_open(input_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\tests\trapezoidal_filter_test.dat", read_mode);
    --file_open(output_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\testresults\trapezoidal_filter_results.dat", write_mode);
    while not endfile(input_file) loop
      readline(input_file, in_line);
      read(in_line, sig_f_file);
      wait until rising_edge(clk);
      data_in <= to_signed(sig_f_file, word_width);
      --write(out_line, to_integer(data_out), left, line_width);
      --writeline(output_file, out_line);
      wait for CLK_PERIOD;
    end loop;
    file_close(input_file);
    file_close(output_file);
  end process;

  -- generate clock
  clock_p: process is
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  -- generate reset
  reset_p: process is
  begin
    clr <= '1';
    wait for RST_HOLD_DURATION;
    wait until rising_edge(clk);
    clr <= '0';
    wait;
  end process;

end architecture;

