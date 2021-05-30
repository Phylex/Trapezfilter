library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.filtertypes.all;

entity MB_signal_filter is
	generic (
    ADC_SIGNAL_WIDTH : integer := adc_input_width;
    LED_COUNT : integer := 4;
    
    -- buffer_generics
    FIFO_DEPTH : integer := FB_DEPTH;
    FIFO_COUNTER_WIDTH : integer := FB_COUNT_WIDTH;
    
    -- filter parameter widths
    KL_PARAM_WIDTH : integer := KL_PARAM_WIDTH;
    TF_DELAY_DEPTH: natural := tf_delay_buffer_depth;
    M_PARAM_WIDTH : integer := mul_const_width;
    ACCUM_EXT : natural := accum_2_ext;
    FILTER_STATUS_WIDTH: natural := FILTER_STATUS_WIDTH;
    SPEED_COUNTER_WIDTH : natural := speed_counter_width;
    CYCLE_COUNTER_WIDTH : natural := cycle_counter_width;
    TIMER_WIDTH : natural := timer_width; 
    EVENT_FILTER_DEPTH: natural := event_filter_buffer_depth;
    EVENT_TIMER_WIDTH: natural := event_filter_timer_width;

		-- Parameters of Axi Slave Bus Interface S01_AXI
		C_S01_AXI_DATA_WIDTH	: integer := axi_4l_register_width;
		C_S01_AXI_ADDR_WIDTH	: integer := axi_addr_width
	);
	port (
    -- inputs from the cycle and speed tick
    cycle_tick: in std_logic;
    speed_tick: in std_logic;
    
    -- outputs to the leds to indicate fill state of the buffer
    fifo_fill: out std_logic_vector(1+LED_COUNT+FILTER_STATUS_WIDTH-1 downto 0);
    
    -- ports for the adc
    adc_data_a : in std_logic_vector(ADC_SIGNAL_WIDTH-1 downto 0);
    adc_data_b : in std_logic_vector(ADC_SIGNAL_WIDTH-1 downto 0);
    adc_clk_a: in std_logic;
    adc_clk_b: in std_logic;
    adc_csn: out std_logic;
		
		-- Ports of Axi Slave Bus Interface S01_AXI
		s01_axi_aclk	: in std_logic;
		s01_axi_aresetn	: in std_logic;
		s01_axi_awaddr	: in std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 0);
		s01_axi_awprot	: in std_logic_vector(2 downto 0);
		s01_axi_awvalid	: in std_logic;
		s01_axi_awready	: out std_logic;
		s01_axi_wdata	: in std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
		s01_axi_wstrb	: in std_logic_vector((C_S01_AXI_DATA_WIDTH/8)-1 downto 0);
		s01_axi_wvalid	: in std_logic;
		s01_axi_wready	: out std_logic;
		s01_axi_bresp	: out std_logic_vector(1 downto 0);
		s01_axi_bvalid	: out std_logic;
		s01_axi_bready	: in std_logic;
		s01_axi_araddr	: in std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 0);
		s01_axi_arprot	: in std_logic_vector(2 downto 0);
		s01_axi_arvalid	: in std_logic;
		s01_axi_arready	: out std_logic;
		s01_axi_rdata	: out std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
		s01_axi_rresp	: out std_logic_vector(1 downto 0);
		s01_axi_rvalid	: out std_logic;
		s01_axi_rready	: in std_logic
	);
end MB_signal_filter;

