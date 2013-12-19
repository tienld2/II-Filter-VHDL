-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_unsign_sat
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short Unsigned saturation
--*
--* Description:
--*
--*   This component saturates an unsigned input to obw bits.
--*   Saturation is done combinatorially, by comparing the MSBs of the input.
--*
--*   @generic ibw    : input bit width
--*   @generic obw    : output bit width
--*   @port i         : input, data in
--*   @port o         :output, saturated data
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 11/10/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;

entity ii_unsign_sat is
  generic (
    ibw         : integer;
    obw         : integer
  );
  port (
    i           : in  std_logic_vector(ibw-1 downto 0);
    o           : out std_logic_vector(obw-1 downto 0)
  );
end ii_unsign_sat;


architecture arch of ii_unsign_sat is

  constant all_zeros : std_logic_vector(ibw-1 downto obw) := (others => '0');
  constant all_ones  : std_logic_vector(obw-1 downto 0)   := (others => '1');

begin

  -- this is done by comparing the MSBs of the input and the output
  -- if any input bit in the range of (ibw-1 downto obw) is set, then the
  -- output is saturated to all ones, else if all these bits are zeros, then
  -- just drop the MSBs
  process (i)
  begin
      if (i(ibw-1 downto obw) = all_zeros) then -- don't saturate
        o <= i(obw-1 downto 0);
      else
        o <= all_ones;
      end if;
  end process;

end arch;
