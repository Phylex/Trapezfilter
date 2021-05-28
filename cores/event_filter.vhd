library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.NUMERIC_STD.all;

ENTITY event_filter is
  Generic( peakval_left : natural:= 7;
           peakval_right : natural:= 0; 
           packet_width : natural := 8;
           buffer_depth : natural := 5;
           timer_width : natural := 10
  );
  Port(
    -- input data
    signal  in_event   : in std_logic_vector(packet_width-1 downto 0);
    signal  event_in_flag   : in std_logic;
    
    -- control input
    signal  clk             : in std_logic;
    signal  clr          : in std_logic;
    signal  totzeit     : in unsigned(timer_width-1 downto 0);
    
    -- Output
    signal  out_event   : out std_logic_vector(packet_width-1 downto 0);
    signal  event_out_flag : out std_logic
  );
END event_filter;

ARCHITECTURE event_filter_behav of event_filter is
  type reset_hold_states is (WC0, WC1, WC2, INACTIVE);
  signal rhState: reset_hold_states;
  signal syncd_in_event: std_logic_vector(packet_width-1 downto 0);
  signal syncd_event_in_flag: std_logic;
  signal timer_reached_zero : std_logic;
  signal timer_reset : std_logic;
  signal timer_reset_enable: std_logic;
  signal timer_reset_value: unsigned(timer_width-1 downto 0);
  signal buffer_reset: std_logic;
  signal event_flag: std_logic;
  signal buffer_shift: std_logic;
BEGIN
  -- synchronize asynchronous input
  sync_p: process (clk, clr)
  begin
    if clr = '1' then
      syncd_in_event <= (others => '0');
      syncd_event_in_flag <= '0';
    elsif rising_edge(clk) then
      syncd_in_event <= in_event;
      syncd_event_in_flag <= event_in_flag;
    end if;
  end process;
  
  -- instantiate the timer
  totzeit_timer: entity work.wait_timer
    generic map ( timer_width => timer_width)
    port map (
      rst           => timer_reset,
      clk           => clk,
      wait_time     => timer_reset_value,
      timer_reached_zero  => timer_reached_zero,
      timer_is_zero     => timer_reset_enable
    );
  
  -- instantiate the max-array
  max_array: entity work.max_shift_array
    generic map (
      packet_width   => packet_width,
      buffer_depth   => buffer_depth,
      eval_max_left  => peakval_left,
      eval_max_right => peakval_right
    )
    port map (
      rst            => buffer_reset,
      shift          => buffer_shift,
      packet_in      => syncd_in_event,
      max_packet     => out_event
    );
  
  -- reset the max buffer as soon as the signal out flag has been lowered
  buffer_reset_p: PROCESS (clr, clk, timer_reached_zero)
  BEGIN
    if clr = '1' then
      buffer_reset <= '1';
      event_flag <= '0';
      rhState <= INACTIVE;
    elsif rising_edge(clk) then
      if timer_reached_zero = '1' then
        rhState <= WC0;
        event_flag <= '1';
      elsif rhState = WC0 then
        rhState <= INACTIVE;
        event_flag <= '0';
        buffer_reset <= '1';
      --elsif rhState = WC1 then
        --rhState <= INACTIVE;
        --event_flag <= '0';
        --buffer_reset <= '1';
      elsif buffer_reset = '1' then
        buffer_reset <= '0';
      end if;
    end if;
  END PROCESS;
  -- now comes the wiring of the modules
  -- tell the buffer to shift only if the result is not being output
  buffer_shift <= syncd_event_in_flag and not timer_reached_zero;
  -- wire the timer value directly into the timer
  timer_reset_value <= (others => '0') when clr = '1' else totzeit;
  -- reset the timer only if the result is not outputed
  timer_reset <= clr or (timer_reset_enable and syncd_event_in_flag and (not event_flag));
  -- set the event out flag as soon as the timer reaches zero
  event_out_flag <= event_flag;
  
END event_filter_behav;