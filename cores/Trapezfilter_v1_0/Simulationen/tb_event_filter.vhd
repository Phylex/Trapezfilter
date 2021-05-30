library ieee;
  use ieee.std_logic_1164.all;
  use ieee.NUMERIC_STD.all;

library std;
  use std.textio.all;

entity tb_event_filter is
end entity;

architecture rtl_sim of tb_event_filter is

  constant peakval_left: natural := 7;
  constant peakval_right: natural := 0;
  constant packet_width: natural := 8;
  constant buffer_depth: natural := 5;
  constant timer_width: natural := 10;

  constant CLK_PERIOD: time := 8 ns;
  constant SHIFT_PERIOD: time := 32 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  signal in_event: std_logic_vector(packet_width - 1 downto 0);
  signal event_in_flag: std_logic;
  signal clk: std_logic;
  signal clr: std_logic;
  signal totzeit: unsigned(timer_width - 1 downto 0);
  signal out_event: std_logic_vector(packet_width - 1 downto 0);
  signal event_out_flag: std_logic;

  -- file input
  constant line_width: natural := 10;
  file input_file: text;
  file output_file: text;
  
begin
  -- set the wait time after an event
  totzeit <= to_unsigned(24, timer_width);
  
  -- instantiate dut
  event_filter_inst: entity work.event_filter
    generic map (
      peakval_left   => peakval_left,
      peakval_right  => peakval_right,
      packet_width   => packet_width,
      buffer_depth   => buffer_depth,
      timer_width    => timer_width
    )
    port map (
      in_event       => in_event,
      event_in_flag  => event_in_flag,
      clk            => clk,
      clr            => clr,
      totzeit        => totzeit,
      out_event      => out_event,
      event_out_flag => event_out_flag
    );

  stimuli_p: process is
    variable in_line    :   line;
    variable out_line   :   line;
    variable sig_f_file :   integer := 0;
  begin
    wait for 4 ns;
    file_open(input_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\tests\max_shift_test.dat", read_mode);
  --file_open(output_file, "", write_mode);
  while not endfile(input_file) loop
    readline(input_file, in_line);
    read(in_line, sig_f_file);
    wait until rising_edge(clk);
    in_event <= std_logic_vector(to_signed(sig_f_file, packet_width));
    event_in_flag <= '1';
    wait for CLK_PERIOD;
    wait until rising_edge(clk);
    event_in_flag <= '0';
    wait for SHIFT_PERIOD;
  end loop;
    wait;
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

