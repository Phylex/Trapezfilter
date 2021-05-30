library ieee;
  use ieee.std_logic_1164.all;
  use ieee.NUMERIC_STD.all;

library std;
  use std.textio.all;

entity tb_max_shift_array is
end entity;

architecture rtl_sim of tb_max_shift_array is

  constant packet_width: natural := 8;
  constant buffer_depth: natural := 10;
  constant eval_max_left: natural := 7;
  constant eval_max_right: natural := 4;

  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  
  -- control inputs
  signal rst: std_logic;
  signal shift: std_logic;
  
  -- packet input
  signal packet_in: std_logic_vector(packet_width - 1 downto 0);
  
  -- packet output
  signal max_packet: std_logic_vector(packet_width - 1 downto 0);
  
  -- input and output files
  constant line_width: natural := 10;
  file input_file: text;
  file output_file: text;

begin

  max_shift_array_inst: entity work.max_shift_array
    generic map (
      packet_width   => packet_width,
      buffer_depth   => buffer_depth,
      eval_max_left  => eval_max_left,
      eval_max_right => eval_max_right
    )
    port map (
      rst            => rst,
      shift          => shift,
      packet_in      => packet_in,
      max_packet     => max_packet
    );

  -- set parameters for the test
  --packet_in <= std_logic_vector(to_signed(5, packet_width));
  stimuli_p: process is
    variable in_line : line;
    variable out_line : line;
    variable packet_val : integer := 0;
  begin
    wait for CLK_PERIOD / 2;
    file_open(input_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\tests\max_shift_test.dat", read_mode);
    file_open(output_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\vhdl_testresults\max_shift_testresult.dat", write_mode);
    while not endfile(input_file) loop
      readline(input_file, in_line);
      read(in_line, packet_val);
      wait until rising_edge(shift);
      packet_in <= std_logic_vector(to_signed(packet_val, packet_width));
      write(out_line, to_integer(signed(max_packet)));
      writeline(output_file, out_line);
    end loop;
    file_close(input_file);
    file_close(output_file);
  end process;

  clock_p: process is
  begin
    shift <= '1';
    wait for CLK_PERIOD / 2;
    shift <= '0';
    wait for CLK_PERIOD / 2;
  end process;

  reset_p: process is
  begin
    rst <= '1';
    wait for RST_HOLD_DURATION;
    wait until rising_edge(shift);
    rst <= '0';
    wait for 244 ns;
  end process;

end architecture;

