-- Copyright 2009 by Innovative Integration Inc., All Rights Reserved.

-- COMMENTS FOR AUTODOC

--******************************************************************************
--* Design Name: ii_trig_alert
--*
--* @li Target Device:  any
--* @li Tool versions:  ISE 11.2
--*
--*     @short Trigger alert generator
--*
--* Description:
--*
--*   This module detects a rising edge on the incoming trigger and sets and
--*   latches the output on the first detected edge.
--*
--*   @port rst_sys_clk       : input, Synchronous active high reset @sys_clk domain
--*   @port sys_clk           : input, system clock
--*   @port rst_fs_clk        : input, Synchronous active high reset @fs_clk domain
--*   @port fs_clk            : input, FS clock
--*   @port trig_in           : input, trigger @fs_clk domain
--*   @port trig_alert        :output, latched trigger alert
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date Created 11/17/09
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;

entity ii_trig_alert is
  port (
    rst_sys_clk       : in  std_logic;
    sys_clk           : in  std_logic;
    rst_fs_clk        : in  std_logic;
    fs_clk            : in  std_logic;
    trig_in           : in  std_logic;
    trig_alert        : out std_logic
  );
end ii_trig_alert;


architecture arch of ii_trig_alert is

 signal trig_in_d         : std_logic;
 signal trig_in_re        : std_logic;
 signal trig_latched      : std_logic;
 signal trig_latched_xdom : std_logic;

begin

  -- detect a rising edge on trig_in @fs_clk domain
  process (fs_clk)
  begin
    if (rising_edge(fs_clk)) then
      trig_in_d <= trig_in;
    end if;
  end process;

  trig_in_re <= not trig_in_d and trig_in;

  -- generate trigger latch level signal @fs_clk domain
  -- on the first rising edge of trigger after a reset
  process (fs_clk)
  begin
    if (rising_edge(fs_clk)) then
      if (rst_fs_clk = '1') then
        trig_latched <= '0';
      elsif (trig_in_re = '1') then
        trig_latched <= '1';
      end if;
    end if;
  end process;

  -- Sync trig_latched level signal to sys_clk domain
  -- and generate trig_alert level signal for alert
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (rst_sys_clk = '1') then
        trig_latched_xdom <= '0';
        trig_alert        <= '0';
      else
        trig_latched_xdom <= trig_latched;
        trig_alert        <= trig_latched_xdom;
      end if;
    end if;
  end process;

end arch;
