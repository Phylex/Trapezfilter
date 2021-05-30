library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity AXI_to_param is
  generic (
    AXI_REG_WIDTH: natural;
    EVENT_TIMER_WIDTH: natural;
    PEAK_THRESHHOLD_WIDTH: natural;
    KL_PARAM_WIDTH: natural;
    MUL_CONST_WIDTH: natural
  );
  port (
    clk: in  std_logic;
    rst: in  std_logic;
    merged_params: out std_logic_vector(EVENT_TIMER_WIDTH+
                                          PEAK_THRESHHOLD_WIDTH+
                                          KL_PARAM_WIDTH+
                                          KL_PARAM_WIDTH+
                                          MUL_CONST_WIDTH+
                                          1 -1 downto 0);  -- +1 for adc select-1 downto 0);
    
    param_reg_0: in std_logic_vector(AXI_REG_WIDTH-1 downto 0);
    param_reg_0_valid: in std_logic;
    param_reg_1: in std_logic_vector(AXI_REG_WIDTH-1 downto 0);
    param_reg_1_valid: in std_logic;
    param_reg_2: in std_logic_vector(AXI_REG_WIDTH-1 downto 0);
    param_reg_2_valid: in std_logic;
    
    param_updated: out std_logic;
    param_valid: out std_logic
  );
end entity;

architecture rtl of AXI_to_param is
  signal params_valid: std_logic := '0';
  constant PARAM_REG_1_PARAM_WIDTH: natural := PEAK_THRESHHOLD_WIDTH;
  constant PARAM_REG_0_PARAM_WIDTH: natural := EVENT_TIMER_WIDTH;
  constant PARAM_REG_2_PARAM_WIDTH: natural := 2*KL_PARAM_WIDTH + MUL_CONST_WIDTH +1; -- adc select is the plus 1
  constant MERGED_PARAMS_REG_1_LOWER_BOUND: natural := PARAM_REG_0_PARAM_WIDTH;
  constant MERGED_PARAMS_REG_1_UPPER_BOUND: natural := PARAM_REG_0_PARAM_WIDTH + PARAM_REG_1_PARAM_WIDTH;
  constant MERGED_PARAMS_REG_2_LOWER_BOUND: natural := MERGED_PARAMS_REG_1_UPPER_BOUND;
  constant MERGED_PARAMS_REG_2_UPPER_BOUND: natural := MERGED_PARAMS_REG_2_LOWER_BOUND + PARAM_REG_2_PARAM_WIDTH;
begin
  update_p: process ( clk ) is
  begin
    if rst = '1' then
      param_updated <= '0';
    elsif rising_edge(clk) then
      if params_valid = '1' then
        param_updated <= (param_reg_0_valid or param_reg_1_valid or param_reg_2_valid);
      end if;
    end if;
  end process;
  
  valid_p: process ( clk ) is
    variable rg0_valid: std_logic;
    variable rg1_valid: std_logic;
    variable rg2_valid: std_logic;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rg0_valid := '0';
        rg1_valid := '0';
        rg2_valid := '0';
        params_valid <= '0';
      else 
        if param_reg_0_valid = '1' then
          rg0_valid := '1';
        end if;
        if param_reg_1_valid = '1' then
          rg1_valid := '1';
        end if;
        if param_reg_2_valid = '1' then
          rg2_valid := '1';
        end if;
        if (rg0_valid and rg1_valid and rg2_valid) = '1' then
          params_valid <= '1';
        end if;
      end if;
    end if;
  end process;
  param_valid <= params_valid;
  
  klm_sync_and_verify: process ( clk ) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        merged_params(PARAM_REG_0_PARAM_WIDTH-1 downto 0) <= (others => '0');
        -- the reset flag from the ps comes from here so we extract it and don't do any
      elsif param_reg_0_valid = '1' then
        merged_params(PARAM_REG_0_PARAM_WIDTH-1 downto 0) <= param_reg_0(PARAM_REG_0_PARAM_WIDTH-1 downto 0);
      end if;
    end if;
  end process;

  peak_threshhold_sync_and_verify: process ( clk ) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        merged_params(MERGED_PARAMS_REG_1_UPPER_BOUND-1 downto MERGED_PARAMS_REG_1_LOWER_BOUND) <= (others => '0');
      elsif param_reg_1_valid = '1' then
        merged_params(MERGED_PARAMS_REG_1_UPPER_BOUND-1 downto MERGED_PARAMS_REG_1_LOWER_BOUND) <= param_reg_1(PARAM_REG_1_PARAM_WIDTH-1 downto 0);
      end if;
    end if;
  end process;

  accum_time_sync_and_verify: process ( clk ) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        merged_params(MERGED_PARAMS_REG_2_UPPER_BOUND-1 downto MERGED_PARAMS_REG_2_LOWER_BOUND) <= (others => '0');
      elsif param_reg_2_valid = '1' then
        merged_params(MERGED_PARAMS_REG_2_UPPER_BOUND-1 downto MERGED_PARAMS_REG_2_LOWER_BOUND) <= param_reg_2(PARAM_REG_2_PARAM_WIDTH-1 downto 0);
      end if;
    end if;
  end process;
end architecture;