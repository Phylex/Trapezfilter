library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use IEEE.std_logic_misc.all;

entity filter_control is
  generic (
    FILTER_STATE_WIDTH: natural
  );
  port (
    -- control inputs
    clk: in  std_logic;
    rst: in  std_logic;
    
    -- fifo status input
    fifo_empty: in std_logic;
    fifo_full: in std_logic;
    fifo_rst_busy: in std_logic;
    
    -- PS reset flag
    ps_filter_reset: in std_logic;
    
    -- parameter status input
    param_valid: in std_logic;
    param_updated: in std_logic;
    
    -- flags for the cdc parameter logic
    transfer_params: out std_logic;
    transfer_ack: in std_logic;

    -- transport the filter reset seperatly;
    filter_reset: out std_logic;
    filter_reset_ack: in std_logic;
    
    -- report the state of the filter back to the ps so it can be inspected.
    filter_state_out: out std_logic_vector(FILTER_STATE_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of filter_control is
  type filter_state_t is (PARAM_INVALID, WAIT_FOR_FIFO, STARTED_PARAM_TRANSFER, PARAM_TRANSFERRING, PARAM_TRANSFERED,
                          FIFO_DRAIN, READY, RUNNING, HALTED, START_FILTER, STOP_FILTER);
  signal filter_state: filter_state_t;
  signal internal_filter_reset: std_logic;
begin
  control_state_m: process ( clk ) is
    variable updated_params_available: std_logic;
  begin
    if rising_edge(clk) then
      if param_updated = '1' then
        updated_params_available := '1';
      end if;
      case filter_state is
        when PARAM_INVALID =>
          -- outputs
          filter_state_out <= std_logic_vector(to_unsigned(1, FILTER_STATE_WIDTH));
          internal_filter_reset <= '1';
          transfer_params <= '0';
          -- state switching mechanism
          if rst = '1' then
            filter_state <= PARAM_INVALID;
          elsif param_valid = '1' then
            filter_state <= STARTED_PARAM_TRANSFER;
            transfer_params <= '1';
            updated_params_available := '0';
          end if;
          
        when STARTED_PARAM_TRANSFER =>
          -- set outputs for state
          filter_state_out <= std_logic_vector(to_unsigned(1, FILTER_STATE_WIDTH));
          internal_filter_reset <= '1';
          transfer_params <= '0';
          -- state transitions
          if  rst = '1' then
            filter_state <= PARAM_INVALID;
          elsif transfer_ack = '1' then
            filter_state <= PARAM_TRANSFERRING;
          end if;
          
        when PARAM_TRANSFERRING =>
          -- set outputs for state
          filter_state_out <= std_logic_vector(to_unsigned(1, FILTER_STATE_WIDTH));
          internal_filter_reset <= '1';
          -- state transitions
          if rst = '1' then
            filter_state <= PARAM_INVALID;
          elsif transfer_ack = '0' then
            filter_state <= PARAM_TRANSFERED;
          end if;
          
        when PARAM_TRANSFERED =>
          -- outputs for state
          filter_state_out <= std_logic_vector(to_unsigned(1, FILTER_STATE_WIDTH));
          internal_filter_reset <= '1';
          -- state transitions
          if rst = '1' then
            filter_state <= PARAM_INVALID;
          elsif updated_params_available = '1' then
            filter_state <= STARTED_PARAM_TRANSFER;
            transfer_params <= '1';
            updated_params_available := '0';
          elsif fifo_rst_busy = '1' then
            filter_state <= WAIT_FOR_FIFO;
          elsif fifo_rst_busy = '0' and fifo_empty = '0' then
            filter_state <= FIFO_DRAIN;
          elsif fifo_rst_busy = '0' and fifo_empty = '1' then
            filter_state <= READY;
          end if;
          
        when WAIT_FOR_FIFO =>
          filter_state_out <= std_logic_vector(to_unsigned(1, FILTER_STATE_WIDTH));
          internal_filter_reset <= '1';
          if rst = '1' then
            filter_state <= PARAM_INVALID;
          elsif fifo_rst_busy = '0' then
            filter_state <= READY;
          end if;
          
        when FIFO_DRAIN =>
          -- outputs for state
          filter_state_out <= std_logic_vector(to_unsigned(2, FILTER_STATE_WIDTH));
          internal_filter_reset <= '1';
          -- state transitions
          if rst = '1' then
            filter_state <= PARAM_INVALID;
          elsif fifo_empty = '1' then
            if updated_params_available = '1' then
              filter_state <= STARTED_PARAM_TRANSFER;
              transfer_params <= '1';
              updated_params_available := '0';
            else
              filter_state <= READY;
            end if;
          end if;
          
        when READY =>
          -- outputs for state
          filter_state_out <= std_logic_vector(to_unsigned(3, FILTER_STATE_WIDTH));
          internal_filter_reset <= '1';
          -- state changes
          if rst = '1' then
            filter_state <= PARAM_INVALID;
          elsif updated_params_available = '1'then
            filter_state <= STARTED_PARAM_TRANSFER;
            transfer_params <= '1';
            updated_params_available := '0';
          elsif ps_filter_reset = '0' then
            filter_state <= START_FILTER;
          end if;
                   
        when START_FILTER =>
          internal_filter_reset <= '0';
          filter_state_out <= std_logic_vector(to_unsigned(4, FILTER_STATE_WIDTH));
          if rst = '1' then
            filter_state <= PARAM_INVALID;
          elsif (filter_reset_ack xor internal_filter_reset) = '0' then
            filter_state <= RUNNING;
          end if;
            
        when RUNNING =>
          -- outputs for state
          filter_state_out <= std_logic_vector(to_unsigned(4, FILTER_STATE_WIDTH));
          internal_filter_reset <= '0';
          -- state changes
          if rst = '1' then
            filter_state <= PARAM_INVALID;
          elsif ps_filter_reset = '1' or fifo_full = '1' then
            filter_state <= STOP_FILTER;
          end if;
          
        when STOP_FILTER =>
          filter_state_out <= std_logic_vector(to_unsigned(5, FILTER_STATE_WIDTH));
          internal_filter_reset <= '1';
          if rst = '1' then
            filter_state <= PARAM_INVALID;
          elsif (filter_reset_ack xor internal_filter_reset) = '0' then
            filter_state <= HALTED;
          end if;
          
        when HALTED => 
          --outputs for state
          filter_state_out <= std_logic_vector(to_unsigned(5, FILTER_STATE_WIDTH));
          internal_filter_reset <= '1';
          -- state changes
          if rst = '1' then
            filter_state <= PARAM_INVALID;
          elsif ps_filter_reset = '1' then
            filter_state <= FIFO_DRAIN;
          end if;
          
        when others =>
          filter_state_out <= std_logic_vector(to_unsigned(1, FILTER_STATE_WIDTH));
          internal_filter_reset <= '1';
          filter_state <= PARAM_INVALID;
      end case;
    end if;
  end process;
  filter_reset <= internal_filter_reset;
end architecture;