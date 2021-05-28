library ieee;
  use ieee.NUMERIC_STD.all;
  use ieee.std_logic_1164.all;

library std;
  use std.textio.all;

entity tb_dkl_calc is
end entity;

architecture rtl_sim of tb_dkl_calc is
  component dkl_calc is
    Generic(  input_word_width: natural;
            kplusl: natural
          );
    Port( signal data_in: in signed(input_word_width-1 downto 0);
        signal data_out: out signed(input_word_width-1 downto 0);
        
        signal clk: in std_logic;
        signal rst: in std_logic;
        
        signal k: in natural range 0 to kplusl;
        signal l: in natural range 0 to kplusl
      );
  end component;
  constant line_width: natural := 4;
  file input_file: text; -- open READ_MODE is "C:\Users\Alexander\Bachelorarbeit\test\input_acc.dat";
  file output_file: text; -- open WRITE_MODE is "C:\Users\Alexander\Bachelorarbeit\test\output_acc.dat";

  constant input_word_width: natural := 14;
  constant kplusl: natural := 20;

  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  signal data_in: signed(input_word_width - 1 downto 0);
  signal data_out: signed(input_word_width - 1 downto 0);
  signal clk: std_logic;
  signal rst: std_logic;
  signal k: natural range 0 to kplusl := 5;
  signal l: natural range 0 to kplusl := 5;

begin

  dkl_calc_inst: entity work.dkl_calc
    generic map (
      input_word_width => input_word_width,
      kplusl           => kplusl
    )
    port map (
      data_in          => data_in,
      data_out         => data_out,
      clk              => clk,
      rst              => rst,
      k                => k,
      l                => l
    );
  stimulus : process
    variable in_line    :   line;
    variable out_line   :   line;
    variable sig_f_file :   integer := 0;
  begin
    file_open(input_file, "C:\Users\Alexander\Bachelorarbeit\tests\sub_test_hand.txt", read_mode);
    file_open(output_file, "C:\Users\Alexander\Bachelorarbeit\tests\output_sub.dat", write_mode);
    while not endfile(input_file) loop
      readline(input_file, in_line);
      read(in_line, sig_f_file);
      data_in <= to_signed(sig_f_file, input_word_width);
      write(out_line, to_integer(data_out), left, line_width);
      writeline(output_file, out_line);
      wait until rising_edge(clk);
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
    rst <= '1';
    wait for RST_HOLD_DURATION;
    wait until rising_edge(clk);
    rst <= '0';
    wait;
  end process;

end architecture;

