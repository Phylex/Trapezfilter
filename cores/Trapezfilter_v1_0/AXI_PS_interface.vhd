
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity AXI_PS_interface is
  generic (
    FRAME_WIDTH: natural;
    FIFO_CNT_WIDTH: natural;
    FILTER_STATUS_WIDTH: natural;
    KL_PARAM_WIDTH: natural;
    M_PARAM_WIDTH: natural;
    PTHRESH_WIDTH: natural;
    ACTIME_WIDTH: natural;
    
    C_S_AXI_DATA_WIDTH: natural;
    C_S_AXI_ADDR_WIDTH: natural
  );
  port (
    -- input from FIFO
    frame: in std_logic_vector(FRAME_WIDTH-1 downto 0) := (others => '0');
    fifo_rd_en: out std_logic := '0';
    -- filter status information
    fifo_cnt: in std_logic_vector(FIFO_CNT_WIDTH-1 downto 0) := (others => '0');
    filter_status: in std_logic_vector(FILTER_STATUS_WIDTH-1 downto 0) := (others => '0');
    -- parameter output
    param_valid: out std_logic := '0';
    param_updated: out std_logic := '0';
    merged_parameters: out std_logic_vector(1 +
                                              2*KL_PARAM_WIDTH +
                                              M_PARAM_WIDTH +
                                              PTHRESH_WIDTH +
                                              ACTIME_WIDTH-1 downto 0) := (others => '0');
    -- control signal output (coming from ps)
    fpga_clk: out std_logic := '0';
    system_rst: out std_logic := '1';
    ps_reset: out std_logic := '0';
    
    
    -- AXI bus ports
    -- global bus signals
    s_axi_aclk: in std_logic;
    s_axi_aresetn: in std_logic;
    
    -- Write Channel signals --
    -- control signals
    s_axi_awaddr: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_awprot: in std_logic_vector(2 downto 0);
    s_axi_awvalid: in std_logic;
    s_axi_awready: out std_logic;
    -- data signals
    s_axi_wdata: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_wstrb: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    s_axi_wvalid: in std_logic;
    s_axi_wready: out std_logic;
    
    -- Write response Channel signals --
    s_axi_bresp: out std_logic_vector(1 downto 0);
    s_axi_bvalid: out std_logic;
    s_axi_bready: in std_logic;
    
    -- Read Channel signals --
    -- control signals
    s_axi_araddr: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_arprot: in std_logic_vector(2 downto 0);
    s_axi_arready: out std_logic;
    s_axi_arvalid: in std_logic;
    -- data signals
    s_axi_rdata: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_rresp: out std_logic_vector(1 downto 0);
    s_axi_rvalid: out std_logic;
    s_axi_rready: in std_logic
  );
end entity;

architecture rtl of AXI_PS_interface is
  signal system_reset : std_logic;
  signal param_reg_0 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal param_reg_1 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal param_reg_2 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal param_reg_0_written: std_logic;
  signal param_reg_1_written: std_logic;
  signal param_reg_2_written: std_logic;
begin
  -- this is the part that directly connects to the ps
  axi_bus_interface: entity work.AXI_4_BUS_LOGIC
    generic map (
      FIFO_CNT_WIDTH => FIFO_CNT_WIDTH,
      FRAME_WIDTH => FRAME_WIDTH,
      FILTER_STATUS_WIDTH => FILTER_STATUS_WIDTH,
      C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH,
      C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH
    )
    port map (
      -- Frame from filter
      Frame => Frame,
      fifo_rd_en => fifo_rd_en,
      -- state information
      fifo_cnt => fifo_cnt,
      filter_status => filter_status,
      -- parameter signals
      param_reg_0 => param_reg_0, 
      param_reg_1 => param_reg_1,
      param_reg_2 => param_reg_2,
      param_reg_0_written => param_reg_0_written,
      param_reg_1_written => param_reg_1_written,
      param_reg_2_written => param_reg_2_written,
      -- PS reset signal
      PS_reset => ps_reset,
      -- global fpga clock output      
      -- Global Clock Signal from axi bus
      S_AXI_ACLK => s_axi_aclk,
      -- Global Reset Signal. This Signal is Active LOW
      S_AXI_ARESETN  => s_axi_aresetn,
      --axi signals
      S_AXI_AWADDR => s_axi_awaddr,
      S_AXI_AWPROT => s_axi_awprot,
      S_AXI_AWVALID => s_axi_awvalid,
      S_AXI_AWREADY => s_axi_awready,
      S_AXI_WDATA => s_axi_wdata,
      S_AXI_WSTRB => s_axi_wstrb,
      S_AXI_WVALID => s_axi_wvalid,
      S_AXI_WREADY => s_axi_wready,
      S_AXI_BRESP => s_axi_bresp,
      S_AXI_BVALID => s_axi_bvalid,
      S_AXI_BREADY => s_axi_bready,
      S_AXI_ARADDR => s_axi_araddr,
      S_AXI_ARPROT => s_axi_arprot,
      S_AXI_ARVALID => s_axi_arvalid,
      S_AXI_ARREADY => s_axi_arready,
      S_AXI_RDATA => s_axi_rdata,
      S_AXI_RRESP => s_axi_rresp,
      S_AXI_RVALID => s_axi_rvalid,
      S_AXI_RREADY => s_axi_rready
    );
    fpga_clk <= s_axi_aclk;
    system_reset <= not s_axi_aresetn;
    -- system reset is active high but axi reset is acive low
    system_rst <= system_reset;
    
    parameter_extraction: entity work.AXI_to_param
      generic map (
        AXI_REG_WIDTH => C_S_AXI_DATA_WIDTH,
        EVENT_TIMER_WIDTH => ACTIME_WIDTH,
        PEAK_THRESHHOLD_WIDTH => PTHRESH_WIDTH,
        KL_PARAM_WIDTH => KL_PARAM_WIDTH,
        MUL_CONST_WIDTH => M_PARAM_WIDTH
      )
      port map (
        clk => s_axi_aclk,
        rst => system_reset,
        merged_params => merged_parameters,
        param_reg_0 => param_reg_0,
        param_reg_0_valid => param_reg_0_written,
        param_reg_1 => param_reg_1,
        param_reg_1_valid => param_reg_1_written,
        param_reg_2 => param_reg_2,
        param_reg_2_valid => param_reg_2_written,
        param_updated => param_updated,
        param_valid => param_valid
    );

end architecture;