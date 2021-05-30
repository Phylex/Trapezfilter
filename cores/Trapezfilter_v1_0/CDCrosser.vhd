library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity CDCrosser is
  generic ( 
    DATA_WIDTH: natural
  );
  port (
    -- the data travels from sender to reciever
    sender_clk: in  std_logic;
    din:  in  std_logic_vector(DATA_WIDTH-1 downto 0);
    valid_strobe: in std_logic;
    transfered: out std_logic;
    rst: in std_logic;
    reciever_clk: in  std_logic;
    dout: out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of CDCrosser is
  signal captured_data:  std_logic_vector(DATA_WIDTH-1 downto 0);
  signal valid:          std_logic;
  signal valid_1:        std_logic;
  signal valid_syncd:    std_logic;
  signal ack:            std_logic;
  signal ack_1:          std_logic;
  signal ack_transfered: std_logic;
begin
  sync_valid_and_data_with_reciever: process ( reciever_clk )
  begin
    if rising_edge(reciever_clk) then
      if rst = '1' then
        valid_1 <= '0';
        valid_syncd <= '0';
        captured_data <= (others => '0');
        ack <= '0';
      else        
        valid_1 <= valid;
        valid_syncd <= valid_1;
        if valid_syncd = '1' then
          captured_data <= din;
          ack <= '1';
        else
          ack <= '0';
        end if;
      end if;
    end if;
  end process;
  dout <= captured_data;
  
  sync_ack_with_sender: process ( sender_clk )
  begin
    if rising_edge( sender_clk ) then
      if rst = '1' then
        ack_1 <= '0';
        ack_transfered <= '0';
        valid <= '0';
      else
        ack_1 <= ack;
        ack_transfered <= ack_1;
        -- we have to lower the valid flag to allow for another process. 
        if ack_transfered = '1' then
          valid <= '0';
        end if;
        if valid = '0' and ack_transfered = '0' and valid_strobe = '1' then
          valid <= '1';
        end if;
      end if;
    end if;
  end process;
  transfered <= ack_transfered;

end architecture;