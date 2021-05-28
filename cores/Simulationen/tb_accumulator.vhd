library ieee;
  use ieee.NUMERIC_STD.all;
  use ieee.std_logic_1164.all;

library std;
  use std.textio.all;

entity tb_accumulator is
end entity;

architecture rtl_sim of tb_accumulator is
  COMPONENT accumulator is
    Generic( word_width: natural);
    Port(
      -- Input
      signal in_sig   : in signed(word_width-1 downto 0);

      -- control input
      signal clk      : in std_logic;
      signal clr      : in std_logic;

      -- output
      signal acc_sig  : out signed(word_width-1 downto 0)
    );
  END COMPONENT;

  -- Generic Definition
  constant word_width: natural := 14;

  -- Files
  constant line_width: natural := 4;
  file input_file: text; -- open READ_MODE is "C:\Users\Alexander\Bachelorarbeit\test\input_hand.acc";
  file output_file: text; -- open WRITE_MODE is "C:\Users\Alexander\Bachelorarbeit\test\output_hand.acc";
  
  -- signal Definition
  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  signal in_sig: signed(word_width - 1 downto 0) := (others => '0');
  signal clk: std_logic;
  signal clr: std_logic;
  signal acc_sig: signed(word_width - 1 downto 0) := (others => '0');

begin

  accumulator_inst: entity work.accumulator
    generic map (
      word_width => word_width
    )
    port map (
      in_sig     => in_sig,
      clk        => clk,
      clr        => clr,
      acc_sig    => acc_sig
    );
  stimulus : process
    variable in_line    :   line;
    variable out_line   :   line;
    variable sig_f_file :   integer := 0;
  begin
    file_open(input_file, "C:\Users\Alexander\Bachelorarbeit\tests\input_acc_delta.txt", read_mode);
    file_open(output_file, "C:\Users\Alexander\Bachelorarbeit\tests\output_hand.acc", write_mode);
    while not endfile(input_file) loop
      readline(input_file, in_line);
      read(in_line, sig_f_file);
      in_sig <= to_signed(sig_f_file*5, word_width);
      write(out_line, to_integer(acc_sig), left, line_width);
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
    clr <= '1';
    wait for RST_HOLD_DURATION;
    wait until rising_edge(clk);
    clr <= '0';
    wait;
  end process;

end architecture;

