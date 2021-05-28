library ieee;
  use ieee.NUMERIC_STD.all;
  use ieee.std_logic_1164.all;

library std;
  use std.textio.all;

entity tb_delay_buffer is
end entity;

architecture rtl_sim of tb_delay_buffer is
  COMPONENT delay_buffer is
    Generic( word_width : natural;
             synth_buffer_depth: natural
    );
    Port(
        -- Data Input signals;
        signal data_in  : in std_logic_vector(word_width-1 downto 0);
        
        -- selection
        signal sel      : in integer range 0 to synth_buffer_depth-1;
        
        -- Control inputs;
        signal clk      : in std_logic;
        signal clr      : in std_logic;
        
        -- Data Output signals;
        signal data_out : out std_logic_vector(word_width-1 downto 0)
    );
  END COMPONENT;

  -- Generics definition
  constant word_width: natural := 1;
  constant synth_buffer_depth: natural := 20;

  -- Timing Constants
  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  
  -- Input files
  file input_file: text;
  -- Signals
  signal data_in: std_logic_vector(word_width - 1 downto 0);
  signal sel: integer range 0 to synth_buffer_depth - 1;
  signal clk: std_logic;
  signal clr: std_logic;
  signal data_out: std_logic_vector(word_width-1 downto 0);

begin

  delay_buffer_inst: delay_buffer
    generic map (
      word_width         => word_width,
      synth_buffer_depth => synth_buffer_depth
    )
    port map (
      data_in            => data_in,
      sel                => sel,
      clk                => clk,
      clr                => clr,
      data_out           => data_out
    );

  stimulus_p : process
    variable in_line    :   line;
    variable data_val   :   natural := 0;
    variable sel_in     :   integer := 0;
    variable space      :   character;
  begin
    file_open(input_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\tests\one_bit_delay_buffer.dat", read_mode);
    wait for CLK_PERIOD/2;
    while not endfile(input_file) loop
      readline(input_file, in_line);
      read(in_line, data_val);
      --read(in_line, space);
      --read(in_line, sel_in);
      wait until rising_edge(clk);
      data_in <= std_logic_vector(to_unsigned(data_val, word_width));
      sel     <= 5;   
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
    clr <= '1';
    wait for RST_HOLD_DURATION/4;
    wait until rising_edge(clk);
    clr <= '0';
    wait;
  end process;

end architecture;

