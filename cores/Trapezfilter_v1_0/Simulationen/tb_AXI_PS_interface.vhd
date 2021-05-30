library ieee;
  use ieee.std_logic_1164.all;
  use ieee.NUMERIC_STD.all;

library std;
  use std.textio.all;

library work;
  use work.filtertypes.all;

entity tb_AXI_PS_interface is
end entity;

architecture rtl_sim of tb_AXI_PS_interface is
  constant FRAME_WIDTH: natural := 96;
  constant FIFO_CNT_WIDTH: natural := 11;
  constant FILTER_STATUS_WIDTH: natural := 3;
  constant KL_PARAM_WIDTH: natural := 7;
  constant M_PARAM_WIDTH: natural := mul_const_width;
  constant PTHRESH_WIDTH: natural := filtered_signal_width;
  constant ACTIME_WIDTH: natural := event_filter_timer_width;
  constant C_S_AXI_DATA_WIDTH: natural := 32;
  constant C_S_AXI_ADDR_WIDTH: natural := 5;

  constant CLK_PERIOD: time := 8 ns;
  signal frame: std_logic_vector(FRAME_WIDTH - 1 downto 0) := (others => '0');
  signal fifo_rd_en: std_logic := '0';
  signal fifo_cnt: std_logic_vector(FIFO_CNT_WIDTH - 1 downto 0) := (others => '0');
  signal filter_status: std_logic_vector(FILTER_STATUS_WIDTH - 1 downto 0) := "001";
  signal param_valid: std_logic := '0';
  signal param_updated: std_logic := '0';
  signal merged_parameters: std_logic_vector(1 + 2 * KL_PARAM_WIDTH + M_PARAM_WIDTH + PTHRESH_WIDTH + ACTIME_WIDTH - 1 downto 0) := (others => '0');
  signal fpga_clk: std_logic;
  signal system_rst: std_logic;
  signal ps_reset: std_logic;
  signal s_axi_aclk: std_logic;
  signal s_axi_aresetn: std_logic;
  signal s_axi_awaddr: std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
  signal s_axi_awprot: std_logic_vector(2 downto 0);
  signal s_axi_awvalid: std_logic;
  signal s_axi_awready: std_logic;
  signal s_axi_wdata: std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal s_axi_wstrb: std_logic_vector((C_S_AXI_DATA_WIDTH / 8) - 1 downto 0);
  signal s_axi_wvalid: std_logic;
  signal s_axi_wready: std_logic;
  signal s_axi_bresp: std_logic_vector(1 downto 0);
  signal s_axi_bvalid: std_logic;
  signal s_axi_bready: std_logic;
  signal s_axi_araddr: std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
  signal s_axi_arprot: std_logic_vector(2 downto 0);
  signal s_axi_arready: std_logic;
  signal s_axi_arvalid: std_logic;
  signal s_axi_rdata: std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal s_axi_rresp: std_logic_vector(1 downto 0);
  signal s_axi_rvalid: std_logic;
  signal s_axi_rready: std_logic;
