library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.NUMERIC_STD.all;

ENTITY peak_diskriminator is
  Generic( word_width : natural :=8
  );
  Port(
    -- input data
    signal  peak_flag   : in std_logic;
    signal  data_stream : in signed(word_width-1 downto 0);
    signal  cycle_tick  : in std_logic;
    signal  speed_tick  : in std_logic;
    
    -- control input
    signal  clk          : in std_logic;
    signal  clr          : in std_logic;
    signal  peak_threshhold : in signed(word_width-1 downto 0);
    
    -- Output
    signal  filtered_peaks   : out signed(word_width-1 downto 0);
    signal  filtered_flag   : out std_logic;
    signal  syncd_cycle_tick : out std_logic;
    signal  syncd_speed_tick : out std_logic
  );
END peak_diskriminator;

ARCHITECTURE behavioral_pd of peak_diskriminator is
  signal peak_above_threshhold : std_logic;
  signal syncd_flag: std_logic;
  signal syncd_data: signed(word_width-1 downto 0);
  signal syncd_threshhold: signed(word_width-1 downto 0);
BEGIN
  synch_p : PROCESS (clk, clr)
  BEGIN
    if clr = '1' then
      syncd_flag <= '0';
      syncd_data <= (others => '0');
      syncd_threshhold <= (others => '0');
    elsif rising_edge(clk) then
      syncd_flag <= peak_flag;
      syncd_data <= data_stream;
      syncd_threshhold <= peak_threshhold;
      syncd_cycle_tick <= cycle_tick;
      syncd_speed_tick <= speed_tick;
    end if;
  END PROCESS;
  peak_above_threshhold <= '1' when syncd_data >= syncd_threshhold else '0';
  filtered_flag <= syncd_flag AND peak_above_threshhold;
  filtered_peaks <= syncd_data;
END behavioral_pd;
