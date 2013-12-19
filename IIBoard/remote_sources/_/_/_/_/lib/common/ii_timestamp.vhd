-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_timestamp
--*
--* @li Target Device: generic
--* @li Tool versions: any
--*
--*     @short Timestamp counter
--*
--* Description:
--*
--*   @port clk                : input, reference clock used for counting
--*   @port ce                 : input, sample enable for counting
--*   @port timestamp_run      : input, run the timestamp counter
--*   @port timestamp_timer    : output, the timestamp count
--*   @port timestamp_rollover : output, the timestamp counter rolled over
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 03/19/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_timestamp is
  port (
    clk                  : in  std_logic;
    ce                   : in  std_logic;
    timestamp_run        : in  std_logic;
    timestamp_timer      : out std_logic_vector(31 downto 0):= (others => '0');
    timestamp_rollover   : out std_logic
  );
end ii_timestamp;

architecture arch of ii_timestamp is

  signal ts_timer             : unsigned(31 downto 0) := (others => '0');
  signal ts_timer_msb_d       : std_logic;

begin

  -- timestamp timer
  process (timestamp_run, clk)
  begin
    if (timestamp_run = '0') then
      ts_timer <= (others => '0');
    elsif (rising_edge(clk)) then
      if (ce = '1' and timestamp_run ='1') then
        ts_timer <= ts_timer + 1;
      end if;
    end if;
  end process;

  timestamp_timer <= std_logic_vector(ts_timer);

  -- rollover detection
  process (timestamp_run, clk)
  begin
    if (timestamp_run = '0') then
      timestamp_rollover  <= '0';
      ts_timer_msb_d      <= '0';
    elsif (rising_edge(clk)) then
      ts_timer_msb_d     <= ts_timer(31);
      timestamp_rollover <= ts_timer_msb_d and not ts_timer(31);
    end if;
  end process;

end arch;
