library ieee;
  use ieee.NUMERIC_STD.all;
  use ieee.std_logic_1164.all;

library std;
  use std.textio.all;

entity tb_event_assembly is
end entity;

architecture rtl_sim of tb_event_assembly is

  constant signal_word_width: natural := 25;
  constant speed_tick_counter_width: natural := 10;
  constant cycle_tick_counter_width: natural := 18;
  constant timestamp_word_width: natural := 40;

  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  signal signal_in: signed(signal_word_width - 1 downto 0);
  signal peak_in: std_logic;
  signal cycle_tick: std_logic;
  signal speed_tick: std_logic;
  signal event_out: std_logic_vector(signal_word_width + speed_tick_counter_width + cycle_tick_counter_width + timestamp_word_width - 1 downto 0);
  signal event_ind: std_logic;
  signal clk: std_logic;
  signal rst: std_logic;
  
  -- Files
  constant line_width: natural := 20;
  file input_file: text;
  file output_file: text;
begin

  event_assembly_inst: entity work.event_assembly
    generic map (
      signal_word_width        => signal_word_width,
      speed_tick_counter_width => speed_tick_counter_width,
      cycle_tick_counter_width => cycle_tick_counter_width,
      timestamp_word_width     => timestamp_word_width
    )
    port map (
      signal_in                => signal_in,
      peak_in                  => peak_in,
      cycle_tick               => cycle_tick,
      speed_tick               => speed_tick,
      event_out                => event_out,
      event_ind                => event_ind,
      clk                      => clk,
      rst                      => rst
    );
  
  -- read stimulus from file
  stimulus : process
    variable in_line    :   line;
    variable out_line   :   line;
    variable sig_f_file :   integer := 0;
    variable speedt_f_file: integer;
    variable cycle_f_file: integer;
    variable event_f_file: integer;
    variable typeconv: std_logic_vector(0 downto 0);
    variable space: character;
  begin
    file_open(input_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\tests\event_assembly_test.dat", read_mode);
    while not endfile(input_file) loop
      readline(input_file, in_line);
      read(in_line, sig_f_file);
      read(in_line, space);
      read(in_line, event_f_file);
      read(in_line, space);
      read(in_line, speedt_f_file);
      read(in_line, space);
      read(in_line, cycle_f_file);
      wait until rising_edge(clk);
      signal_in <= to_signed(sig_f_file, signal_word_width);
      typeconv := std_logic_vector(to_unsigned(event_f_file, 1));
      peak_in <= typeconv(0);
      typeconv := std_logic_vector(to_unsigned(cycle_f_file, 1));
      cycle_tick <= typeconv(0);
      typeconv := std_logic_vector(to_unsigned(speedt_f_file, 1));
      speed_tick <= typeconv(0);
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

