-- Copyright 2007 by Innovative Integration Inc., All Rights Reserved.

-- COMMENTS FOR AUTODOC

--* *************************************************************************
--* Design Name: ii_offgain
--*
--* @li Target Device:  xc5vsx95t-1ff1136
--* @li Tool versions:  ISE 10.1
--*
--*     @short Offset/Gain Correction
--*
--* Description:
--*
--*   This component applies gain/offset error correction coefficients to the
--*   incoming samples to produce compensated samples of (obw) bit width.
--*   This block has a latency of 8 cycles.
--*
--*   gain range : -2 to +2
--*        gain of +1 = 0x10000
--*
--*   @port srst     : input, synchronous active high reset
--*   @port clk      : input, sample clock
--*   @port gain     : input, gain correction coefficient (2's complement)
--*   @port offset   : input, offset correction coefficient (2's complement)
--*   @port ce       : input, process enable
--*   @port din      : input, data in
--*   @port data_vld :output, data ready at dout
--*   @port dout     :output, data out
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 4/18/07
--*
--* *************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ii_offgain is
  generic (
    obw             : integer := 16
  );
  port (
    srst            : in  std_logic;
    clk             : in  std_logic;

    gain            : in  std_logic_vector(17 downto 0);
    offset          : in  std_logic_vector(15 downto 0);

    ce              : in  std_logic;
    din             : in  std_logic_vector(15 downto 0);

    data_vld        : out std_logic;
    dout            : out std_logic_vector(obw-1 downto 0)
  );
end ii_offgain;


architecture arch of ii_offgain is

  component ii_mult_add
    port (
      rst        : in  std_logic;
      clk        : in  std_logic;
      ce         : in  std_logic;
      mult_a_in  : in  std_logic_vector(24 downto 0);
      mult_b_in  : in  std_logic_vector(17 downto 0);
      add_in     : in  std_logic_vector(47 downto 0);
      valid      : out std_logic;
      result     : out std_logic_vector(47 downto 0)
    );
  end component;

  component ii_sign_sat
    generic (
      ibw        : integer;
      obw        : integer
    );
    port (
      i          : in  std_logic_vector(ibw-1 downto 0);
      o          : out std_logic_vector(obw-1 downto 0)
    );
  end component;

  signal din_shifted   : std_logic_vector(24 downto 0);
  signal offset_shifted: std_logic_vector(40 downto 0);
  signal offset_sext   : std_logic_vector(47 downto 0);
  signal mult_add_vld  : std_logic;
  signal raw_result    : std_logic_vector(47 downto 0);
  signal result_rnd    : signed(19 downto 0);
  signal result_sat    : std_logic_vector(obw-1 downto 0);
  signal mult_add_vld_d: std_logic;

begin

-- Data Flow:
-- din is multiplied by the gain coefficient first then the offset
-- coefficient is added
-- finally, the product is rounded and saturated to the proper format

  -- Extend the inputs of the multiply add unit to the proper size and format
  din_shifted    <= din & "000000000";        -- to make it 25 bits
  offset_shifted <= offset & '0' & x"000000"; -- to match the multiplier output RHS
  offset_sext    <= std_logic_vector(resize(signed(offset_shifted),48));

  -- Instantiate multiply add unit
  mult_add_inst : ii_mult_add
    port map (
      rst        => srst,
      clk        => clk,
      ce         => ce,
      mult_a_in  => din_shifted,  -- <1.24>S
      mult_b_in  => gain,         -- <2.16>S
      add_in     => offset_sext,  -- <8.40>S
      valid      => mult_add_vld,
      result     => raw_result    -- <8.40>S
    );

  -- drop 4MSBs from raw_result since its guaranteed the full
  -- precision raw_result can be covered with <4.40>S format
  -- also round raw_result by 25 bits, sign extend raw_result
  -- to avoid getting an overflow when adding an LSB
  process (clk)
  begin
    if (rising_edge(clk)) then
      result_rnd <= signed(raw_result(43) & raw_result(43 downto 25)) +
                    signed('0' & raw_result(24 downto 24));
    end if;
  end process;

  sat_inst : ii_sign_sat
    generic map (
      ibw        => 20,
      obw        => obw
    )
    port map (
      i          => std_logic_vector(result_rnd),
      o          => result_sat
    );

  -- generate data valid output
  process (clk)
  begin
    if (rising_edge(clk)) then
      dout           <= result_sat;
      mult_add_vld_d <= mult_add_vld;
      data_vld       <= mult_add_vld_d;
    end if;
  end process;

end arch;
