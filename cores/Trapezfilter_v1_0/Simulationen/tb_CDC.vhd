library ieee;
  use ieee.std_logic_1164.all;
  use ieee.NUMERIC_STD.all;

library std;
  use std.textio.all;

library work;
  use work.filtertypes.all;

entity tb_CDC is
end entity;

architecture rtl_sim of tb_CDC is
  constant FRAME_WIDTH: natural := const_event_width;
  constant MERGED_PARAM_WIDTH: natural := MERGED_PARAM_WIDTH;
  constant FIFO_DEPTH: natural := FB_DEPTH;
  constant FIFO_COUNTER_WIDTH: natural := FB_COUNT_WIDTH;

  constant ADC_CLK_PERIOD: time := 8 ns;
  constant FPGA_CLK_PERIOD: time := 10 ns;
  signal frame: std_logic_vector(FRAME_WIDTH - 1 downto 0);
  signal fifo_wr_en: std_logic;
  signal fifo_rd_en: std_logic;
  signal fifo_full: std_logic;
  signal fifo_empty: std_logic;
  signal frame_out: std_logic_vector(FRAME_WIDTH - 1 downto 0);
  signal frame_count: std_logic_vector(FIFO_COUNTER_WIDTH - 1 downto 0);
  signal adc_clk: std_logic;
  signal fpga_clk: std_logic;
  signal rst: std_logic;
  signal merged_params: std_logic_vector(MERGED_PARAM_WIDTH - 1 downto 0);
  signal transfer_param_flag: std_logic;
  signal param_transfer_ack: std_logic;
  signal transfered_parameters: std_logic_vector(MERGED_PARAM_WIDTH - 1 downto 0);
  signal filter_reset_in: std_logic;
  signal reset_ack: std_logic;
  signal filter_reset_out: std_logic;
begin

  fifo_in_p: process is
  begin
    fifo_wr_en <= '0';
    frame <= (others => '0');
    wait until falling_edge(rst);
    wait for 400 ns;
    wait until rising_edge(adc_clk);
    frame <= (others => '1');
    fifo_wr_en <= '1';
    wait until rising_edge(adc_clk);
    fifo_wr_en <= '0';
    wait for 50 ns;
    wait until rising_edge(adc_clk);
    frame <= "101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010";
    fifo_wr_en <= '1';
    wait until rising_edge(adc_clk);
    fifo_wr_en <= '0';
    wait;
  end process;
  
  fifo_out_p: process is
  begin
    fifo_rd_en <= '0';
    wait until falling_edge(rst);
    wait for 700 ns;
    wait until rising_edge(fpga_clk);
    fifo_rd_en <= '1';
    wait until rising_edge(fpga_clk);
    fifo_rd_en <= '0';
    wait for 50 ns;
    wait until rising_edge(fpga_clk);
    fifo_rd_en <= '1';
    wait until rising_edge(fpga_clk);
    fifo_rd_en <= '0';
    wait;
  end process;
  
  transfer_params_p: process is
  begin
    merged_params <= (others => '0');
    transfer_param_flag <= '0';
    wait until falling_edge(rst);
    wait for 50 ns;
    wait until rising_edge(fpga_clk);
    merged_params <= (others => '1');
    transfer_param_flag <= '1';
    wait until rising_edge(fpga_clk);
    transfer_param_flag <= '0';
    wait;
  end process;
  
  reset_test_p: process is
  begin
    filter_reset_in <= '0';
    wait until falling_edge(rst);
    wait for 10 ns;
    wait until rising_edge(fpga_clk);
    filter_reset_in <= '1';
    wait for 100 ns;
    wait until rising_edge(fpga_clk);
    filter_reset_in <= '0';
    wait;
  end process;

  CDC_inst: entity work.CDC
    generic map (
      FRAME_WIDTH           => FRAME_WIDTH,
      MERGED_PARAM_WIDTH    => MERGED_PARAM_WIDTH,
      FIFO_DEPTH            => FIFO_DEPTH,
      FIFO_COUNTER_WIDTH    => FIFO_COUNTER_WIDTH
    )
    port map (
      frame                 => frame,
      fifo_wr_en            => fifo_wr_en,
      fifo_rd_en            => fifo_rd_en,
      fifo_full             => fifo_full,
      fifo_empty            => fifo_empty,
      frame_out             => frame_out,
      frame_count           => frame_count,
      adc_clk               => adc_clk,
      fpga_clk              => fpga_clk,
      rst                   => rst,
      merged_params         => merged_params,
      transfer_param_flag   => transfer_param_flag,
      param_transfer_ack    => param_transfer_ack,
      transfered_parameters => transfered_parameters,
      filter_reset_in       => filter_reset_in,
      reset_ack             => reset_ack,
      filter_reset_out      => filter_reset_out
    );

  fpga_clock_p: process is
  begin
    fpga_clk <= '0';
    wait for FPGA_CLK_PERIOD / 2;
    fpga_clk <= '1';
    wait for FPGA_CLK_PERIOD / 2;
  end process;
  
  adc_clock_p: process is
  begin
    adc_clk <= '0';
    wait for ADC_CLK_PERIOD/2;
    adc_clk <= '1';
    wait for ADC_CLK_PERIOD/2;
  end process;
    
  reset_p: process is
  begin
    rst <= '1';
    wait for 30 ns;
    wait until rising_edge(adc_clk);
    rst <= '0';
    wait;
  end process;
end architecture;