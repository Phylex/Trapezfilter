library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;


entity ADC_sim_interface is
  generic(
    adc_data_width : natural
  );
  port (
    clk: out  std_logic;
    rst: in  std_logic;
    adc_sel: in std_logic;
    adc_csn: out std_logic;
    adc_clk_a : in std_logic;
    adc_clk_b : in std_logic;
    adc_data_a: in std_logic_vector(adc_data_width-1 downto 0);
    adc_data_b: in std_logic_vector(adc_data_width-1 downto 0);
    adc_data : out std_logic_vector(adc_data_width-1 downto 0)
  );
end entity;

architecture rtl of ADC_sim_interface is
  signal int_clk0 : std_logic := '0';
  signal int_clk : std_logic := '0';
  signal int_adc_dat_a: std_logic_vector(adc_data_width-1 downto 0)  := (others => '0');
  signal int_adc_dat_b: std_logic_vector(adc_data_width-1 downto 0)  := (others => '0');
  signal raw_adc_dat_a: std_logic_vector(adc_data_width-1 downto 0)  := (others => '0');
  signal raw_adc_dat_b: std_logic_vector(adc_data_width-1 downto 0)  := (others => '0');
  signal syncd_sel : std_logic := '0';
begin
  int_clk <= adc_clk_a;
  data_sync_in: process (int_clk)
  begin
    if rising_edge(int_clk) then
	  if rst = '0' then
        syncd_sel <= adc_sel;
        raw_adc_dat_a <= adc_data_a;
	    raw_adc_dat_b <= adc_data_b;
	    int_adc_dat_a <= raw_adc_dat_a;
	    int_adc_dat_b <= raw_adc_dat_b;
	  end if;
    end if;
  end process;
  adc_data <= (others => '0') when rst = '1' else
              int_adc_dat_a when (syncd_sel = '0' and rst = '0') else
			  int_adc_dat_b when (syncd_sel = '1' and rst = '0');
  clk <= int_clk;
  adc_csn <= '1';
end architecture;