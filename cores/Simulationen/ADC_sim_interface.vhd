library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use IEEE.std_logic_misc.or_reduce;
  use IEEE.std_logic_misc.and_reduce;
library unisim;
  use unisim.vcomponents.all;

entity ADC_sim_interface is
  generic(
    adc_data_width : natural;
    downsample_width :natural
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
  signal clk_cnt : unsigned(downsample_width-1 downto 0) := (others => '0');
  signal downsampled_clk: std_logic := '0';
  signal int_clk0 : std_logic := '0';
  signal int_clk : std_logic := '0';
  signal reset_acc: std_logic := '0';
  signal int_adc_dat_a: signed(adc_data_width-1 downto 0)  := (others => '0');
  signal int_adc_dat_b: signed(adc_data_width-1 downto 0)  := (others => '0');
  signal raw_adc_dat_a: std_logic_vector(adc_data_width-1 downto 0)  := (others => '0');
  signal raw_adc_dat_b: std_logic_vector(adc_data_width-1 downto 0)  := (others => '0');
  signal adc_a_acc: signed(adc_data_width+downsample_width-1 downto 0)  := (others => '0');
  signal adc_b_acc: signed(adc_data_width+downsample_width-1 downto 0)  := (others => '0');
  signal adc_out_a: std_logic_vector(adc_data_width-1 downto 0)  := (others => '0');
  signal acc_mask: signed(adc_data_width+downsample_width-1 downto 0) := (others => '0');
  signal adc_out_b: std_logic_vector(adc_data_width-1 downto 0)  := (others => '0');
  signal syncd_sel : std_logic := '0';

begin
  adc_clk_in: IBUFDS
    port map (
      I => adc_clk_a,
      IB => adc_clk_b,
      O => int_clk0
    );
  adc_secondary_buffer: BUFG
    port map (
      I => int_clk0,
      O => int_clk
    );
  
  data_sync_in: process (int_clk)
  begin
    if rising_edge(int_clk) then
      clk_cnt <= clk_cnt + 1;
      if rst = '0' then
        syncd_sel <= adc_sel;
        raw_adc_dat_a <= adc_data_a;
        raw_adc_dat_b <= adc_data_b;
        int_adc_dat_a <= signed(raw_adc_dat_a);
        int_adc_dat_b <= signed(raw_adc_dat_b);
        adc_a_acc <= (adc_a_acc and acc_mask) + int_adc_dat_a;
        adc_b_acc <= (adc_b_acc and acc_mask) + int_adc_dat_b;
      end if;
    end if;
  end process;

  reset_acc <= clk_cnt(downsample_width-1) and not or_reduce(std_logic_vector(clk_cnt(downsample_width-2 downto 0)));
  acc_mask <= (others => not reset_acc);


  average_adc_signals: process(int_clk, downsampled_clk)
  begin
    if rising_edge(downsampled_clk) then
        adc_out_a <= std_logic_vector(adc_a_acc(adc_data_width+downsample_width-1 downto downsample_width));
        adc_out_b <= std_logic_vector(adc_b_acc(adc_data_width+downsample_width-1 downto downsample_width));
    end if;
  end process;


  adc_data <= (others => '0') when rst = '1' else
              adc_out_a when (syncd_sel = '0' and rst = '0') else
              adc_out_b when (syncd_sel = '1' and rst = '0');
  downsampled_clk <= clk_cnt(downsample_width-1);
  clk <= downsampled_clk;
  adc_csn <= '1';
end architecture;
