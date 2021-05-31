-----------------------------------------------------------
-- Project:     Trapezoidal Filter
-- Part:        Event assembly
-- Description: The Event assembly combines the mitainformation
--              from the two digital signals and the trapezoidal
--              filter into an event. The event is the data unit
--              that is processed by the linux and every PL part
--              from here on out.
-- Author:      Alexander Becker
-- Date:        11.03.2019
-- Version:     0.3
-----------------------------------------------------------
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity event_assembly is
  generic(  signal_word_width: natural;
            speed_tick_counter_width: natural;
            cycle_tick_counter_width: natural;
            timestamp_word_width: natural
          );
  port( signal signal_in: in signed(signal_word_width-1 downto 0);
        signal peak_in: in std_logic;
        signal cycle_tick: in std_logic;
        signal speed_tick: in std_logic;
        
        -- signal output
        signal event_out: out std_logic_vector(signal_word_width+speed_tick_counter_width+cycle_tick_counter_width+timestamp_word_width-1 downto 0);
        signal event_ind: out std_logic;

        -- control input
        signal clk: in std_logic;
        signal rst: in std_logic
      );
end event_assembly;

Architecture event_assembly_arch of event_assembly is
  signal timer_val: unsigned(timestamp_word_width-1 downto 0);
  signal cycle_counter: unsigned(cycle_tick_counter_width-1 downto 0);
  signal speed_counter: unsigned(speed_tick_counter_width-1 downto 0);
  signal internal_event_ind: std_logic;
BEGIN
  timer_p: process(rst, clk) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        timer_val <= to_unsigned(0, timestamp_word_width);
      else
        timer_val <= timer_val + to_unsigned(1, timestamp_word_width);
      end if;
    end if;
  end process;
  
  cycle_and_speed_tick_p: process ( clk ) is
    variable cycle_counter_set: std_logic;
    variable speed_ind_set: std_logic;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cycle_counter <= to_unsigned(0, cycle_tick_counter_width);
        speed_counter <= to_unsigned(0, speed_tick_counter_width);
      else
        if cycle_tick = '1' and cycle_counter_set = '0' then
          cycle_counter <= cycle_counter + to_unsigned(1, cycle_tick_counter_width);
          speed_counter <= (others => '0');
          cycle_counter_set := '1';
        elsif cycle_tick = '0' and cycle_counter_set = '1' then
          cycle_counter_set := '0';
        end if;
        if speed_tick = '1' and speed_ind_set = '0' then
          speed_counter <= speed_counter + to_unsigned(1, speed_tick_counter_width);
          speed_ind_set := '1';
        elsif speed_tick = '0' and speed_ind_set = '1' then
          speed_ind_set := '0';
        end if;
      end if;
    end if;
  end process;
  
  event_p: process ( clk ) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        internal_event_ind <= '0';
        event_out <= (others => '0');
      elsif peak_in = '1' then
        event_out <= std_logic_vector(signal_in) & std_logic_vector(speed_counter) & std_logic_vector(cycle_counter) & std_logic_vector(timer_val);
        internal_event_ind <= '1';
      elsif internal_event_ind = '1' then
        internal_event_ind <= '0';
      end if;
    end if;
  end process;
  event_ind <= internal_event_ind;
END event_assembly_arch;
