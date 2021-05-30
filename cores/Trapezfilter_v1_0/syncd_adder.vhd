-----------------------------------------------------------
-- Project:     Trapezoidal Filter
-- Part:        Synchronized Adder
-- Description: Adds two inputs together that are synchronized to a clock
-- Author:      Alexander Becker
-- Date:        14.12.2018
-- Version:     0.1
-----------------------------------------------------------
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity syncd_adder is
  generic(
    in1_width: natural;
    in2_width: natural
  );
  port(
    -- Input
    signal in_1   : in signed(in1_width-1 downto 0);
    signal in_2   : in signed(in2_width-1 downto 0);
    
    -- control input
    signal clk      : in std_logic;
    signal rst      : in std_logic;

    -- output
    signal add_out : out signed(in1_width downto 0)
  );
end syncd_adder;

ARCHITECTURE dfb_addr of syncd_adder is
  signal syncd_in_1: signed(in1_width-1 downto 0);
  signal syncd_in_2: signed(in2_width-1 downto 0);
  signal add_1: signed(in1_width downto 0);
  signal add_2: signed(in1_width downto 0);
begin
  sync_p: process(rst, clk) is
  begin
    if rst = '1' then
      syncd_in_1 <= (others => '0');
      syncd_in_2 <= (others => '0');
    elsif rising_edge(clk) then
      syncd_in_1 <= in_1;
      syncd_in_2 <= in_2;
    end if;
  end process;
  add_1 <= resize(syncd_in_1, in1_width+1);
  add_2 <=  resize(syncd_in_2, in1_width+1);
  add_out <= add_1 + add_2;
end dfb_addr;