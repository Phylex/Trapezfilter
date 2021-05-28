library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.NUMERIC_STD.all;

ENTITY peakfinder is
  Generic( word_width : natural :=8);
  Port(
    -- input data
    signal  in_signal   : in signed(word_width-1 downto 0);
    signal  in_cycle_tick : in std_logic;
    signal  in_speed_tick: in std_logic;
    
    -- control input
    signal  clk          : in std_logic;
    signal  clr          : in std_logic;
    
    -- Output
    signal  peak        : out std_logic;
    signal  syncd_sig   : out signed(word_width-1 downto 0);
    signal  syncd_cycle_tick: out std_logic;
    signal  syncd_speed_tick: out std_logic
  );
END peakfinder;

ARCHITECTURE pf of peakfinder is
  SUBTYPE tick_word is std_logic_vector(1 downto 0);
  Type tick_buf is ARRAY (0 to 1) of tick_word;
  SUBTYPE word is signed(word_width-1 downto 0);
  TYPE sig_buf is ARRAY (0 to 2) of word;
  signal    buf :   sig_buf ;
  signal    tick:   tick_buf;
BEGIN
  peakdetection : PROCESS (clk, clr)
  BEGIN
    if clr = '1' then
      buf <= (others => word'(others => '0'));
      tick <= (others => tick_word'(others => '0'));
    elsif rising_edge(clk) then
      buf <= in_signal & buf(0 to 1);
      --dbfr <= data_in & dbfr(0 to synth_buffer_depth-2);
      tick <= (in_cycle_tick & in_speed_tick) & tick(0);
    end if;
  end PROCESS;
  peak <= '1' when buf(1) > buf(0) and buf(1) >= buf(2) else '0';
  syncd_sig <= buf(1);
  syncd_cycle_tick <= tick(1)(1);
  syncd_speed_tick <= tick(1)(0);
END pf;