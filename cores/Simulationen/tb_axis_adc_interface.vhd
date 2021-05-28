library ieee;
  use ieee.std_logic_1164.all;
  use ieee.NUMERIC_STD.all;

library std;
  use std.textio.all;

entity tb_axis_adc_interface is
end entity;

architecture rtl_sim of tb_axis_adc_interface is
  constant RAW_SIGNAL_WIDTH: integer := 14;
  constant C_S_AXIS_TDATA_WIDTH: integer := 32;

  -- File input
  constant line_width: natural := 10;
  file input_file: text;

  constant CLK_PERIOD: time := 8 ns;
  signal rst: std_logic;
  signal raw_signal: std_logic_vector(RAW_SIGNAL_WIDTH - 1 downto 0);
  signal adc_sel: std_logic;
  signal S_AXIS_ACLK: std_logic;
  signal S_AXIS_ARESETN: std_logic;
  signal S_AXIS_TREADY: std_logic;
  signal S_AXIS_TDATA: std_logic_vector(C_S_AXIS_TDATA_WIDTH - 1 downto 0);
  signal S_AXIS_TSTRB: std_logic_vector((C_S_AXIS_TDATA_WIDTH / 8) - 1 downto 0);
  signal S_AXIS_TLAST: std_logic;
  signal S_AXIS_TVALID: std_logic;
begin

  stimuli_p: process is
    variable in_line    :   line;
    variable readnat : natural;
    variable readval : integer;
    variable conversion: unsigned(0 downto 0);
    variable space: character;
  begin
    S_AXIS_TVALID <= '1';
    S_AXIS_TSTRB <= (others => '1');
    S_AXIS_TLAST <= '0';
    S_AXIS_TDATA <= (others => '0');
    wait until falling_edge(rst);
    file_open(input_file, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\tests\MB_filter_signal.txt", read_mode);
    while not endfile(input_file) loop
      wait until rising_edge(S_AXIS_ACLK);
      readline(input_file, in_line);
      read(in_line, readval);
      S_AXIS_TDATA <= std_logic_vector(to_signed(readval, C_S_AXIS_TDATA_WIDTH));
    end loop;
    file_close(input_file);
    wait;
  end process;

  axis_adc_interface_inst: entity work.axis_adc_interface
    generic map (
      RAW_SIGNAL_WIDTH     => RAW_SIGNAL_WIDTH,
      C_S_AXIS_TDATA_WIDTH => C_S_AXIS_TDATA_WIDTH
    )
    port map (
      rst                  => rst,
      raw_signal           => raw_signal,
      adc_sel              => adc_sel,
      S_AXIS_ACLK          => S_AXIS_ACLK,
      S_AXIS_ARESETN       => S_AXIS_ARESETN,
      S_AXIS_TREADY        => S_AXIS_TREADY,
      S_AXIS_TDATA         => S_AXIS_TDATA,
      S_AXIS_TSTRB         => S_AXIS_TSTRB,
      S_AXIS_TLAST         => S_AXIS_TLAST,
      S_AXIS_TVALID        => S_AXIS_TVALID
    );

  clock_p: process is
  begin
    S_AXIS_ACLK <= '0';
    wait for CLK_PERIOD / 2;
    S_AXIS_ACLK <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  reset_p: process is
  begin
    S_AXIS_ARESETN <= '0';
    rst <= '1';
    wait for 200 ns;
    wait until rising_edge(S_AXIS_ACLK);
    S_AXIS_ARESETN <= '1';
    rst <= '0';
    wait;
  end process;
  
  switch_adc_p: process is
  begin
    adc_sel <= '0';
    wait until falling_edge(rst);
    wait for 500 ns;
    adc_sel <= '1';
    wait for 100 ns;
  end process;

end architecture;