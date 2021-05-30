-----------------------------------------------------------
-- Project:     Trapezoidal Filter
-- Part:        Entire Filter
-- Description: Adds the current input i to the input i-1
--              and return the result
-- Author:      Alexander Becker
-- Date:        28.11.2018
-- Version:     0.4
-----------------------------------------------------------
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library work;
  use work.filtertypes.all;

ENTITY trapezoidal_filter is
  -- parameters
  Generic(  word_width: natural;
            buffer_length: natural;
            max_multiplier_word_width: natural;
            param_width: natural;
          );
  Port   (  -- parameters from software
            signal k: in unsigned(param_width-1 downto 0);
            signal l: in unsigned(param_width-1 downto 0);
            signal m: in signed(max_multiplier_word_width-1 downto 0);

            -- signal in
            signal data_in: in signed(word_width-1 downto 0);
            signal cycle_tick: in std_logic;
            signal speed_tick: in std_logic;

            -- signal out
            signal data_out: out signed(word_width + max_multiplier_word_width + accum_2_ext - 1 downto 0);
            signal syncd_cycle_tick: out std_logic;
            signal syncd_speed_tick: out std_logic;

            -- control inputs
            signal clk: in std_logic;
            signal clr: in std_logic
          );
END trapezoidal_filter;

ARCHITECTURE btf of trapezoidal_filter is
  -- imtermediate Signals
  subtype acc1_t is signed(word_width + param_width - 1 downto 0);
  subtype acc2_t is signed(word_width + max_multiplier_word_width + accum_2_ext - 1 downto 0);
  subtype add_out_t is signed(word_width + max_multiplier_word_width downto 0);
  subtype mul_t is signed(word_width + max_multiplier_word_width - 1 downto 0);

  signal akl:           signed(word_width-1 downto 0);
  signal resized_akl:   acc1_t;
  signal b:             acc1_t;
  signal mul_res:       mul_t;
  signal resized_c:     acc2_t;
  signal c:             add_out_t;
  signal ticks:         std_logic_vector(1 downto 0);
  signal dlyd_ticks:    std_logic_vector(1 downto 0);
BEGIN
  dkl_calc_inst: entity work.dkl_calc
    generic map (
      input_word_width => word_width,
      DELAY_BUFFER_DEPTH => buffer_length,
      KL_PARAM_WIDTH => param_width
    )
    port map (
      data_in          => data_in,
      data_out         => akl,
      clk              => clk,
      rst              => clr,
      k                => k,
      l                => l
    );

  multiplier: entity work.syncd_mul
    generic map (
      -- careful, the wider of both operands has to be input to in_1
      in_1_word_width => word_width,
      in_2_word_width => max_multiplier_word_width
    )
    port map (
      in_1            => akl,
      in_2            => m,
      clk             => clk,
      rst             => clr,
      mul_out         => mul_res
    );
  
  -- resize so we don't get an overflow
  resized_akl <=  resize(akl, acc1_t'length);
  accumulator_1: entity work.accumulator 
    generic map (word_width => acc1_t'length) 
    port map(
      in_sig        => resized_akl,
      clk           => clk,
      clr           => clr,
      acc_sig       => b
    );
  
  -- resize the output of the accumulator so it can be entered into the adder
  adder: entity work.syncd_adder
    generic map (
      in1_width => acc1_t'length
      in2_width => mul_t'length,
    )
    port map (
      in_1       => b,
      in_2       => mul_res,
      clk        => clk,
      rst        => clr,
      add_out    => c
    );
  resized_c <= resize(c, acc2_t'length);
  accumulator_2: entity work.accumulator 
    generic map (word_width => acc2_t'length) 
    port map (
      in_sig => resized_c,
      clk => clk,
      clr => clr,
      acc_sig => data_out
  );

  -- we now have to synchronize the signals from the driver control unit with the
  -- signal from the ADC as it is delayed through the registers in the different
  -- stages of the signal processing so that they stay synchronous.
  -- first combine both signals into a single single
  ticks <= cycle_tick & speed_tick;
  
  --delay the signal as it would be delayed through the dkl calculation
  dkl_control_signal_delay: entity work.delay_buffer
    generic map (
      word_width => 2,
      synth_buffer_depth => 5,
      sel_width => 3
    )
    port map (data_in => ticks,
              data_out => dlyd_ticks,
              clk =>clk,
              clr => clr,
              sel => to_unsigned(5, 3)
            );
  
  -- split the combined delayed tick signals and output
  syncd_speed_tick <= dlyd_ticks(dlyd_ticks'right);
  syncd_cycle_tick <= dlyd_ticks(dlyd_ticks'left);
END;
