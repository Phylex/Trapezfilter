library ieee;
  use ieee.std_logic_1164.all;
  use ieee.NUMERIC_STD.all;

library std;
  use std.textio.all;

entity tb_filter_control is
end entity;

architecture rtl_sim of tb_filter_control is
  constant FILTER_STATE_WIDTH: natural := 3;

  constant CLK_PERIOD: time := 8 ns;
  constant RST_PERIOD: time := 80 ns;
  signal clk: std_logic;
  signal rst: std_logic;
  signal fifo_empty: std_logic;
  signal fifo_full: std_logic;
  signal fifo_rst_busy: std_logic;
  signal ps_filter_reset: std_logic;
  signal param_valid: std_logic;
  signal param_updated: std_logic;
  signal transfer_params: std_logic := '0';
  signal transfer_ack: std_logic;
  signal filter_reset: std_logic;
  signal filter_reset_ack: std_logic;
  signal filter_state_out: std_logic_vector(FILTER_STATE_WIDTH-1 downto 0);
begin

  fifo_rst_busy_p: process is
  begin
    fifo_rst_busy <= '1';
    wait until falling_edge(rst);
    wait for 15*CLK_PERIOD;
    wait until rising_edge(clk);
    fifo_rst_busy <= '0';
    wait until rising_edge(rst);
  end process;
  
  fifo_empty_full_p: process is
    variable frame_cnt: natural;
  begin
    if fifo_rst_busy = '1' then
      fifo_empty <= '1';
      fifo_full <= '0';
    else
      if filter_reset = '0' then
        wait for 100 ns;
        wait until rising_edge(clk);
        frame_cnt := frame_cnt + 1;
        if frame_cnt = 20 then
          frame_cnt := frame_cnt -1;
        end if;
      elsif filter_reset = '1' then
        wait for 20 ns;
        wait until rising_edge(clk);
        if frame_cnt > 0 then
          frame_cnt := frame_cnt - 1;
        end if;
      end if;
      if frame_cnt > 0 then
        fifo_empty <= '0';
      else
        fifo_empty <= '1';
      end if;
    end if;
    wait for 1 ns;
  end process;

  param_valid_p: process is
  begin
    param_valid <= '0';
    wait until falling_edge(rst);
    wait for 20 ns;
    wait until rising_edge(clk);
    param_valid <= '1';
    wait until rising_edge(rst);
  end process;

  param_updated_p: process is
  begin
    param_updated <= '0';
    wait until rising_edge(param_valid);
    wait for 500 ns;
    wait until rising_edge(clk);
    param_updated <= '1';
    wait until rising_edge(clk);
    param_updated <= '0';
    wait until rising_edge(rst);
  end process;
  
  transfer_ack_p: process is
  begin
    transfer_ack <= '0';
    wait until falling_edge(transfer_params);
    wait for 30 ns;
    wait until rising_edge(clk);
    transfer_ack <= '1';
    wait for 20 ns;
    wait until rising_edge(clk);
    transfer_ack <= '0';
  end process;

  ps_filter_reset_p: process is
  begin
    ps_filter_reset <= '0';
    wait until falling_edge(filter_reset);
    wait for 1000 ns;
    wait until rising_edge(clk);
    ps_filter_reset <= '1';
    wait for 1000 ns;
    wait until rising_edge(clk);
    ps_filter_reset <= '0';
    wait;
  end process;
  
  filter_reset_ack_p: process is
  begin 
    filter_reset_ack <= '1';
    wait until falling_edge(filter_reset);
    wait for 30 ns;
    wait until rising_edge(clk);
    filter_reset_ack <= '0';
    wait until rising_edge(filter_reset);
    wait for 30 ns;
    wait until rising_edge(clk);
  end process;
  filter_control_inst: entity work.filter_control
    generic map (
      FILTER_STATE_WIDTH => FILTER_STATE_WIDTH
    )
    port map (
      clk                => clk,
      rst                => rst,
      fifo_empty         => fifo_empty,
      fifo_full          => fifo_full,
      fifo_rst_busy      => fifo_rst_busy,
      ps_filter_reset    => ps_filter_reset,
      param_valid        => param_valid,
      param_updated      => param_updated,
      transfer_params    => transfer_params,
      transfer_ack       => transfer_ack,
      filter_reset       => filter_reset,
      filter_reset_ack   => filter_reset_ack,
      filter_state_out   => filter_state_out
    );

  clock_p: process is
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  rst_p: process is
  begin
    rst <= '1';
    wait for RST_PERIOD;
    rst <= '0';
    wait;
  end process;

end architecture;