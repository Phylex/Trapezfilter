library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library xpm;
  use xpm.vcomponents.all;

entity CDC is
  generic (
    FRAME_WIDTH: natural;
    MERGED_PARAM_WIDTH: natural;
    FIFO_DEPTH: integer;
    FIFO_COUNTER_WIDTH: natural
  );
  port (
    -- FIFO control logic signal
    -- input from the signal filter
    frame: in std_logic_vector(FRAME_WIDTH-1 downto 0);
    fifo_wr_en: in std_logic;

    -- input from the AXI logic
    fifo_rd_en: in std_logic;

    -- output to the filter control
    fifo_full: out std_logic;
    fifo_empty: out std_logic;
    fifo_busy: out std_logic;

    -- output to the AXI logic
    frame_out: out std_logic_vector(FRAME_WIDTH-1 downto 0);
    frame_count: out std_logic_vector(FIFO_COUNTER_WIDTH-1 downto 0);

    -- clock inputs
    adc_clk: in  std_logic;
    fpga_clk: in std_logic;
    rst: in  std_logic;

    -- parameter CDC signals
    merged_params: in std_logic_vector(MERGED_PARAM_WIDTH-1 downto 0);
    transfer_param_flag: in std_logic;
    param_transfer_ack: out std_logic;
    transfered_parameters: out std_logic_vector(MERGED_PARAM_WIDTH-1 downto 0);

    -- reset CDC signals
    filter_reset_in: in std_logic;
    reset_ack: out std_logic;
    filter_reset_out: out std_logic
  );
end entity;

architecture rtl of CDC is
  signal fifo_rst_rd_busy: std_logic;
  signal fifo_rst_wr_busy: std_logic;
