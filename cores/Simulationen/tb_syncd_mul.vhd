library ieee;
  use ieee.NUMERIC_STD.all;
  use ieee.std_logic_1164.all;

library std;
  use std.textio.all;

entity tb_syncd_mul is
end entity;

architecture rtl_sim of tb_syncd_mul is

  constant in_1_word_width: natural := 8;
  constant in_2_word_width: natural := 8;

  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  signal in_1: signed(in_1_word_width - 1 downto 0);
  signal in_2: signed(in_1_word_width - 1 downto 0);
  signal clk: std_logic;
  signal rst: std_logic;
  signal mul_out: signed(in_1_word_width + in_2_word_width - 1 downto 0);
  
  file input_file: text;
  file output_file: text;

begin

  syncd_mul_inst: entity work.syncd_mul
    generic map (
      in_1_word_width => in_1_word_width,
      in_2_word_width => in_2_word_width
    )
    port map (
      in_1            => in_1,
      in_2            => in_2,
      clk             => clk,
      rst             => rst,
      mul_out         => mul_out
    );

  stimulus_p : process
    variable in_line    :   line;
    variable int_1   :   integer := 0;
    variable int_2   :   integer := 0;
    variable space      :   character;
  begin
    file_open(input_file, "C:\Users\Alexander\Bachelorarbeit\simdaten\Trapezfilter\delay_buffer\test", read_mode);
    while not endfile(input_file) loop
      readline(input_file, in_line);
      read(in_line, int_1);
      read(in_line, space);
      read(in_line, int_2);
      wait until rising_edge(clk);
      in_1 <= to_signed(int_1, in_1_word_width);
      in_2 <= to_signed(int_2, in_2_word_width);
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

