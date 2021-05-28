library ieee;
  use ieee.std_logic_1164.all;
  use ieee.NUMERIC_STD.all;

library std;
  use std.textio.all;
library work;
  use work.filtertypes.all;
entity tb_MB_signal_filter is
end entity;

architecture rtl_sim of tb_MB_signal_filter is
  constant ADC_SIGNAL_WIDTH: integer := adc_input_width;
  constant LED_COUNT: integer := 8;
  constant FIFO_DEPTH: integer := FB_DEPTH;
  constant FIFO_COUNTER_WIDTH: integer := FB_COUNT_WIDTH;
  constant KL_PARAM_WIDTH: integer := KL_PARAM_WIDTH;
  constant TF_DELAY_DEPTH: natural := tf_delay_buffer_depth;
  constant M_PARAM_WIDTH: integer := mul_const_width;
  constant ACCUM_EXT: natural := accum_2_ext;
  constant FILTER_STATUS_WIDTH: natural := FILTER_STATUS_WIDTH;
  constant ACTIME_WIDTH: integer := event_filter_timer_width;
  constant SPEED_COUNTER_WIDTH: natural := speed_counter_width;
  constant CYCLE_COUNTER_WIDTH: natural := cycle_counter_width;
  constant TIMER_WIDTH: natural := timer_width;
  constant EVENT_FILTER_DEPTH: natural := event_filter_buffer_depth;
  constant EVENT_TIMER_WIDTH: natural := event_filter_timer_width;
  constant C_S01_AXI_DATA_WIDTH: integer := 32;
  constant C_S01_AXI_ADDR_WIDTH: integer := 5;

  constant ADC_CLK_PERIOD: time := 8 ns;
  constant FPGA_CLK_PERIOD: time := 7 ns;
  
  -- tick input
  signal cycle_tick: std_logic;
  signal speed_tick: std_logic;
  
  -- LED output
  signal fifo_fill: std_logic_vector(LED_COUNT + FILTER_STATUS_WIDTH downto 0);
  
  -- adc_input
  signal adc_data_a : std_logic_vector(ADC_SIGNAL_WIDTH - 1 downto 0);
  signal adc_data_b : std_logic_vector(ADC_SIGNAL_WIDTH - 1 downto 0);
  signal adc_clk_a : std_logic;
  signal adc_clk_b : std_logic;
  signal adc_csn : std_logic;
  
  -- axi 4l PS interface
  signal s01_axi_aclk: std_logic;
  signal s01_axi_aresetn: std_logic;
  signal s01_axi_awaddr: std_logic_vector(C_S01_AXI_ADDR_WIDTH - 1 downto 0);
  signal s01_axi_awprot: std_logic_vector(2 downto 0);
  signal s01_axi_awvalid: std_logic;
  signal s01_axi_awready: std_logic;
  signal s01_axi_wdata: std_logic_vector(C_S01_AXI_DATA_WIDTH - 1 downto 0);
  signal s01_axi_wstrb: std_logic_vector((C_S01_AXI_DATA_WIDTH / 8) - 1 downto 0);
  signal s01_axi_wvalid: std_logic;
  signal s01_axi_wready: std_logic;
  signal s01_axi_bresp: std_logic_vector(1 downto 0);
  signal s01_axi_bvalid: std_logic;
  signal s01_axi_bready: std_logic;
  signal s01_axi_araddr: std_logic_vector(C_S01_AXI_ADDR_WIDTH - 1 downto 0);
  signal s01_axi_arprot: std_logic_vector(2 downto 0);
  signal s01_axi_arvalid: std_logic;
  signal s01_axi_arready: std_logic;
  signal s01_axi_rdata: std_logic_vector(C_S01_AXI_DATA_WIDTH - 1 downto 0);
  signal s01_axi_rresp: std_logic_vector(1 downto 0);
  signal s01_axi_rvalid: std_logic;
  signal s01_axi_rready: std_logic;
  
  -- File input
  constant line_width: natural := 10;
  file input_file_param: text;
  file input_file_signal: text;

  -- output of the frame in the register
  signal frame: std_logic_vector(3*C_S01_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

begin

  params_from_file_p: process is
    variable in_line    :   line;
    -- parameters for the filter;
    variable k : integer;
    variable l : integer;
    variable m : integer;
    variable peak_thresh : integer;
    variable accum_time : integer;
    variable adc_select : integer;
    variable param_reg_0: std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
    variable param_reg_1: std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
    variable param_reg_2: std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
    variable ps_reset_reg : std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
    variable p_reg0_addr: integer := 4;
    variable p_reg1_addr: integer := 5;
    variable p_reg2_addr: integer := 6;
    variable ps_reset_addr: integer := 7;

    variable conversion: unsigned(0 downto 0);
    variable space: character;
  begin
    -- read in the filter parameters from the file containing them and the input signal
    file_open(input_file_param, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\tests\MB_filter_parameter.txt", read_mode);
    readline(input_file_param, in_line);
    read(in_line, k);
    readline(input_file_param, in_line);
    read(in_line, l);
    readline(input_file_param, in_line);
    read(in_line, m);
    readline(input_file_param, in_line);
    read(in_line, peak_thresh);
    readline(input_file_param, in_line);
    read(in_line, accum_time);
    adc_select := 0;

    -- arrange the input values in the registers
    param_reg_0 := std_logic_vector(to_unsigned(0, C_S01_AXI_DATA_WIDTH - ACTIME_WIDTH))
    & std_logic_vector(to_unsigned(accum_time, ACTIME_WIDTH));
    param_reg_1 := std_logic_vector(to_unsigned(0, C_S01_AXI_DATA_WIDTH - (ADC_SIGNAL_WIDTH + M_PARAM_WIDTH + ACCUM_EXT)))
    & std_logic_vector(to_signed(peak_thresh, ADC_SIGNAL_WIDTH + M_PARAM_WIDTH + ACCUM_EXT));
    param_reg_2 := std_logic_vector(to_unsigned(0, C_S01_AXI_DATA_WIDTH - 2*KL_PARAM_WIDTH - M_PARAM_WIDTH -1))
    & std_logic_vector(to_unsigned(adc_select, 1))
    & std_logic_vector(to_unsigned(k, KL_PARAM_WIDTH))
    & std_logic_vector(to_unsigned(l, KL_PARAM_WIDTH))
    & std_logic_vector(to_signed(m, M_PARAM_WIDTH));
    ps_reset_reg := std_logic_vector(to_unsigned(1, C_S01_AXI_DATA_WIDTH));

    -- set the initial values for the axi 4l bus
    s01_axi_arprot <= (others => '0');
    s01_axi_awaddr <= (others => '0');
    s01_axi_awprot <= (others => '0');
    s01_axi_awvalid <= '0';
    s01_axi_wdata <= (others => '0');
    s01_axi_wstrb <= (others => '0');
    s01_axi_bready <= '0';
    s01_axi_wvalid <= '0';

    -- wait for the bus to become active
    wait until rising_edge(s01_axi_aresetn);
    wait for 50 ns;

    -- write the parameters to the filter via the axi 4l bus

    -- begin first WRITE TRANSACTION to the set the ps reset flag.
    -- master writes address on the address line and signals validity
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awaddr <= std_logic_vector(to_unsigned(ps_reset_addr*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s01_axi_aclk);
    s01_axi_wdata <= ps_reset_reg;
    s01_axi_wstrb <= (others => '1');
    s01_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s01_axi_wready = '0' or s01_axi_awready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s01_axi_wvalid <= '0';
    s01_axi_awvalid <= '0';
    s01_axi_wstrb <= (others => '0');
    s01_axi_awaddr <= (others => '0');
    s01_axi_wdata <= (others => '0');
    -- the write response completes the transaction.
    while s01_axi_bvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_bready <= '1';
    wait until rising_edge(s01_axi_aclk);
    s01_axi_bready <= '0';

    -- wait a bit until starting the next transfer.
    wait for 100 ns;

    -- begin second WRITE TRANSACTION to the set the parameters in the first register flag.
    -- master writes address on the address line and signals validity
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awaddr <= std_logic_vector(to_unsigned(p_reg0_addr*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s01_axi_aclk);
    s01_axi_wdata <= param_reg_0;
    s01_axi_wstrb <= (others => '1');
    s01_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s01_axi_wready = '0' or s01_axi_awready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s01_axi_wvalid <= '0';
    s01_axi_awvalid <= '0';
    s01_axi_wstrb <= (others => '0');
    s01_axi_awaddr <= (others => '0');
    s01_axi_wdata <= (others => '0');
    -- the write response completes the transaction.
    while s01_axi_bvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_bready <= '1';
    wait until rising_edge(s01_axi_aclk);
    s01_axi_bready <= '0';

    -- wait a bit until the next transaction
    wait for 100 ns;

    -- begin third WRITE TRANSACTION to the set the parameters in the second register flag.
    -- master writes address on the address line and signals validity
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awaddr <= std_logic_vector(to_unsigned(p_reg1_addr*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s01_axi_aclk);
    s01_axi_wdata <= param_reg_1;
    s01_axi_wstrb <= (others => '1');
    s01_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s01_axi_wready = '0' or s01_axi_awready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s01_axi_wvalid <= '0';
    s01_axi_awvalid <= '0';
    s01_axi_wstrb <= (others => '0');
    s01_axi_awaddr <= (others => '0');
    s01_axi_wdata <= (others => '0');
    -- the write response completes the transaction.
    while s01_axi_bvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_bready <= '1';
    wait until rising_edge(s01_axi_aclk);
    s01_axi_bready <= '0';

    -- wait another bit until the last parameter transfer
    wait for 100 ns;

    -- begin fourth WRITE TRANSACTION to the set the parameters in the third register.
    -- master writes address on the address line and signals validity
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awaddr <= std_logic_vector(to_unsigned(p_reg2_addr*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s01_axi_aclk);
    s01_axi_wdata <= param_reg_2;
    s01_axi_wstrb <= (others => '1');
    s01_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s01_axi_wready = '0' or s01_axi_awready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s01_axi_wvalid <= '0';
    s01_axi_awvalid <= '0';
    s01_axi_wstrb <= (others => '0');
    s01_axi_awaddr <= (others => '0');
    s01_axi_wdata <= (others => '0');
    -- the write response completes the transaction.
    while s01_axi_bvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_bready <= '1';
    wait until rising_edge(s01_axi_aclk);
    s01_axi_bready <= '0';

    -- wait another bit until clearing the ps reset flag
    wait for 100 ns;

    ps_reset_reg := std_logic_vector(to_unsigned(0, C_S01_AXI_DATA_WIDTH));

    -- begin fourth WRITE TRANSACTION to the set the parameters in the third register.
    -- master writes address on the address line and signals validity
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awaddr <= std_logic_vector(to_unsigned(ps_reset_addr*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s01_axi_aclk);
    s01_axi_wdata <= ps_reset_reg;
    s01_axi_wstrb <= (others => '1');
    s01_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s01_axi_wready = '0' or s01_axi_awready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s01_axi_wvalid <= '0';
    s01_axi_awvalid <= '0';
    s01_axi_wstrb <= (others => '0');
    s01_axi_awaddr <= (others => '0');
    s01_axi_wdata <= (others => '0');
    -- the write response completes the transaction.
    while s01_axi_bvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_bready <= '1';
    wait until rising_edge(s01_axi_aclk);
    s01_axi_bready <= '0';

    wait for 30000 ns;

    ps_reset_reg := std_logic_vector(to_unsigned(1, C_S01_AXI_DATA_WIDTH));

    -- begin fith WRITE TRANSACTION to the set ps reset and stop the experiment.
    -- master writes address on the address line and signals validity
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awaddr <= std_logic_vector(to_unsigned(ps_reset_addr*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s01_axi_aclk);
    s01_axi_wdata <= ps_reset_reg;
    s01_axi_wstrb <= (others => '1');
    s01_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s01_axi_wready = '0' or s01_axi_awready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s01_axi_wvalid <= '0';
    s01_axi_awvalid <= '0';
    s01_axi_wstrb <= (others => '0');
    s01_axi_awaddr <= (others => '0');
    s01_axi_wdata <= (others => '0');
    -- the write response completes the transaction.
    while s01_axi_bvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_bready <= '1';
    wait until rising_edge(s01_axi_aclk);
    s01_axi_bready <= '0';
  end process;

  signal_from_file_p: process
    variable in_line    :   line;
    variable readval : integer;
    variable space: character;
    variable conversion : std_logic_vector(0 downto 0);
  begin
    file_open(input_file_signal, "C:\Users\Alexander\Documents\Uni\Bachelorarbeit\Testdaten\tests\MB_filter_signal.txt", read_mode);
    while not endfile(input_file_signal) loop
      wait until rising_edge(adc_clk_a);
      readline(input_file_signal, in_line);
      read(in_line, readval);
      adc_data_a <= std_logic_vector(to_signed(readval, ADC_SIGNAL_WIDTH));
	  adc_data_b <= std_logic_vector(to_signed(readval, ADC_SIGNAL_WIDTH));
      read(in_line, space);
      read(in_line, readval);
      conversion := std_logic_vector(to_unsigned(readval, 1));
      cycle_tick <= conversion(0);
      read(in_line, space);
      read(in_line, readval);
      conversion := std_logic_vector(to_unsigned(readval, 1));
      speed_tick <= conversion(0);
    end loop;
    file_close(input_file_signal);
    wait;
  end process;
  
  AXI_filter_readout: process is
  begin
    s01_axi_araddr <= (others => '0');
    s01_axi_rready <= '0';
    s01_axi_arvalid <= '0';
    wait for 30000 ns;
    
    -- empty the fifo by reading the sequence of the registers zero to two
    
    -- READ TRANSACTON
    -- set read address
    wait until rising_edge(s01_axi_aclk);
    s01_axi_araddr <= std_logic_vector(to_unsigned(0*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_arvalid <= '1';
    s01_axi_rready <= '1';
    -- signal readienes to recieve the data;
    while s01_axi_arready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_arvalid <= '0';
    -- wait until data is valid
    while s01_axi_rvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    frame(C_S01_AXI_DATA_WIDTH-1 downto 0) <= s01_axi_rdata;
    -- unset flags
    s01_axi_rready <= '0';
    s01_axi_araddr <= (others => '0');
    wait for 50 ns;
    
    -- READ TRANSACTON
    -- set read address
    wait until rising_edge(s01_axi_aclk);
    s01_axi_araddr <= std_logic_vector(to_unsigned(1*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_arvalid <= '1';
    s01_axi_rready <= '1';
    -- signal readienes to recieve the data;
    while s01_axi_arready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_arvalid <= '0';
    -- wait until data is valid
    while s01_axi_rvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    frame(2*C_S01_AXI_DATA_WIDTH-1 downto C_S01_AXI_DATA_WIDTH) <= s01_axi_rdata;
    -- unset flags
    s01_axi_rready <= '0';
    s01_axi_araddr <= (others => '0');
    wait for 50 ns;

    -- READ TRANSACTON
    -- set read address
    wait until rising_edge(s01_axi_aclk);
    s01_axi_araddr <= std_logic_vector(to_unsigned(2*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_arvalid <= '1';
    s01_axi_rready <= '1';
    -- signal readienes to recieve the data;
    while s01_axi_arready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_arvalid <= '0';
    -- wait until data is valid
    while s01_axi_rvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    frame(3*C_S01_AXI_DATA_WIDTH-1 downto 2*C_S01_AXI_DATA_WIDTH) <= s01_axi_rdata;
    -- unset flags
    s01_axi_rready <= '0';
    s01_axi_araddr <= (others => '0');
    wait for 1000 ns;
    
    -- READ second frame in buffer
    
    -- READ TRANSACTON
    -- set read address
    wait until rising_edge(s01_axi_aclk);
    s01_axi_araddr <= std_logic_vector(to_unsigned(0*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_arvalid <= '1';
    s01_axi_rready <= '1';
    -- signal readienes to recieve the data;
    while s01_axi_arready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_arvalid <= '0';
    -- wait until data is valid
    while s01_axi_rvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    frame(C_S01_AXI_DATA_WIDTH-1 downto 0) <= s01_axi_rdata;
    -- unset flags
    s01_axi_rready <= '0';
    s01_axi_araddr <= (others => '0');
    wait for 50 ns;

    -- READ TRANSACTON
    -- set read address
    wait until rising_edge(s01_axi_aclk);
    s01_axi_araddr <= std_logic_vector(to_unsigned(1*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_arvalid <= '1';
    s01_axi_rready <= '1';
    -- signal readienes to recieve the data;
    while s01_axi_arready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_arvalid <= '0';
    -- wait until data is valid
    while s01_axi_rvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    frame(2*C_S01_AXI_DATA_WIDTH-1 downto C_S01_AXI_DATA_WIDTH) <= s01_axi_rdata;
    -- unset flags
    s01_axi_rready <= '0';
    s01_axi_araddr <= (others => '0');
    wait for 50 ns;

    -- READ TRANSACTON
    -- set read address
    wait until rising_edge(s01_axi_aclk);
    s01_axi_araddr <= std_logic_vector(to_unsigned(2*4, C_S01_AXI_ADDR_WIDTH));
    wait until rising_edge(s01_axi_aclk);
    s01_axi_arvalid <= '1';
    s01_axi_rready <= '1';
    -- signal readienes to recieve the data;
    while s01_axi_arready = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    s01_axi_arvalid <= '0';
    -- wait until data is valid
    while s01_axi_rvalid = '0' loop
      wait until rising_edge(s01_axi_aclk);
    end loop;
    frame(3*C_S01_AXI_DATA_WIDTH-1 downto 2*C_S01_AXI_DATA_WIDTH) <= s01_axi_rdata;
    -- unset flags
    s01_axi_rready <= '0';
    s01_axi_araddr <= (others => '0');
    wait;
  end process;
  
  MB_sim_signal_filter_inst: entity work.MB_sim_signal_filter
    generic map (
      ADC_SIGNAL_WIDTH       => ADC_SIGNAL_WIDTH,
      LED_COUNT              => LED_COUNT,
      FIFO_DEPTH             => FIFO_DEPTH,
      FIFO_COUNTER_WIDTH     => FIFO_COUNTER_WIDTH,
      KL_PARAM_WIDTH         => KL_PARAM_WIDTH,
      TF_DELAY_DEPTH         => TF_DELAY_DEPTH,
      M_PARAM_WIDTH          => M_PARAM_WIDTH,
      ACCUM_EXT              => ACCUM_EXT,
      FILTER_STATUS_WIDTH    => FILTER_STATUS_WIDTH,
      SPEED_COUNTER_WIDTH    => SPEED_COUNTER_WIDTH,
      CYCLE_COUNTER_WIDTH    => CYCLE_COUNTER_WIDTH,
      TIMER_WIDTH            => TIMER_WIDTH,
      EVENT_FILTER_DEPTH     => EVENT_FILTER_DEPTH,
      EVENT_TIMER_WIDTH      => EVENT_TIMER_WIDTH,
      C_S01_AXI_DATA_WIDTH   => C_S01_AXI_DATA_WIDTH,
      C_S01_AXI_ADDR_WIDTH   => C_S01_AXI_ADDR_WIDTH
    )
    port map (
      cycle_tick             => cycle_tick,
      speed_tick             => speed_tick,
      fifo_fill              => fifo_fill,
	  adc_clk_a				 => adc_clk_a,
	  adc_clk_b				 => adc_clk_b,
	  adc_data_a			 => adc_data_a,
	  adc_data_b			 => adc_data_b,
	  adc_csn 				 => adc_csn,
      s01_axi_aclk           => s01_axi_aclk,
      s01_axi_aresetn        => s01_axi_aresetn,
      s01_axi_awaddr         => s01_axi_awaddr,
      s01_axi_awprot         => s01_axi_awprot,
      s01_axi_awvalid        => s01_axi_awvalid,
      s01_axi_awready        => s01_axi_awready,
      s01_axi_wdata          => s01_axi_wdata,
      s01_axi_wstrb          => s01_axi_wstrb,
      s01_axi_wvalid         => s01_axi_wvalid,
      s01_axi_wready         => s01_axi_wready,
      s01_axi_bresp          => s01_axi_bresp,
      s01_axi_bvalid         => s01_axi_bvalid,
      s01_axi_bready         => s01_axi_bready,
      s01_axi_araddr         => s01_axi_araddr,
      s01_axi_arprot         => s01_axi_arprot,
      s01_axi_arvalid        => s01_axi_arvalid,
      s01_axi_arready        => s01_axi_arready,
      s01_axi_rdata          => s01_axi_rdata,
      s01_axi_rresp          => s01_axi_rresp,
      s01_axi_rvalid         => s01_axi_rvalid,
      s01_axi_rready         => s01_axi_rready
    );

  adc_clock_p: process is
  begin
    adc_clk_a <= '0';
	adc_clk_b <= '1';
    wait for ADC_CLK_PERIOD / 2;
    adc_clk_a <= '1';
	adc_clk_b <= '0';
    wait for ADC_CLK_PERIOD / 2;
  end process;
  
  fpga_clock_p: process is
  begin
    s01_axi_aclk <= '0';
    wait for FPGA_CLK_PERIOD/2;
    s01_axi_aclk <= '1';
    wait for FPGA_CLK_PERIOD/2;
  end process;
  
  reset_p: process is
  begin
    s01_axi_aresetn <= '0';
    wait for 50 ns;
    s01_axi_aresetn <= '1';
    wait;
  end process;


end architecture;