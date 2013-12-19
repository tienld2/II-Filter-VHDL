-- Copyright 2009 by Innovative Integration Inc., All Rights Reserved.

-- COMMENTS FOR AUTODOC

--******************************************************************************
--* Design Name: ii_mult_add
--*
--* @li Target device:  xc5vsx95t-1ff1136
--* @li Tool versions:  ISE 10.1
--*
--*     @short 25x18 Multiply Plus 48-Bit Add
--*
--* Description:
--*
--*     result = (mult_a_in * mult_b_in) + add_in
--*
--* Note:
--*   1) the inputs and output are signed 2'S complement numbers.
--*   2) add_in should be applied 1 clock cycle later
--*   3) the output latency is 3 clocks
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 3/25/09
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ii_mult_add is
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
end ii_mult_add;


architecture arch of ii_mult_add is

  signal ce_d      : std_logic;
  signal ce_dd     : std_logic;
  signal a         : std_logic_vector(29 downto 0);


begin

  -- pipeline the enable signal
  process (clk)
  begin
    if (rising_edge(clk)) then
      ce_d  <= ce;
      ce_dd <= ce_d;
      valid <= ce_dd;
    end if;
  end process;

  a <= std_logic_vector(resize(signed(mult_a_in),30));

  -- Instantiate DSP48E
  DSP48E_inst : DSP48E
    generic map (
      ACASCREG                        => 1,
      ALUMODEREG                      => 0,
      AREG                            => 1,
      AUTORESET_PATTERN_DETECT        => FALSE,
      AUTORESET_PATTERN_DETECT_OPTINV => "MATCH",
      A_INPUT                         => "DIRECT",
      BCASCREG                        => 1,
      BREG                            => 1,
      B_INPUT                         => "DIRECT",
      CARRYINREG                      => 0,
      CARRYINSELREG                   => 0,
      CREG                            => 1,
      MASK                            => X"3FFFFFFFFFFF",
      MREG                            => 1,
      MULTCARRYINREG                  => 1,
      OPMODEREG                       => 0,
      PATTERN                         => X"000000000000",
      PREG                            => 1,
      SIM_MODE                        => "SAFE",
      SEL_MASK                        => "MASK",
      SEL_PATTERN                     => "PATTERN",
      SEL_ROUNDING_MASK               => "SEL_MASK",
      USE_MULT                        => "MULT_S",
      USE_PATTERN_DETECT              => "NO_PATDET",
      USE_SIMD                        => "ONE48"
    )
    port map (
      ACOUT                           => open,
      BCOUT                           => open,
      CARRYCASCOUT                    => open,
      CARRYOUT                        => open,
      MULTSIGNOUT                     => open,
      OVERFLOW                        => open,
      P                               => result,
      PATTERNBDETECT                  => open,
      PATTERNDETECT                   => open,
      PCOUT                           => open,
      UNDERFLOW                       => open,
      A                               => a,
      ACIN                            => (others => '0'),
      ALUMODE                         => "0000",
      B                               => mult_b_in,
      BCIN                            => (others => '0'),
      C                               => add_in,
      CARRYCASCIN                     => '0',
      CARRYIN                         => '0',
      CARRYINSEL                      => "000",

      CEA1                            => ce,
      CEA2                            => '1',
      CEALUMODE                       => '1',
      CEB1                            => ce,
      CEB2                            => '1',
      CEC                             => ce_d,
      CECARRYIN                       => '1',
      CECTRL                          => '1',
      CEM                             => ce_d,
      CEMULTCARRYIN                   => '0',
      CEP                             => ce_dd,

      CLK                             => clk,
      MULTSIGNIN                      => '0',
      OPMODE                          => "0110101",
      PCIN                            => (others => '0'),
      RSTA                            => rst,
      RSTALLCARRYIN                   => rst,
      RSTALUMODE                      => rst,
      RSTB                            => rst,
      RSTC                            => rst,
      RSTCTRL                         => rst,
      RSTM                            => rst,
      RSTP                            => rst
    );

end arch;
