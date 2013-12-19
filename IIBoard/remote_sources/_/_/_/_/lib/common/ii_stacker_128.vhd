-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.

-- COMMENTS FOR AUTODOC

--******************************************************************************
--* Design Name: ii_stacker_128
--*
--* @li Target Device:  any
--* @li Tool versions:  ISE 11.x
--*
--*     @short Stacker ibw-in obw-out
--*
--* Description:
--*
--*   This component generates an obw-bit word output by stacking up n
--*   ibw-bit word input data points, where n = obw/ibn (ratio). This ratio
--*   must be an integer number.
--*   The first input word goes to the low location of the output word and
--*   subsequent words go to the higher locations. ie. little endian.
--*   An output valid is generated after receiving every n input points.
--*   This version also generates an output valid when the din_vld input
--*   deasserts, padding the output word to the full width (128B), and
--*   resetting the next location to the low word.
--*
--*   @port srst            : input, synchronous active high reset
--*   @port clk             : input, sample clock
--*   @port frame           : input, input data frame
--*   @port din_vld         : input, input data ready
--*   @port din             : input, input data (ibw bits)
--*   @port dout_vld        :output, data out is valid
--*   @port dout            :output, data out (128 bits)
--*   @port pad_bytes       :output, amount of padding in bytes for last point
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 03/28/10
--*      @date Modified 06/25/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_stacker_128 is
  generic (
    ibw             : integer;
    obw             : integer
  );
  port (
    srst            : in  std_logic;
    clk             : in  std_logic;

    frame           : in  std_logic;
    din_vld         : in  std_logic;
    din             : in  std_logic_vector(ibw-1 downto 0);

    dout_vld        : out std_logic;
    dout            : out std_logic_vector(obw-1 downto 0);
    pad_bytes       : out std_logic_vector(3 downto 0)
  );
end ii_stacker_128;

architecture arch of ii_stacker_128 is

  constant ratio              : integer := obw/ibw;
  signal sreg                 : std_logic_vector(ratio-1 downto 0);
  signal pad_cnt              : integer range 0 to ratio-1;
  signal frame_d              : std_logic;
  signal frame_fe             : std_logic;
  signal stkr_ip              : std_logic := '0';
  signal full_dout_vld        : std_logic;
  signal partial_dout_vld     : std_logic;
  signal dout_vld_l           : std_logic;

begin

  -- Generate a walking pulse enabled by din_vld and
  -- Route the input data to the appropriate word location depending on sreg
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1' or frame = '0') then
        sreg    <= (others => '0');
        sreg(0) <= '1';
        pad_cnt <= ratio-1;
      elsif (din_vld = '1') then
        sreg <= std_logic_vector(unsigned(sreg) rol 1);
        if (pad_cnt = 0) then
          pad_cnt <= ratio-1;
        else
          pad_cnt <= pad_cnt - 1;
        end if;
        pad_bytes <= std_logic_vector(to_unsigned(pad_cnt*ibw/8,4));
        for i in 0 to ratio-1 loop
          if (sreg = std_logic_vector(to_unsigned(2**i,ratio))) then
            dout(ibw*(i+1)-1 downto ibw*i)   <= din;
            dout(dout'high downto ibw*(i+1)) <= (others => '0');
          end if;
        end loop;
      end if;
    end if;
  end process;

  -- Pipeline frame to look for negedge
  process (clk)
  begin
    if (rising_edge(clk)) then
      frame_d <= frame;
    end if;
  end process;

  frame_fe <= not frame and frame_d;

  -- Don't issue another dout_vld if no new point has come in
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (din_vld = '1') then
        stkr_ip <= '1';
      elsif (dout_vld_l = '1') then
        stkr_ip <= '0';
      end if;
    end if;
  end process;

  -- Generate a valid signal when sreg is highest and din_vld is asserted
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        full_dout_vld <= '0';
      else
        full_dout_vld <= (din_vld and sreg(ratio-1));
      end if;
    end if;
  end process;

  partial_dout_vld <= frame_fe and stkr_ip;

  dout_vld_l <= full_dout_vld or partial_dout_vld;

  dout_vld   <= dout_vld_l;

end arch;

