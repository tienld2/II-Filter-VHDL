-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_mmcm
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.1
--*
--*     @short Parameterized Mixed-Mode Clock Manager
--*
--* Description:
--*
--*   This module calculates various Mixed-Mode Clock Manager (MMCM) parameters
--*   and instantiates an MMCM with these parameters.
--*   These calculations are based on the input and output clock periods
--*   specified in generics and are optimized to yield the closest match.
--*
--*   @port rst_in            : input, Asynchronous active high reset
--*   @port clk_in            : input, clock input
--*   @port clk_out           :output, clock output
--*   @port locked_out        :output, MMCM locked
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date Created 6/1/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

library std;
use std.textio.all;

entity ii_mmcm is
  generic (
    CLKIN_PERIOD      : integer := 5000; -- in ps
    CLKOUT_PERIOD     : integer := 3000  -- in ps
  );
  port (
    rst_in            : in  std_logic;
    clk_in            : in  std_logic;
    clk_out           : out std_logic;
    locked_out        : out std_logic
  );
end ii_mmcm;

architecture arch of ii_mmcm is

  ------------------------------------------------------------------------------
  -- Functions to calculate MMCM parameters
  ------------------------------------------------------------------------------
  function div_rnd_dwn(constant num : in integer; constant den : in integer) return integer is
  begin
    return num/den;
  end function;

  function div_rnd_up(constant num : in integer; constant den : in integer) return integer is
  begin
    return (num+den-1)/den;
  end function;

  -- Calculate MMCM input clock period in nanoseconds
  constant CLKIN_PERIOD_NS  : real := real(CLKIN_PERIOD)/real(1000);  -- in ns

  -- Calculate appropriate MMCM multiplication factor to keep VCO frequency
  -- in allowable range, and at the same time as high as possible in order
  -- to keep output jitter as low as possible
  --   VCO frequency = CLKIN frequency * CLKFBOUT_MULT_F / DIVCLK_DIVIDE

  -- Calculate max MMCM PFD and VCO frequencies - these values are based on
  -- speedgrades. As an appropriximation, assume worst case speed grade
  -- from the input clock frequency (CLKIN_PERIOD). This means that a more
  -- conservative value can be calculated - for example, when a -3 part is
  -- run at 533MHz
  --  For f <= 400MHz (CLKIN_PERIOD >= 2500), use -1 value
  --  For 400MHz < f <= 533MHz (1875 <= CLKIN_PERIOD < 2500), use -2 value
  --  For f > 533.33MHz (CLKIN_PERIOD < 1875), use -3 value

  -- For -1/-2/-3 part, maximum PFD frequency is 450/500/550MHz.
  -- In terms of period, the values are (round up to avoid downstream
  -- rounding issues):
  --   -1: 2223ps (450MHz)
  --   -2: 2000ps (500MHz)
  --   -3: 1819ps (550MHz)
  function CALC_MIN_PFD_PERIOD return integer is
    variable return_value : integer := 2223;
  begin
    if (CLKIN_PERIOD >= 2500) then
      return_value := 2223;
    else
      if (CLKIN_PERIOD < 1875) then
        return_value := 1819;
      else
        return_value := 2000;
      end if;
    end if;
    return return_value;
  end function;
  constant MIN_PFD_PERIOD    : integer := CALC_MIN_PFD_PERIOD;
  constant MAX_PFD_PERIOD    : integer := 100000;

  -- Calculate Dmin (round up to next integer value)
  constant Dmin : integer := div_rnd_up(MIN_PFD_PERIOD,CLKIN_PERIOD);

  -- Calculate Dmax (round down to next integer value)
  constant Dmax : integer := div_rnd_dwn(MAX_PFD_PERIOD,CLKIN_PERIOD);

  -- For -1/-2/-3 part, maximum VCO frequency is 1.2/1.44/1.6GHz
  -- In terms of period, the values are (round up to avoid downstream
  -- rounding issues):
  --   -1: 834ps (1200MHz)
  --   -2: 695ps (1440MHz)
  --   -3: 625ps (1600MHz)
  function CALC_MIN_VCO_PERIOD return integer is
    variable return_value : integer := 834;
  begin
    if (CLKIN_PERIOD >= 2500) then
      return_value := 834;
    else
      if (CLKIN_PERIOD < 1875) then
        return_value := 625;
      else
        return_value := 695;
      end if;
    end if;
    return return_value;
  end function;
  constant MIN_VCO_PERIOD    : integer := CALC_MIN_VCO_PERIOD;
  constant MAX_VCO_PERIOD    : integer := 1667;

  -- Calculate Mmin value and saturate if out of boundary
  function CALC_Mmin return integer is
    variable Mmin : integer := 0;
  begin
    Mmin := integer(ceil(real(Dmin)*(real(CLKIN_PERIOD)/real(MAX_VCO_PERIOD))));
    if (Mmin < 5) then
      return 5;
    else
      return Mmin;
    end if;
  end function;
  constant Mmin    : integer := CALC_Mmin;

  -- Calculate Mmax value and saturate if out of boundary
  function CALC_Mmax return integer is
    variable Mmax : integer := 0;
  begin
    Mmax := integer(floor(real(Dmax)*(real(CLKIN_PERIOD)/real(MIN_VCO_PERIOD))));
    if (Mmax > 64) then
      return 64;
    else
      return Mmax;
    end if;
  end function;
  constant Mmax    : integer := CALC_Mmax;

  -- Calculate Omin (round up to next multiple of 0.125 value)
  constant Omin_f : real := real(CLKOUT_PERIOD)/real(MAX_VCO_PERIOD);
  constant Omin   : real := ceil(Omin_f*8.0)/8.0;

  -- Calculate Omax (round down to next multiple of 0.125 value)
  constant Omax_f : real := real(CLKOUT_PERIOD)/real(MIN_VCO_PERIOD);
  constant Omax   : real := real(floor(Omax_f*8.0))/8.0;

  -- Define a record with all the required parameters
  -- so that a function can be used later on to calculate
  -- these parameters and return the record type output
  type mmcm_param is record
    err : real;
    m   : integer;
    d   : integer;
    o   : real;
  end record mmcm_param;

  -- Search for the best possible match
  function CALC_mmcm_param return mmcm_param is
    variable Omin_x8 : integer;
    variable Omax_x8 : integer;
    variable o       : real;
    variable skip    : boolean := false;
    variable err     : real;
    variable params  : mmcm_param;
  begin
    Omin_x8 := integer(Omin * 8.0);
    Omax_x8 := integer(Omax * 8.0);
    params.err := 100.0;  -- just a max initial value
    L1: for d in Dmin to Dmax loop
      L2: for m in Mmax downto Mmin loop
        skip := ((real(m)/real(d)) < (real(CLKIN_PERIOD)/real(MAX_VCO_PERIOD))) or
        ((real(m)/real(d)) > (real(CLKIN_PERIOD)/real(MIN_VCO_PERIOD)));
        next L2 when skip;
        L3: for Ox8 in Omin_x8 to Omax_x8 loop
          o := real(Ox8)/8.0;
          err := (real(m)/(real(CLKIN_PERIOD)*real(d) * o)) - (1.0/real(CLKOUT_PERIOD));
          if (abs(err) < abs(params.err)) then
            params.err := err;
            params.m   := m;
            params.d   := d;
            params.o   := o;
          end if;
          exit L1 when (err = 0.0);
        end loop;
      end loop;
    end loop;
    return params;
  end function;
  constant params : mmcm_param := CALC_mmcm_param;

  ------------------------------------------------------------------------------
  -- Procedures to print messages to stdout
  ------------------------------------------------------------------------------
  --synthesis translate_off
  procedure print(s : in string) is
    variable l: line;
  begin
    write(l, now);
    write(l, string'("  "));
    write(l, s);
    writeline(output,l);
  end print;

  procedure print(s : in string; int : in integer) is
    variable l: line;
  begin
    write(l, now);
    write(l, string'("  "));
    write(l, s);
    write(l, int);
    writeline(output,l);
  end print;

  procedure print(s : in string; rl : in real) is
    variable l: line;
  begin
    write(l, now);
    write(l, string'("  "));
    write(l, s);
    write(l, rl);
    writeline(output,l);
  end print;
  --synthesis translate_on

  ------------------------------------------------------------------------------
  -- Signal definitions
  ------------------------------------------------------------------------------
  signal clkfbout          : std_logic;
  signal clkout0           : std_logic;
  signal clkout0_bufg      : std_logic;
  signal locked            : std_logic;
  signal locked_sreg       : std_logic_vector(2 downto 0);

begin

--------------------------------------------------------------------------------
-- MMCM instance
--------------------------------------------------------------------------------
  u_mmcm_adv : MMCM_ADV
  generic map (
    BANDWIDTH             => "OPTIMIZED",
    CLOCK_HOLD            => FALSE,
    COMPENSATION          => "ZHOLD",
    REF_JITTER1           => 0.005,
    REF_JITTER2           => 0.005,
    STARTUP_WAIT          => FALSE,

    CLKIN1_PERIOD         => CLKIN_PERIOD_NS,
    CLKIN2_PERIOD         => 10.000,

    CLKFBOUT_MULT_F       => real(params.m),
    DIVCLK_DIVIDE         => params.d,

    CLKFBOUT_PHASE        => 0.000,
    CLKFBOUT_USE_FINE_PS  => FALSE,

    CLKOUT0_DIVIDE_F      => params.o,
    CLKOUT0_DUTY_CYCLE    => 0.500,
    CLKOUT0_PHASE         => 0.000,
    CLKOUT0_USE_FINE_PS   => FALSE,

    CLKOUT1_DIVIDE        => 1,
    CLKOUT1_DUTY_CYCLE    => 0.500,
    CLKOUT1_PHASE         => 0.000,
    CLKOUT1_USE_FINE_PS   => FALSE,

    CLKOUT2_DIVIDE        => 1,
    CLKOUT2_DUTY_CYCLE    => 0.500,
    CLKOUT2_PHASE         => 0.000,
    CLKOUT2_USE_FINE_PS   => TRUE,

    CLKOUT3_DIVIDE        => 1,
    CLKOUT3_DUTY_CYCLE    => 0.500,
    CLKOUT3_PHASE         => 0.000,
    CLKOUT3_USE_FINE_PS   => FALSE,

    CLKOUT4_CASCADE       => FALSE,
    CLKOUT4_DIVIDE        => 1,
    CLKOUT4_DUTY_CYCLE    => 0.500,
    CLKOUT4_PHASE         => 0.000,
    CLKOUT4_USE_FINE_PS   => FALSE,

    CLKOUT5_DIVIDE        => 1,
    CLKOUT5_DUTY_CYCLE    => 0.500,
    CLKOUT5_PHASE         => 0.000,
    CLKOUT5_USE_FINE_PS   => FALSE,

    CLKOUT6_DIVIDE        => 1,
    CLKOUT6_DUTY_CYCLE    => 0.500,
    CLKOUT6_PHASE         => 0.000,
    CLKOUT6_USE_FINE_PS   => FALSE
  )
  port map (
    CLKFBOUT              => clkfbout,
    CLKFBOUTB             => open,
    CLKFBSTOPPED          => open,
    CLKINSTOPPED          => open,
    CLKOUT0               => clkout0,
    CLKOUT0B              => open,
    CLKOUT1               => open,
    CLKOUT1B              => open,
    CLKOUT2               => open,
    CLKOUT2B              => open,
    CLKOUT3               => open,
    CLKOUT3B              => open,
    CLKOUT4               => open,
    CLKOUT5               => open,
    CLKOUT6               => open,
    DO                    => open,
    DRDY                  => open,
    LOCKED                => locked,
    PSDONE                => open,
    CLKFBIN               => clkfbout,
    CLKIN1                => clk_in,
    CLKIN2                => '0',
    CLKINSEL              => '1',
    DADDR                 => (others => '0'),
    DCLK                  => '0',
    DEN                   => '0',
    DI                    => x"0000",
    DWE                   => '0',
    PSCLK                 => '0',
    PSEN                  => '0',
    PSINCDEC              => '0',
    PWRDWN                => '0',
    RST                   => rst_in
  );

  u_bufg_clkout0 : BUFG
  port map (
    O => clkout0_bufg,
    I => clkout0
  );

  clk_out <= clkout0_bufg;

--------------------------------------------------------------------------------
-- MMCM Lock logic
--------------------------------------------------------------------------------
  process (rst_in, clkout0_bufg)
  begin
    if (rst_in = '1') then
      locked_sreg <= (others => '0');
    elsif (rising_edge(clkout0_bufg)) then
      locked_sreg <= locked_sreg(1 downto 0) & locked;
    end if;
  end process;

  locked_out <= locked_sreg(locked_sreg'high);

--------------------------------------------------------------------------------
-- Debug
--------------------------------------------------------------------------------
  --synthesis translate_off
  process
  begin
    print ("----------------------------------------------");
    print ("CLKIN_PERIOD = ", CLKIN_PERIOD);
    print ("CLKOUT_PERIOD = ", CLKOUT_PERIOD);
    print ("----------------------------------------------");
    print ("Input Divider Calculations");
    print ("MIN_PFD_PERIOD = ", MIN_PFD_PERIOD);
    print ("MAX_PFD_PERIOD = ", MAX_PFD_PERIOD);
    print ("Dmin = ", Dmin);
    print ("Dmax = ", Dmax);
    print ("----------------------------------------------");
    print ("VCO Feedback Divider Calculations");
    print ("Mmin = ", Mmin);
    print ("Mmax = ", Mmax);
    print ("----------------------------------------------");
    print ("Output Divider Calculations");
    print ("Omin_f = ", Omin_f);
    print ("Omin = ", Omin);
    print ("Omax_f = ", Omax_f);
    print ("Omax = ", Omax);
    print ("----------------------------------------------");
    print ("Error = ", params.err);
    print ("M = ", params.m);
    print ("D = ", params.d);
    print ("O = ", params.o);
    wait;
  end process;
  --synthesis translate_on

end arch;
