library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.NUMERIC_STD.all;
  use IEEE.std_logic_misc.all;

ENTITY wait_timer is
  Generic( timer_width: natural := 8);
  Port(
    -- control input
    signal rst : in std_logic;
    signal clk : in std_logic;
    signal wait_time : in unsigned(timer_width-1 downto 0);
    
    -- output
    signal timer_reached_zero : out std_logic;
    signal timer_is_zero : out std_logic
  );
END wait_timer;

ARCHITECTURE wt of wait_timer is
  signal timer_val: unsigned(timer_width-1 downto 0);
BEGIN
  waitp : PROCESS (clk, rst)
    variable zero_flag : std_logic := '0';
    variable last_zf : std_logic := '0';
  BEGIN
    -- load the value into the timer at reset
    if rst = '1' then
      zero_flag := nor_reduce(std_logic_vector(wait_time));
      timer_val <= wait_time;
      timer_reached_zero <= '0';
      timer_is_zero <= zero_flag;
      last_zf := '0';
      -- possibly add last_zf and zf = 1
    -- for every clock cycle decrement the timer value and update the state variable
    -- accordingly, triggering the timer zero flag as soon as the timer reaches zero
    elsif rising_edge(clk) then
      last_zf := zero_flag;
      zero_flag := nor_reduce(std_logic_vector(timer_val));
      if zero_flag = '0'then
        timer_val <= timer_val - to_unsigned(1, timer_width);
      elsif (zero_flag and (zero_flag xor last_zf)) = '1' then
        timer_reached_zero <= '1';
      else
        timer_reached_zero <= '0';
      end if;
      timer_is_zero <= zero_flag;
    end if;
  END PROCESS;
END wt;