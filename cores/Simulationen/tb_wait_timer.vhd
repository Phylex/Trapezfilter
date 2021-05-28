library ieee;
  use ieee.std_logic_1164.all;
  use ieee.NUMERIC_STD.all;

library std;
  use std.textio.all;

entity tb_wait_timer is
end entity;

architecture rtl_sim of tb_wait_timer is

  constant timer_width: natural := 8;

  constant CLK_PERIOD: time := 8 ns;
  constant RST_HOLD_DURATION: time := 16 ns;
  signal rst: std_logic;
  signal clk: std_logic;
  signal wait_time: unsigned(timer_width - 1 downto 0);
  signal timer_reached_zero: std_logic;
  signal timer_is_zero: std_logic;

begin

  wait_timer_inst: entity work.wait_timer
    generic map (
      timer_width => timer_width
    )
    port map (
      rst         => rst,
      clk         => clk,
      wait_time   => wait_time,
      timer_reached_zero  => timer_reached_zero,
      timer_is_zero => timer_is_zero
    );

  stimuli_p: process is
  begin
    wait_time <= to_unsigned(20, timer_width);
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
    rst <= '0';
    wait for RST_HOLD_DURATION;
    wait until rising_edge(clk);
    rst <= '1';
    wait for RST_HOLD_DURATION;
    wait until rising_edge(clk);
    rst <= '0';
    wait for 10* RST_HOLD_DURATION;
    wait until rising_edge(clk);
    rst <= '1';
    wait for 2 * CLK_PERIOD;
    wait until rising_edge(clk);
    rst <= '0';
    wait;
  end process;

end architecture;