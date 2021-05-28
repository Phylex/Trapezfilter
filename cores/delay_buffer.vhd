-----------------------------------------------------------
-- Project:     Trapezoidal Filter
-- Part:        Delay buffer
-- Description: stores the incoming data in a fifo style
--              buffer that can be configured to return a
--              value at any position in the buffer
--              The information in the last buffer position
--              of the buffer is discarded
-- Author:      Alexander Becker
-- Date:        28.11.2018
-- Version:     0.1
-----------------------------------------------------------
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

ENTITY delay_buffer is
  Generic( word_width: natural;
           synth_buffer_depth: natural;
           sel_width: natural
  );
  Port(
    -- Data Input signals;
    signal data_in  : in std_logic_vector(word_width-1 downto 0);
    
    -- selection
    signal sel      : in unsigned(sel_width-1 downto 0);
    
    -- Control inputs;
    signal clk      : in std_logic;
    signal clr      : in std_logic;
    
    -- Data Output signals;
    signal data_out : out std_logic_vector(word_width-1 downto 0)
  );
END delay_buffer;

ARCHITECTURE b_dbf of delay_buffer is
  SUBTYPE word is std_logic_vector(word_width-1 downto 0);
  TYPE bfr      is ARRAY(0 to synth_buffer_depth-1) of word;
  signal dbfr   : bfr;
  signal array_sel : unsigned(sel_width-1 downto 0);
BEGIN
  delay : PROCESS (clk, clr) 
  BEGIN
    if clr = '1' then
      dbfr <= (others => word'(others => '0'));
    elsif rising_edge(clk) then
      dbfr <= data_in & dbfr(0 to synth_buffer_depth-2);
    end if;
  END PROCESS;
  array_sel <= sel - to_unsigned(1, sel_width);
  data_out <= dbfr(to_integer(array_sel)) when sel > 0 else
              data_in;
END b_dbf;