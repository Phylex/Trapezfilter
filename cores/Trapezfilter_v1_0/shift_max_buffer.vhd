library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use IEEE.std_logic_misc.all;

ENTITY max_shift_array is
  Generic( packet_width : natural := 32;
           buffer_depth : natural := 10;
           eval_max_left : natural :=31;
           eval_max_right : natural := 15
         );
  Port(
    -- control input
    signal rst : in std_logic;
    signal shift : in std_logic;
    
    -- data input
    signal packet_in : in std_logic_vector(packet_width-1 downto 0);
    
    -- output
    signal max_packet : out std_logic_vector(packet_width-1 downto 0)
  );
END max_shift_array;

ARCHITECTURE msa of max_shift_array is
  SUBTYPE packet is std_logic_vector(packet_width-1 downto 0);
  TYPE packet_bfr is ARRAY(0 to buffer_depth-1) of packet;
  signal pbfr : packet_bfr;
BEGIN
  
  -- determin the maximum of the packets in the buffer asynchronously
  determin_max : PROCESS (pbfr)
    variable max_ind : natural range 0 to buffer_depth-1 := 0;
  BEGIN
    max_ind := 0;
    for i in 1 to buffer_depth-1 loop
      if signed(pbfr(max_ind)(eval_max_left downto eval_max_right)) < signed(pbfr(i)(eval_max_left downto eval_max_right)) then
        max_ind := i;
      end if;
    end loop;
    max_packet <= pbfr(max_ind);
  END PROCESS;
  
  -- reset and shift process
  reset_and_shift_p : PROCESS (shift, rst)
  BEGIN
    if rst = '1' then
      pbfr <= (others => packet'(others => '0'));
    elsif rising_edge(shift) then
      pbfr <= packet_in & pbfr(0 to buffer_depth-2);
    end if;
  END PROCESS;
END msa; 