begin

  stimuli_p: process is
  begin
    -- initialize all values of the bus
    s_axi_araddr <= (others => '0');
    s_axi_arprot <= (others => '0');
    s_axi_arvalid <= '0';
    s_axi_rready <= '0';
    s_axi_awaddr <= (others => '0');
    s_axi_awprot <= (others => '0');
    s_axi_awvalid <= '0';
    s_axi_wdata <= (others => '0');
    s_axi_wstrb <= (others => '0');
    s_axi_bready <= '0';
    s_axi_wvalid <= '0';
    -- wait for the bus to become active
    wait until rising_edge(s_axi_aresetn);
    wait for 50 ns;


    -- begin first WRITE TRANSACTION to the set the ps reset flag.
    -- master writes address on the address line and signals validity
    wait until rising_edge(s_axi_aclk);
    s_axi_awaddr <= std_logic_vector(to_unsigned(7*4, C_S_AXI_ADDR_WIDTH));
    wait until rising_edge(s_axi_aclk);
    s_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s_axi_aclk);
    s_axi_wdata <= "00000000000000000000000000000001";
    s_axi_wstrb <= (others => '1');
    s_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s_axi_wready = '0' or s_axi_awready = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s_axi_wvalid <= '0';
    s_axi_awvalid <= '0';
    s_axi_wstrb <= (others => '0');
    s_axi_awaddr <= (others => '0');
    s_axi_wdata <= (others => '0');
    while s_axi_bvalid = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    s_axi_bready <= '1';
    wait until rising_edge(s_axi_aclk);
    s_axi_bready <= '0';
    wait for 100 ns;
    
    
    -- begin first WRITE TRANSACTION to the parameter registers
    -- master writes address on the address line and signals validity
    wait until rising_edge(s_axi_aclk);
    s_axi_awaddr <= std_logic_vector(to_unsigned(4*4, C_S_AXI_ADDR_WIDTH));
    wait until rising_edge(s_axi_aclk);
    s_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s_axi_aclk);
    s_axi_wdata <= "10101010101010101010101010101010";
    s_axi_wstrb <= (others => '1');
    s_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s_axi_wready = '0' or s_axi_awready = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s_axi_wvalid <= '0';
    s_axi_awvalid <= '0';
    s_axi_wstrb <= (others => '0');
    s_axi_awaddr <= (others => '0');
    s_axi_wdata <= (others => '0');
    while s_axi_bvalid = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    s_axi_bready <= '1';
    wait until rising_edge(s_axi_aclk);
    s_axi_bready <= '0';

    wait for 100 ns;
    
    
    -- begin second WRITE TRANSACTION to the parameter registers
    -- master writes address on the address line and signals validity
    wait until rising_edge(s_axi_aclk);
    s_axi_awaddr <= std_logic_vector(to_unsigned(5*4, C_S_AXI_ADDR_WIDTH));
    wait until rising_edge(s_axi_aclk);
    s_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s_axi_aclk);
    s_axi_wdata <= "10101010101010101010101010101010";
    s_axi_wstrb <= (others => '1');
    s_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s_axi_wready = '0' or s_axi_awready = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s_axi_wvalid <= '0';
    s_axi_awvalid <= '0';
    s_axi_wstrb <= (others => '0');
    s_axi_awaddr <= (others => '0');
    s_axi_wdata <= (others => '0');
    while s_axi_bvalid = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    s_axi_bready <= '1';
    wait until rising_edge(s_axi_aclk);
    s_axi_bready <= '0';

    wait for 100 ns;

    
    -- begin third WRITE TRANSACTION to the parameter registers
    -- master writes address on the address line and signals validity
    wait until rising_edge(s_axi_aclk);
    s_axi_awaddr <= std_logic_vector(to_unsigned(6*4, C_S_AXI_ADDR_WIDTH));
    wait until rising_edge(s_axi_aclk);
    s_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s_axi_aclk);
    s_axi_wdata <= "10101010101010101010101010101010";
    s_axi_wstrb <= (others => '1');
    s_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s_axi_wready = '0' or s_axi_awready = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s_axi_wvalid <= '0';
    s_axi_awvalid <= '0';
    s_axi_wstrb <= (others => '0');
    s_axi_awaddr <= (others => '0');
    s_axi_wdata <= (others => '0');
    while s_axi_bvalid = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    s_axi_bready <= '1';
    wait until rising_edge(s_axi_aclk);
    s_axi_bready <= '0';

    
    -- wait a bit unitl writing the reset signal to low
    wait for 500 ns;
    
    --set reset signal low
    -- master writes address on the address line and signals validity
    wait until rising_edge(s_axi_aclk);
    s_axi_awaddr <= std_logic_vector(to_unsigned(7*4, C_S_AXI_ADDR_WIDTH));
    wait until rising_edge(s_axi_aclk);
    s_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s_axi_aclk);
    s_axi_wdata <= "00000000000000000000000000000000";
    s_axi_wstrb <= (others => '1');
    s_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s_axi_wready = '0' or s_axi_awready = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s_axi_wvalid <= '0';
    s_axi_awvalid <= '0';
    s_axi_wstrb <= (others => '0');
    s_axi_awaddr <= (others => '0');
    s_axi_wdata <= (others => '0');
    while s_axi_bvalid = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    s_axi_bready <= '1';
    wait until rising_edge(s_axi_aclk);
    s_axi_bready <= '0';

    
    -- wait a bit and then update the third parameter register
    -- master writes address on the address line and signals validity
    wait until rising_edge(s_axi_aclk);
    s_axi_awaddr <= std_logic_vector(to_unsigned(6*4, C_S_AXI_ADDR_WIDTH));
    wait until rising_edge(s_axi_aclk);
    s_axi_awvalid <= '1';
    -- the master writes the data onto the bus and signals validity of the data
    wait until rising_edge(s_axi_aclk);
    s_axi_wdata <= "11001100110011001100110011001100";
    s_axi_wstrb <= (others => '1');
    s_axi_wvalid <= '1';
    -- the master waits until the slave signals readyness for both data and addr
    while s_axi_wready = '0' or s_axi_awready = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    -- the transfer ends with the deassertion of the valid flags
    s_axi_wvalid <= '0';
    s_axi_awvalid <= '0';
    s_axi_wstrb <= (others => '0');
    s_axi_awaddr <= (others => '0');
    s_axi_wdata <= (others => '0');
    while s_axi_bvalid = '0' loop
      wait until rising_edge(s_axi_aclk);
    end loop;
    s_axi_bready <= '1';
    wait until rising_edge(s_axi_aclk);
    s_axi_bready <= '0';
    wait;
  end process;

  AXI_PS_interface_inst: entity work.AXI_PS_interface
    generic map (
      FRAME_WIDTH         => FRAME_WIDTH,
      FIFO_CNT_WIDTH      => FIFO_CNT_WIDTH,
      FILTER_STATUS_WIDTH => FILTER_STATUS_WIDTH,
      KL_PARAM_WIDTH      => KL_PARAM_WIDTH,
      M_PARAM_WIDTH       => M_PARAM_WIDTH,
      PTHRESH_WIDTH       => PTHRESH_WIDTH,
      ACTIME_WIDTH        => ACTIME_WIDTH,
      C_S_AXI_DATA_WIDTH  => C_S_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH  => C_S_AXI_ADDR_WIDTH
    )
    port map (
      frame               => frame,
      fifo_rd_en          => fifo_rd_en,
      fifo_cnt            => fifo_cnt,
      filter_status       => filter_status,
      param_valid         => param_valid,
      param_updated       => param_updated,
      merged_parameters   => merged_parameters,
      fpga_clk            => fpga_clk,
      system_rst          => system_rst,
      ps_reset            => ps_reset,
      s_axi_aclk          => s_axi_aclk,
      s_axi_aresetn       => s_axi_aresetn,
      s_axi_awaddr        => s_axi_awaddr,
      s_axi_awprot        => s_axi_awprot,
      s_axi_awvalid       => s_axi_awvalid,
      s_axi_awready       => s_axi_awready,
      s_axi_wdata         => s_axi_wdata,
      s_axi_wstrb         => s_axi_wstrb,
      s_axi_wvalid        => s_axi_wvalid,
      s_axi_wready        => s_axi_wready,
      s_axi_bresp         => s_axi_bresp,
      s_axi_bvalid        => s_axi_bvalid,
      s_axi_bready        => s_axi_bready,
      s_axi_araddr        => s_axi_araddr,
      s_axi_arprot        => s_axi_arprot,
      s_axi_arready       => s_axi_arready,
      s_axi_arvalid       => s_axi_arvalid,
      s_axi_rdata         => s_axi_rdata,
      s_axi_rresp         => s_axi_rresp,
      s_axi_rvalid        => s_axi_rvalid,
      s_axi_rready        => s_axi_rready
    );

  clock_p: process is
  begin
    s_axi_aclk <= '0';
    wait for CLK_PERIOD / 2;
    s_axi_aclk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  reset_p: process is
  begin
    s_axi_aresetn <= '0';
    wait for 50 ns;
    wait until rising_edge(s_axi_aclk);
    s_axi_aresetn <= '1';
    wait;
  end process;

end architecture;