begin

  frame_fifo_and_cdc : xpm_fifo_async
    generic map (
      CDC_SYNC_STAGES => 2, -- DECIMAL
      DOUT_RESET_VALUE => "0", -- String
      ECC_MODE => "no_ecc", -- String
      FIFO_MEMORY_TYPE => "auto", -- String
      FIFO_READ_LATENCY => 0, -- DECIMAL
      FIFO_WRITE_DEPTH => FIFO_DEPTH, -- DECIMAL
      FULL_RESET_VALUE => 0, -- DECIMAL
      PROG_EMPTY_THRESH => 10, -- DECIMAL
      PROG_FULL_THRESH => FIFO_DEPTH-10, -- DECIMAL
      RD_DATA_COUNT_WIDTH => FIFO_COUNTER_WIDTH, -- DECIMAL
      READ_DATA_WIDTH => FRAME_WIDTH, -- DECIMAL
      READ_MODE => "std", -- String
      RELATED_CLOCKS => 0, -- DECIMAL
      USE_ADV_FEATURES => "0400", -- String
      WAKEUP_TIME => 0, -- DECIMAL
      WRITE_DATA_WIDTH => FRAME_WIDTH, -- DECIMAL
      WR_DATA_COUNT_WIDTH => FIFO_COUNTER_WIDTH -- DECIMAL
    )
    port map (
      almost_empty => open, -- 1-bit output: Almost Empty : When asserted, this signal indicates that 
                                     -- only one more read can be performed before the FIFO goes to empty. 
      almost_full => open, -- 1-bit output: Almost Full: When asserted, this signal indicates that 
                                   -- only one more write can be performed before the FIFO is full. 
      data_valid => open, -- 1-bit output: Read Data Valid: When asserted, this signal indicates
                                 -- that valid data is available on the output bus (dout). 
      dbiterr => open, -- 1-bit output: Double Bit Error: Indicates that the ECC decoder 
                           -- detected a double-bit error and data in the FIFO core is corrupted. 
      dout => frame_out, -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven 
                    -- when reading the FIFO. 
      empty => fifo_empty, -- 1-bit output: Empty Flag: When asserted, this signal indicates that 
                      -- the FIFO is empty. Read requests are ignored when the FIFO is empty, 
                      -- initiating a read while empty is not destructive to the FIFO. 
      full => fifo_full, -- 1-bit output: Full Flag: When asserted, this signal indicates that the 
                    -- FIFO is full. Write requests are ignored when the FIFO is full, 
                    -- initiating a write when the FIFO is full is not destructive to the 
                    -- contents of the FIFO. 
      overflow => open, -- 1-bit output: Overflow: This signal indicates that a write request 
                             -- (wren) during the prior clock cycle was rejected, because the FIFO is 
                             -- full. Overflowing the FIFO is not destructive to the contents of the 
                             -- FIFO. 
      prog_empty => open, -- 1-bit output: Programmable Empty: This signal is asserted when the 
                                 -- number of words in the FIFO is less than or equal to the programmable 
                                 -- empty threshold value. It is de-asserted when the number of words in 
                                 -- the FIFO exceeds the programmable empty threshold value. 
      prog_full => open, -- 1-bit output: Programmable Full: This signal is asserted when the 
      -- number of words in the FIFO is greater than or equal to the 
      -- programmable full threshold value. It is de-asserted when the number 
      -- of words in the FIFO is less than the programmable full threshold 
      -- value. 
      rd_data_count => frame_count, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates 
      -- the number of words read from the FIFO. 
      rd_rst_busy => fifo_rst_rd_busy, -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO 
      -- read domain is currently in a reset state. 
      sbiterr => open, -- 1-bit output: Single Bit Error: Indicates that the ECC decoder 
      -- detected and fixed a single-bit error.
      underflow => open, -- 1-bit output: Underflow: Indicates that the read request (rd_en) 
      -- during the previous clock cycle was rejected because the FIFO is 
      -- empty. Under flowing the FIFO is not destructive to the FIFO. 
      wr_ack => open, -- 1-bit output: Write Acknowledge: This signal indicates that a write 
      -- request (wr_en) during the prior clock cycle is succeeded. 
      wr_data_count => open, -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates 
      -- the number of words written into the FIFO. 
      wr_rst_busy => fifo_rst_wr_busy, -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO 
      -- write domain is currently in a reset state. 
      din => frame, -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when 
      -- writing the FIFO. 
      injectdbiterr => '0', -- 1-bit input: Double Bit Error Injection: Injects a double bit error if 
      -- the ECC feature is used on block RAMs or UltraRAM macros. 
      injectsbiterr => '0', -- 1-bit input: Single Bit Error Injection: Injects a single bit error if 
      -- the ECC feature is used on block RAMs or UltraRAM macros. 
      rd_clk => fpga_clk, -- 1-bit input: Read clock: Used for read operation. rd_clk must be a 
      -- free running clock. 
      rd_en => fifo_rd_en, -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this 
      -- signal causes data (on dout) to be read from the FIFO. Must be held 
      -- active-low when rd_rst_busy is active high. . 
      rst => rst, -- 1-bit input: Reset: Must be synchronous to wr_clk. Must be applied 
      -- only when wr_clk is stable and free-running. 
      sleep => '0', -- 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo 
      -- block is in power saving mode. 
      wr_clk => adc_clk, -- 1-bit input: Write clock: Used for write operation. wr_clk must be a 
      -- free running clock. 
      wr_en => fifo_wr_en -- 1-bit input: Write Enable: If the FIFO is not full, asserting this 
      -- signal causes data (on din) to be written to the FIFO. Must be held 
      -- active-low when rst or wr_rst_busy is active high. .
    ); -- End of xpm_fifo_async_inst instantiation
  fifo_busy <= fifo_rst_rd_busy or fifo_rst_wr_busy;

  param_CDC: entity work.CDCrosser
    generic map (
      DATA_WIDTH => MERGED_PARAM_WIDTH
    )
    port map (
      sender_clk => fpga_clk,
      din => merged_params,
      valid_strobe => transfer_param_flag,
      transfered => param_transfer_ack,
      rst => rst,
      reciever_clk => adc_clk,
      dout => transfered_parameters
    );

  filter_reset_CDC: entity work.ResetCDC
    port map (
      FPGA_clk => fpga_clk,
      ADC_clk => adc_clk,
      rst_in => filter_reset_in,
      rst_out => filter_reset_out,
      ack_out => reset_ack
    );
end architecture;