architecture arch_imp of MB_signal_filter is
  constant FILTERED_SIGNAL_WIDTH : natural := ADC_SIGNAL_WIDTH + M_PARAM_WIDTH + ACCUM_EXT;
  constant MERGED_PARAM_WIDTH : natural := 1 + 2*KL_PARAM_WIDTH + M_PARAM_WIDTH + FILTERED_SIGNAL_WIDTH + EVENT_TIMER_WIDTH;
  constant FRAME_WIDTH : natural := FILTERED_SIGNAL_WIDTH + SPEED_COUNTER_WIDTH + CYCLE_COUNTER_WIDTH + TIMER_WIDTH;

  
  -- global signals
  signal filter_reset: std_logic;
  signal system_reset: std_logic;
  signal fpga_clk: std_logic;
  signal filter_clk: std_logic;

  -- adc signal
  signal adc_val: std_logic_vector(ADC_SIGNAL_WIDTH-1 downto 0);
  signal adc_sel: std_logic;
  
  -- fifo signals fpga side
  signal fifo_rd_en: std_logic;
  signal fifo_frame_count: std_logic_vector(FIFO_COUNTER_WIDTH-1 downto 0);
  signal frame_from_fifo: std_logic_vector(FRAME_WIDTH-1 downto 0);
  -- fifo signals filter side
  signal frame_from_filter: std_logic_vector(FRAME_WIDTH-1 downto 0);
  signal fifo_wr_en: std_logic;
  
  -- signals going to filtercontrol
  signal fifo_full: std_logic;
  signal fifo_empty: std_logic;
  signal fifo_busy: std_logic;
  signal filter_status: std_logic_vector(FILTER_STATUS_WIDTH-1 downto 0);
  signal transfer_params: std_logic;
  signal transfer_ack: std_logic;
  signal filter_reset_fpga_side: std_logic;
  signal filter_reset_ack: std_logic;
  signal param_valid: std_logic;
  signal param_updated: std_logic;
  signal ps_reset_flag: std_logic;
  
  --params going to cdc
  signal merged_parameters_to_cdc: std_logic_vector(MERGED_PARAM_WIDTH -1 downto 0);
  signal merged_parameters_from_cdc: std_logic_vector(MERGED_PARAM_WIDTH -1 downto 0);
  
  -- parameters going to filter
  signal k: unsigned(KL_PARAM_WIDTH-1 downto 0);
  signal l: unsigned(KL_PARAM_WIDTH-1 downto 0);
  signal m: signed(M_PARAM_WIDTH - 1 downto 0);
  signal peak_filter_threshhold: signed(FILTERED_SIGNAL_WIDTH - 1 downto 0);
  signal event_filter_accum_time: unsigned(EVENT_TIMER_WIDTH-1 downto 0);
  

begin

-- Instantiation of the adc_interface
adc_interface: entity work.ADC_interface
  generic map (
    adc_data_width => ADC_SIGNAL_WIDTH,
    downsample_width => 5
  )
  port map (
    clk => filter_clk,
    rst => filter_reset,
    adc_sel => adc_sel,
    adc_data => adc_val,
    adc_data_a => adc_data_a,
    adc_data_b => adc_data_b,
    adc_clk_a => adc_clk_a,
    adc_clk_b => adc_clk_b,
    adc_csn => adc_csn
  );

signal_filter: entity work.signal_filter
  generic map(  
    s_word_width => ADC_SIGNAL_WIDTH,
    tf_buffer_length => TF_DELAY_DEPTH,
    KL_PARAM_WIDTH => KL_PARAM_WIDTH,
    tf_max_multiplier_word_width => M_PARAM_WIDTH,
    accum_2_extension => ACCUM_EXT,
    speed_counter_width => SPEED_COUNTER_WIDTH,
    cycle_counter_width => CYCLE_COUNTER_WIDTH,
    timer_width => TIMER_WIDTH,
    event_filter_buffer_depth => EVENT_FILTER_DEPTH,
    event_filter_timer_width => EVENT_TIMER_WIDTH
  )
  port map (  -- parameters from software
    k => k,
    l => l,
    m => m,
    peak_filter_threshhold => peak_filter_threshhold,
    event_filter_accum_time => event_filter_accum_time,
    data_in => signed(adc_val),
    cycle_tick => cycle_tick,
    speed_tick => speed_tick,
    event_out => frame_from_filter,
    event_out_flag => fifo_wr_en,
    clk => filter_clk,
    rst => filter_reset
  );

unpack_prarmeters_from_cdc: entity work.unpack_params
  generic map (
    MERGED_PARAM_WIDTH => MERGED_PARAM_WIDTH,
    KL_PARAM_WIDTH => KL_PARAM_WIDTH,
    MUL_CONST_WIDTH => M_PARAM_WIDTH,
    PEAK_THRESH_WIDTH => FILTERED_SIGNAL_WIDTH,
    EVENT_TIMER_WIDTH => EVENT_TIMER_WIDTH
  )
  port map (
    merged_params => merged_parameters_from_cdc,
    adc_sel => adc_sel,
    k => k,
    l => l,
    m => m,
    peak_filter_thresh => peak_filter_threshhold,
    event_filter_accum_time => event_filter_accum_time
  );

