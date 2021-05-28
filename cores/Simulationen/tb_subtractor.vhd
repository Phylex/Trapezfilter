library ieee;
  use ieee.NUMERIC_STD.all;
  use ieee.std_logic_1164.all;

library std;
  use std.textio.all;

entity tb_subtractor is
end entity;

architecture rtl_sim of tb_subtractor is

  constant word_width: natural := 14;
  constant buffer_depth: natural := 20;
  
  -- declare subtractor
  component subtractor is
    generic( word_width: natural;
              buffer_depth: natural
         );
    port(
        -- Input
        signal in_sig   : in signed(word_width-1 downto 0);

        -- control input
        signal clk      : in std_logic;
        signal clr      : in std_logic;
        signal sel      : in natural range 0 to buffer_depth; 

        -- output
        signal sub_sig  : out signed(word_width-1 downto 0)
    );
  end component;
  -- Files
  
  constant line_width: natural := 4;
  file input_file: text; -- open READ_MODE is "C:\Users\Alexander\Bachelorarbeit\test\input_acc.dat";
  file output_file: text; -- open WRITE_MODE is "C:\Users\Alexander\Bachelorarbeit\test\output_acc.dat";


  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  signal in_sig: signed(word_width - 1 downto 0);
  signal clk: std_logic;
  signal clr: std_logic;
  signal sel: natural range 0 to buffer_depth := 1;
  signal sub_sig: signed(word_width - 1 downto 0);

begin

  subtractor_inst: entity work.subtractor
    generic map (
      word_width   => word_width,
      buffer_depth => buffer_depth
    )
    port map (
      in_sig       => in_sig,
      clk          => clk,
      clr          => clr,
      sel          => sel,
      sub_sig      => sub_sig
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
      wait until rising_edge(clk);
      in_sig <= to_signed(sig_f_file, word_width);
      write(out_line, to_integer(sub_sig), left, line_width);
      writeline(output_file, out_line);
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
    wait for CLK_PERIOD;
    --wait until rising_edge(clk);
    clr <= '0';
    wait;
  end process;

end architecture;

