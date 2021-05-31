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
  signal timer_zero: std_logic;
  signal last_timer: std_logic;
BEGIN

  timer_zero <= not or_reduce(std_logic_vector(timer_val));
  timer_is_zero <= timer_zero;
  timer_reached_zero <= timer_zero xor last_timer;
  
  waitp : PROCESS (clk, rst)
  BEGIN
    -- load the value into the timer at reset
    if rst = '1' then
      timer_val <= wait_time;
      last_timer <= '0';
      -- possibly add last_zf and zf = 1
    -- for every clock cycle decrement the timer value and update the state variable
    -- accordingly, triggering the timer zero flag as soon as the timer reaches zero
    elsif rising_edge(clk) then
      last_timer <= timer_zero;
      if timer_zero = '0' then
        timer_val <= timer_val - to_unsigned(1, timer_width);
      end if;
    end if;
  END PROCESS;
END wt;