Clock_domain_crossing: entity work.CDC
  generic map (
    FRAME_WIDTH => FRAME_WIDTH,
    MERGED_PARAM_WIDTH => MERGED_PARAM_WIDTH,
    FIFO_DEPTH => FIFO_DEPTH,
    FIFO_COUNTER_WIDTH => FIFO_COUNTER_WIDTH
  )
  port map (
    frame => frame_from_filter,
    fifo_wr_en => fifo_wr_en,
    fifo_rd_en => fifo_rd_en,
    fifo_full => fifo_full,
    fifo_empty => fifo_empty,
    fifo_busy => fifo_busy,
    frame_out => frame_from_fifo,
    frame_count => fifo_frame_count,
    adc_clk => filter_clk,
    fpga_clk => fpga_clk,
    rst => system_reset,
    merged_params => merged_parameters_to_cdc,
    transfer_param_flag => transfer_params,
    param_transfer_ack => transfer_ack,
    transfered_parameters => merged_parameters_from_cdc,
    filter_reset_in => filter_reset_fpga_side,
    reset_ack => filter_reset_ack,
    filter_reset_out => filter_reset
  );
    
Filter_control: entity work.filter_control
  generic map (
    FILTER_STATE_WIDTH => FILTER_STATUS_WIDTH
  )
  port map ( 
    clk => fpga_clk,
    rst => system_reset,
    fifo_empty => fifo_empty,
    fifo_full => fifo_full,
    fifo_rst_busy => fifo_busy,
    ps_filter_reset => ps_reset_flag,
    param_valid => param_valid,
    param_updated => param_updated,
    transfer_params => transfer_params,
    transfer_ack => transfer_ack,
    filter_reset => filter_reset_fpga_side,
    filter_reset_ack => filter_reset_ack,
    filter_state_out => filter_status
  );
             

-- Instantiation of Axi Bus Interface S01_AXI
AXI_PS_inteface_logic: entity work.AXI_PS_interface
	generic map (
    -- frame and buffer parameter
    FRAME_WIDTH => FRAME_WIDTH,
    FIFO_CNT_WIDTH => FIFO_COUNTER_WIDTH,
    FILTER_STATUS_WIDTH => 3,
    
    -- Trapezoidal filter parameter
    KL_PARAM_WIDTH => KL_PARAM_WIDTH,
    M_PARAM_WIDTH => M_PARAM_WIDTH,
    
    -- post processing parameters
    PTHRESH_WIDTH => FILTERED_SIGNAL_WIDTH,
    ACTIME_WIDTH => EVENT_TIMER_WIDTH,
    
    -- axi parameter
		C_S_AXI_DATA_WIDTH	=> C_S01_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S01_AXI_ADDR_WIDTH
	)
	port map (
    Frame => frame_from_fifo,
    fifo_rd_en => fifo_rd_en,
    filter_status => filter_status,
    fifo_cnt => fifo_frame_count,
    param_valid => param_valid,
    param_updated => param_updated,
    merged_parameters => merged_parameters_to_cdc,
    fpga_clk => fpga_clk,
    system_rst => system_reset,
    ps_reset => ps_reset_flag,
    
		S_AXI_ACLK	=>   s01_axi_aclk,
		S_AXI_ARESETN	=> s01_axi_aresetn,
		S_AXI_AWADDR	=> s01_axi_awaddr,
		S_AXI_AWPROT	=> s01_axi_awprot,
		S_AXI_AWVALID	=> s01_axi_awvalid,
		S_AXI_AWREADY	=> s01_axi_awready,
		S_AXI_WDATA	=>   s01_axi_wdata,
		S_AXI_WSTRB	=>   s01_axi_wstrb,
		S_AXI_WVALID	=> s01_axi_wvalid,
		S_AXI_WREADY	=> s01_axi_wready,
		S_AXI_BRESP	=>   s01_axi_bresp,
		S_AXI_BVALID	=> s01_axi_bvalid,
		S_AXI_BREADY	=> s01_axi_bready,
		S_AXI_ARADDR	=> s01_axi_araddr,
		S_AXI_ARPROT	=> s01_axi_arprot,
		S_AXI_ARVALID	=> s01_axi_arvalid,
		S_AXI_ARREADY	=> s01_axi_arready,
		S_AXI_RDATA	=>   s01_axi_rdata,
		S_AXI_RRESP	=>   s01_axi_rresp,
		S_AXI_RVALID	=> s01_axi_rvalid,
		S_AXI_RREADY	=> s01_axi_rready
	);

  -- output the level of the fifo to the leds
  fifo_fill <= filter_reset & filter_status & fifo_frame_count(FIFO_COUNTER_WIDTH-1 downto FIFO_COUNTER_WIDTH-LED_COUNT);

end arch_imp;
