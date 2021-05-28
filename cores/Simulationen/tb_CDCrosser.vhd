library ieee;
  use ieee.std_logic_1164.all;
  use ieee.NUMERIC_STD.all;

library std;
  use std.textio.all;

entity tb_CDCrosser is
end entity;

architecture rtl_sim of tb_CDCrosser is
  constant DATA_WIDTH: natural := 10;

  constant SENDER_CLK_PERIOD: time := 8 ns;
  constant RECIEVER_CLK_PERIOD: time := 5 ns;
  signal sender_clk: std_logic;
  signal din: std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal rst: std_logic;
  signal valid_strobe: std_logic;
  signal transfered: std_logic;
  signal reciever_clk: std_logic;
  signal dout: std_logic_vector(DATA_WIDTH - 1 downto 0);
begin

  stimuli_p: process is
  begin
    rst <= '1';
    din <= (others => '0');
    valid_strobe <= '0';
    wait for 10 ns;
    rst <= '0';
    wait for 20 ns;
    wait until rising_edge( sender_clk );
    din <= (others => '1');
    valid_strobe <= '1';
    wait until rising_edge( sender_clk );
    valid_strobe <= '0';
    wait until rising_edge( transfered );
    wait for 100 ns;
    wait until rising_edge( sender_clk );
    din <= "1010101010";
    valid_strobe <= '1';
    wait until rising_edge( sender_clk );
    valid_strobe <= '0';
    wait;
  end process;

  CDCrosser_inst: entity work.CDCrosser
    generic map (
      DATA_WIDTH   => DATA_WIDTH
    )
    port map (
      rst          => rst,
      sender_clk   => sender_clk,
      din          => din,
      valid_strobe => valid_strobe,
      transfered   => transfered,
      reciever_clk => reciever_clk,
      dout         => dout
    );

  sender_clock_p: process is
  begin
    sender_clk <= '0';
    wait for SENDER_CLK_PERIOD / 2;
    sender_clk <= '1';
    wait for SENDER_CLK_PERIOD / 2;
  end process;
  
  reciever_clock_p: process is
  begin
    reciever_clk <= '0';
    wait for RECIEVER_CLK_PERIOD / 2;
    reciever_clk <= '1';
    wait for RECIEVER_CLK_PERIOD / 2;
  end process;


end architecture;