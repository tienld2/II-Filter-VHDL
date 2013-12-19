-- Copyright 2008 by Innovative Integration Inc., All Rights Reserved.

-- COMMENTS FOR AUTODOC

--*****************************************************************************
--* Design Name: ii_xdom_pulse
--*
--* @li Target Device:  any
--* @li Tool versions:  ISE 10.1
--*
--*     @short Clock Domain Crossing Logic
--*
--* Description:
--*
--*   This component generates a pulse on the destination clock domain
--*   whenever it receives a pulse on the source clock domain.
--*
--*   @port src_clk         : input, source clock
--*   @port pls_i           : input, input pulse on source clock domain
--*   @port dst_clk         : input, destination clock
--*   @port pls_o           :output, output pulse on destination clock domain
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 11/14/08
--*
--*****************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;

entity ii_xdom_pulse is
  port (
    src_clk              : in  std_logic;
    pls_i                : in  std_logic;
    dst_clk              : in  std_logic;
    pls_o                : out std_logic
  );
end ii_xdom_pulse;

architecture xdom_arch of ii_xdom_pulse is

  signal pls_i_tog            : std_logic := '0';
  signal pls_i_tog_xdom       : std_logic;
  signal pls_i_tog_demet      : std_logic;
  signal pls_i_tog_demet_d    : std_logic;

begin

  -- toggle a line with every input pulse @src_clk
  process (src_clk)
  begin
    if (rising_edge(src_clk)) then
      if (pls_i = '1') then
        pls_i_tog <= not pls_i_tog;
      end if;
    end if;
  end process;

  -- Sync pls_i_tog to dst_clk domain and detect any transitions on it
  process (dst_clk)
  begin
    if (rising_edge(dst_clk)) then
      pls_i_tog_xdom    <= pls_i_tog;
      pls_i_tog_demet   <= pls_i_tog_xdom;
      pls_i_tog_demet_d <= pls_i_tog_demet;
      pls_o             <= pls_i_tog_demet xor pls_i_tog_demet_d;
    end if;
  end process;

end architecture;
