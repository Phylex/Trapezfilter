library ieee;
  use ieee.NUMERIC_STD.all;
  use ieee.std_logic_1164.all;

library std;
  use std.textio.all;

entity tb_peakfinder is
end entity;

architecture rtl_sim of tb_peakfinder is

  constant word_width: natural := 8;

  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  signal in_signal: signed(word_width - 1 downto 0);
  signal in_cycle_tick: std_logic;
  signal in_speed_tick: std_logic;
  signal clk: std_logic;
  signal clr: std_logic;
  signal peak: std_logic;
  signal syncd_sig: signed(word_width - 1 downto 0);
  signal syncd_cycle_tick: std_logic;
  signal syncd_speed_tick: std_logic;
  
  -- input and output files
  constant line_width: natural := 10;
  file input_file: text;
  file output_file: text;


begin

  peakfinder_inst: entity work.peakfinder
    generic map (
      word_width => word_width
    )
    port map (
      in_signal  => in_signal,
      in_cycle_tick => in_cycle_tick,
      in_speed_tick => in_speed_tick,
      clk        => clk,
      clr        => clr,
      peak       => peak,
      syncd_sig  => syncd_sig,
      syncd_cycle_tick => syncd_cycle_tick,
      syncd_speed_tick => syncd_speed_tick
    );
  stimuli_p: process is
    variable in_line : line;
    variable out_line : line;
    variable packet_val : integer := 0;
  begin
    in_cycle_tick <= '1';
    in_speed_tick <= '1';
    wait for CLK_PERIOD / 2;
    file_open(input_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\tests\peak_detector_test.dat", read_mode);
    file_open(output_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\testresults\peak_detector_testresult.dat", write_mode);
    while not endfile(input_file) loop
      readline(input_file, in_line);
      read(in_line, packet_val);
      wait until rising_edge(clk);
      in_signal <= to_signed(packet_val, word_width);
      --write(out_line, peak);
      --writeline(output_file, out_line);
    end loop;
    file_close(input_file);
    file_close(output_file);
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
    clr <= '1';
    wait for RST_HOLD_DURATION;
    wait until rising_edge(clk);
    clr <= '0';
    wait;
  end process;

end architecture;

