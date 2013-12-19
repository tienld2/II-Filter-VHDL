-- Copyright 2007 by Innovative Integration Inc., All Rights Reserved.

-- COMMENTS FOR AUTODOC

--* *************************************************************************
--* Design Name: ii_sign_sat
--*
--* @li Target Device:  xc5vsx95t-1ff1136
--* @li Tool versions:  ISE 10.1
--*
--*     @short Signed saturation
--*
--* Description:
--*
--*   This component saturates an input to obw bits.
--*   Saturation is done combinatorially, by comparing the MSBs of the input.
--*
--*   @generic ibw    : input bit width
--*   @generic obw    : output bit width
--*   @port i         : input, data in
--*   @port o         : output, saturated data
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 9/15/08
--*
--* *************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;

entity ii_sign_sat is
  generic (
    ibw         : integer;
    obw         : integer
  );
  port (
    i           : in  std_logic_vector(ibw-1 downto 0);
    o           : out std_logic_vector(obw-1 downto 0)
  );
end ii_sign_sat;


architecture arch of ii_sign_sat is

  constant all_zeros : std_logic_vector(ibw-1 downto obw-1) := (others => '0');
  constant all_ones  : std_logic_vector(ibw-1 downto obw-1) := (others => '1');

begin

-----------------------------------------------------------------------------

  -- this is done by comparing the MSBs of the input and the output
  -- if they are identical, then just drop the MSBs 
  -- else if the MSB is 1 then saturate to the max neg value, else
  -- if the MSB is 0 then saturate to the max positive value
  process (i)
  begin
      if (i(ibw-1 downto obw-1) = all_ones or
          i(ibw-1 downto obw-1) = all_zeros) then -- don't saturate
        o <= i(obw-1 downto 0);
      else
        o(obw-1) <= i(ibw-1);                     -- output has same sign
        o(obw-2 downto 0) <= (others => not i(ibw-1));
      end if;
  end process;

-----------------------------------------------------------------------------

end arch;
