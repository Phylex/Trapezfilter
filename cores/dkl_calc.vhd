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

ENTITY dkl_calc is
  Generic(  input_word_width: natural;
            KL_PARAM_WIDTH: natural;
            DELAY_BUFFER_DEPTH: natural
  );
  Port( signal data_in: in signed(input_word_width-1 downto 0);
        signal data_out: out signed(input_word_width-1 downto 0);

        signal clk: in std_logic;
        signal rst: in std_logic;

        signal k: in unsigned(KL_PARAM_WIDTH-1 downto 0);
        signal l: in unsigned(KL_PARAM_WIDTH-1 downto 0)
  );
END dkl_calc;

ARCHITECTURE dlk_b of dkl_calc is
  -- declare components used (in this case only the subtractor)
  signal sub_1_out: signed(input_word_width-1 downto 0);
BEGIN
  subtractor_1: entity work.subtractor
    generic map (
      word_width   => input_word_width,
      buffer_depth => DELAY_BUFFER_DEPTH,
      param_width => KL_PARAM_WIDTH
    )
    port map (
      in_sig       => data_in,
      clk          => clk,
      clr          => rst,
      sel          => k,
      sub_sig      => sub_1_out
    );
  subtractor_2: entity work.subtractor
    generic map (
      word_width   => input_word_width,
      buffer_depth => DELAY_BUFFER_DEPTH,
      param_width => KL_PARAM_WIDTH
    )
    port map (
      in_sig       => sub_1_out,
      clk          => clk,
      clr          => rst,
      sel          => l,
      sub_sig      => data_out
    );
END ARCHITECTURE;
