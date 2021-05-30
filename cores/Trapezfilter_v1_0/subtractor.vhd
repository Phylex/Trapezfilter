-----------------------------------------------------------
-- Project:     Trapezoidal Filter
-- Part:        Accumulator
-- Description: Adds the current input i to the input i-1
--              and return the result
-- Author:      Alexander Becker
-- Date:        28.11.2018
-- Version:     0.7
-----------------------------------------------------------
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity subtractor is
  generic( word_width: natural;
           buffer_depth: natural;
           PARAM_WIDTH: natural
  );
  port(
    -- Input
    signal in_sig   : in signed(word_width-1 downto 0);

    -- control input
    signal clk      : in std_logic;
    signal clr      : in std_logic;
    signal sel      : in unsigned(PARAM_WIDTH-1 downto 0); 

    -- output
    signal sub_sig  : out signed(word_width-1 downto 0)
  );
end subtractor;

architecture bsub of subtractor is
  --internal signals
  signal dlyd_word: std_logic_vector(word_width-1 downto 0);
  signal dlyd_sig: signed(word_width-1 downto 0) := (others => '0');
  signal sub_res: signed(word_width downto 0) := (others => '0'); 
  signal min_max: signed(word_width-1 downto 0) := (others => '0');
  signal syncd_in: signed(word_width-1 downto 0) := (others => '0');
BEGIN
  dly_buffer:   entity work.delay_buffer 
    generic map( word_width => word_width,
                 synth_buffer_depth => buffer_depth,
                 sel_width => PARAM_WIDTH
    )
    port map ( data_in => std_logic_vector(syncd_in),
               sel     => sel,
               clr     => clr,
               clk     => clk,
               data_out => dlyd_word
    );
  dlyd_sig <= signed(dlyd_word);
  sync_in: process(clr, clk) is
  begin
    if clr = '1' then
      syncd_in <= (others => '0');
    elsif rising_edge(clk) then
      syncd_in <= in_sig;
    end if;
  end process;
  min_max(min_max'left) <= sub_res(sub_res'left);
  minmaxgen: for i in min_max'length-2 downto 0 generate
    min_max(i) <= NOT sub_res(sub_res'left);
  end generate;
  sub_res <= (syncd_in(syncd_in'left) & syncd_in) - (dlyd_sig(dlyd_sig'left) & dlyd_sig);
  sub_sig <= sub_res(sub_res'left-1 downto 0) when (sub_res(sub_res'left) XOR sub_res(sub_res'left-1)) = '0' else 
             to_signed(0, word_width) when clr = '1' else
             min_max;
END architecture;