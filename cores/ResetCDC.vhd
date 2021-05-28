library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity ResetCDC is
  port (
    FPGA_clk: in  std_logic;
    ADC_clk: in std_logic;
    rst_in: in  std_logic;
    rst_out: out std_logic;
    ack_out: out std_logic
  );
end entity;

architecture rtl of ResetCDC is
  signal rst_filter_1: std_logic;
  signal rst_filter_2: std_logic;
  signal rst_filter_out: std_logic;
  signal ack_1: std_logic;
  signal ack_2: std_logic;
begin
  rst_filter_synq_p: process ( ADC_clk ) is
  begin
    if rising_edge(ADC_clk) then
      rst_filter_1 <= rst_in;
      rst_filter_2 <= rst_filter_1;
      rst_filter_out <= rst_filter_2;
    end if;
  end process;
  rst_out <= rst_filter_out;
  
  ack_synq_p: process ( FPGA_clk ) is
  begin 
    if rising_edge(FPGA_clk) then
      ack_1 <= rst_filter_out;
      ack_2 <= ack_1;
      ack_out <= ack_2;
    end if;
  end process;
end architecture;