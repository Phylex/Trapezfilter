-----------------------------------------------------------
-- Project:     Trapezoidal Filter
-- Part:        Synchronized multiplier
-- Description: Multiplies two inputs together that are synchronized to a clock
-- Author:      Alexander Becker
-- Date:        14.12.2018
-- Version:     0.1
-----------------------------------------------------------
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity syncd_mul is
  generic( in_1_word_width: natural;
           in_2_word_width: natural);
  port(
    signal in_1: in signed(in_1_word_width-1 downto 0);
    signal in_2: in signed(in_2_word_width-1 downto 0);
    
    signal clk: in std_logic;
    signal rst: in std_logic;
    
    signal mul_out: out signed(in_1_word_width+in_2_word_width-1 downto 0)
  );
end syncd_mul;

architecture df_mul of syncd_mul is
  signal syncd_in_1: signed(in_1_word_width-1 downto 0);
  signal syncd_in_2: signed(in_2_word_width-1 downto 0);
begin
  sync_p: process (rst, clk) is
  begin
    if rst = '1' then
      syncd_in_1 <= (others => '0');
      syncd_in_2 <= (others => '0');
    elsif rising_edge(clk) then
      syncd_in_1 <= in_1;
      syncd_in_2 <= in_2;
    end if;
  end process;
  
  mul_out <= syncd_in_1 * syncd_in_2;
end df_mul;