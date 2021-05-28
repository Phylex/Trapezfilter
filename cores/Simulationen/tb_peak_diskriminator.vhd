library ieee;
  use ieee.std_logic_1164.all;
  use ieee.NUMERIC_STD.all;

library std;
  use std.textio.all;

entity tb_peak_diskriminator is
end entity;

architecture rtl_sim of tb_peak_diskriminator is
  -- Constants for the generics
  constant word_width: natural := 8;
  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  
  -- inputs
  signal peak_flag: std_logic;
  signal data_stream: signed(word_width - 1 downto 0);
  
  -- control inputs
  signal clk: std_logic;
  signal clr: std_logic;
  signal peak_threshhold: signed(word_width - 1 downto 0);
  
  -- Outputs
  signal filtered_peaks: signed(word_width - 1 downto 0);
  signal filtered_flag: std_logic;
  
   -- Files
  constant line_width: natural := 4;
  file input_file: text; -- open READ_MODE is "C:\Users\Alexander\Bachelorarbeit\test\input_hand.acc";
  file output_file: text; -- open WRITE_MODE is "C:\Users\Alexander\Bachelorarbeit\test\output_hand.acc";

begin

  peak_diskriminator_inst: entity work.peak_diskriminator
    generic map (
      word_width      => word_width
    )
    port map (
      peak_flag       => peak_flag,
      data_stream     => data_stream,
      clk             => clk,
      clr             => clr,
      peak_threshhold => peak_threshhold,
      filtered_peaks  => filtered_peaks,
      filtered_flag   => filtered_flag
    );
  
  stimulus : process
    variable in_line    :   line;
    variable out_line   :   line;
    variable data_f_file :   integer := 0;
    variable flag_f_file :  integer;
    variable space      :   character;
  begin
    file_open(input_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\tests\peak_discriminator_test.dat", read_mode);
    --file_open(output_file, "C:\Users\Alexander\Bachelorarbeit\cores\rtl\Peak-Detector\peak_diskriminator_test_out.txt", write_mode);
    peak_threshhold <= to_signed(100,8);
    -- for all other lines read in the peak value and the peak-detector flag.
    -- Both values are contained on one line seperated by a single whitespace char
    while not endfile(input_file) loop
      readline(input_file, in_line);
      read(in_line, data_f_file);
      wait until rising_edge(clk);
      data_stream <= to_signed(data_f_file, word_width);
      read(in_line, space);
      read(in_line, flag_f_file);
      if flag_f_file = 1 then
        peak_flag <= '1';
      else 
        peak_flag <= '0';
      end if;
      -- for every input line that raises the filtered_peak flag we write the peak value into the file
      --if filtered_flag = '1' then
      --  write(out_line, to_integer(filtered_peaks), left, line_width);
      --else
      --  write(out_line, to_integer('0'), left, line_width);
      --end if;
      --writeline(output_file, out_line);
    end loop;
    file_close(input_file);
    --file_close(output_file);
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

