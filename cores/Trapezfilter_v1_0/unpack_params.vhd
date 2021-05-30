library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity unpack_params is
  generic (
    MERGED_PARAM_WIDTH: natural;
    KL_PARAM_WIDTH: natural;
    MUL_CONST_WIDTH: natural;
    PEAK_THRESH_WIDTH: natural;
    EVENT_TIMER_WIDTH: natural
  );
  port (
    -- input from the param cdc
    merged_params: in std_logic_vector(MERGED_PARAM_WIDTH-1 downto 0);
    
    --output to the filter
    adc_sel: out std_logic;
    k: out unsigned(KL_PARAM_WIDTH-1 downto 0);
    l: out unsigned(KL_PARAM_WIDTH-1 downto 0);
    m: out signed(MUL_CONST_WIDTH-1 downto 0);
    peak_filter_thresh: out signed(PEAK_THRESH_WIDTH-1 downto 0);
    event_filter_accum_time: out unsigned(EVENT_TIMER_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of unpack_params is
begin
  adc_sel                  <=          merged_params(k'length + l'length + m'length + peak_filter_thresh'length +
                                                      event_filter_accum_time'length);
  k                        <= unsigned(merged_params(k'length +
                                                      l'length +
                                                      m'length +
                                                      peak_filter_thresh'length +
                                                      event_filter_accum_time'length-1
                                                      downto
                                                      l'length +
                                                      m'length +
                                                      peak_filter_thresh'length +
                                                      event_filter_accum_time'length)); 

  l                        <= unsigned(merged_params(l'length +
                                                      m'length +
                                                      peak_filter_thresh'length +
                                                      event_filter_accum_time'length-1
                                                      downto
                                                      m'length +
                                                      peak_filter_thresh'length +
                                                      event_filter_accum_time'length));

  m                        <= signed(merged_params(m'length +
                                                    peak_filter_thresh'length +
                                                    event_filter_accum_time'length-1
                                                    downto
                                                    peak_filter_thresh'length +
                                                    event_filter_accum_time'length));

  peak_filter_thresh       <= signed(merged_params(peak_filter_thresh'length +
                                                    event_filter_accum_time'length-1
                                                    downto
                                                    event_filter_accum_time'length));
  
  event_filter_accum_time  <= unsigned(merged_params(event_filter_accum_time'length -1 downto 0));
end architecture;