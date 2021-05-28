-----------------------------------------------------------
-- Project:     Trapezoidal Filter
-- Part:        Accumulator
-- Description: Adds the current input i to the input i-1
--              and return the result
-- Author:      Alexander Becker
-- Date:        28.11.2018
-- Version:     0.1
-----------------------------------------------------------
LIBRARY IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

ENTITY accumulator is
  Generic( word_width: natural);
  Port(
    -- Input
    signal in_sig   : in signed(word_width-1 downto 0);
    
    -- control input
    signal clk      : in std_logic;
    signal clr      : in std_logic;
    
    -- output
    signal acc_sig  : out signed(word_width-1 downto 0)
  );
END accumulator;

ARCHITECTURE b_acc of accumulator is
  -- buffer definition
  signal dlyd_sig  : signed(word_width-1 downto 0);
  
  -- bounding and adding signals
  signal add_res: signed(word_width downto 0);
  signal bound: signed(word_width-1 downto 0);
  signal syncd_in: signed(word_width-1 downto 0);
  signal bounded_acc: signed(word_width-1 downto 0);
BEGIN
   delay_and_sync: process (clk, clr) is
   begin
     if clr = '1' then
       dlyd_sig <= (others => '0');
       syncd_in <= (others => '0');
     elsif rising_edge(clk) then
       syncd_in <= in_sig;
       dlyd_sig <= bounded_acc;
     end if;
   end process;
   
   -- perform addition
   add_res <= (syncd_in(syncd_in'left) & syncd_in) + (dlyd_sig(dlyd_sig'left) & dlyd_sig);
   
   -- genererate the result in case of overflow
   bound(bound'left) <= add_res(add_res'left);
   bound(bound'left-1 downto 0) <= (others => not add_res(add_res'left));
   
   -- output the bounded addition
   bounded_acc <= add_res(add_res'left-1 downto 0) when (add_res(add_res'left) xor add_res(add_res'left-1)) = '0' else 
              to_signed(0, word_width) when clr = '1' else
              bound;
   acc_sig <= bounded_acc;
END b_acc;