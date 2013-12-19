-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_alert_gen
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short Alert generator (conditioner)
--*
--* Description:
--*
--*   This component generates an alert strobe and latches the input alert
--*   bus for 4 cycles when any input alert occurs.
--*
--*   @port srst               : input, synchronous active high reset
--*   @port sys_clk            : input, system clock
--*   @port alert_din          : input, alert data in
--*   @port alert_strb         :output, alert strobe
--*   @port alert_dout         :output, alert data out
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 07/09/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;

entity ii_alert_gen is
  generic (
    width                : integer := 16
  );
  port (
    -- Reset and clock
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;

    -- Input alerts
    alert_din            : in  std_logic_vector(width-1 downto 0);

    -- Output alert
    alert_strb           : out std_logic;
    alert_dout           : out std_logic_vector(width-1 downto 0)
  );
end ii_alert_gen;

architecture arch of ii_alert_gen is

  signal alert_din_1s         : std_logic_vector(width-1 downto 0);
  signal alert_din_2s         : std_logic_vector(width-1 downto 0);
  signal alert_din_re_2s      : std_logic_vector(width-1 downto 0);
  signal alert_strb_2s        : std_logic;

  constant do_width           : integer := 4;
  subtype dly_sreg_width is std_logic_vector(do_width-1 downto 0);
  type dly_sreg_type is array (width-1 downto 0) of dly_sreg_width;
  signal sreg                 : dly_sreg_type;

begin

  gen_alert_loop: for i in 0 to width-1 generate
    -- Pipeline and detect a rising edge on each input
    process (sys_clk)
    begin
      if (rising_edge(sys_clk)) then
        if (srst = '1') then
          alert_din_1s(i)    <= '0';
          alert_din_2s(i)    <= '0';
          alert_din_re_2s(i) <= '0';
        else
          alert_din_1s(i)    <= alert_din(i);
          alert_din_2s(i)    <= alert_din_1s(i);
          alert_din_re_2s(i) <= not alert_din_2s(i) and alert_din_1s(i);
        end if;
      end if;
    end process;

    -- On a rising edge of an alert, latch it into a shift register
    process (sys_clk)
    begin
      if (rising_edge(sys_clk)) then
        if (srst = '1') then
          sreg(i) <= (others => '0');
        elsif (alert_din_re_2s(i) = '1') then
          sreg(i) <= (others => '1');
        else
          sreg(i) <= sreg(i)(do_width-2 downto 0) & alert_din_2s(i);
        end if;
      end if;
    end process;

    -- Pass the final stage of the shift register to the output
    alert_dout(i) <= sreg(i)(do_width-1);
  end generate;

  -- Reduction OR
  process (alert_din_re_2s)
    variable tmp : std_logic;
  begin
    tmp := '0';
    for i in alert_din_re_2s'range loop
      tmp := alert_din_re_2s(i) or tmp;
    end loop;
    alert_strb_2s <= tmp;
  end process;

  -- Generate the output alert strobe
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        alert_strb <= '0';
      else
        alert_strb <= alert_strb_2s;
      end if;
    end if;
  end process;

end arch;
