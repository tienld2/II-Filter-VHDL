-- Copyright 2008 by Innovative Integration Inc., All Rights Reserved.

-- COMMENTS FOR AUTODOC

--******************************************************************************
--* Design Name: ii_fifo_drainer
--*
--* @li Target Device:  any
--* @li Tool versions:  ISE 10.1
--*
--*     @short FIFO drainer
--*
--* Description:
--*
--*   This component moves (drains) data from a source fifo in two modes; bleed
--*   and drip; whenever a destination is ready.
--*
--*
--*   @port srst            : input, synchronous active high reset
--*   @port clk             : input, sample clock
--*   @port ce              : input, chip en
--*   @port src_empty       : input, source fifo empty
--*   @port src_aempty      : input, source fifo almost empty
--*   @port dest_rdy        : input, destination ready
--*   @port src_rden        :output, source fifo read enable
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 8/21/08
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ii_fifo_drainer is
  port (
    srst            : in  std_logic;
    clk             : in  std_logic;
    ce              : in  std_logic;

    src_empty       : in  std_logic;
    src_aempty      : in  std_logic;
    dest_rdy        : in  std_logic;

    src_rden        : out std_logic
  );
end ii_fifo_drainer;

architecture arch of ii_fifo_drainer is

  signal dly_cnt              : std_logic_vector(2 downto 0);

begin

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        src_rden <= '0';
        dly_cnt  <= (others => '0');
      else
        if (ce = '1' and dest_rdy = '1' and src_empty = '0' and
            (src_aempty = '0' or dly_cnt = "000")) then
          src_rden <= '1';
          dly_cnt  <= "100";
        else
          src_rden <= '0';
          if (dly_cnt /= "000") then
            dly_cnt <= dly_cnt - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

end arch;
