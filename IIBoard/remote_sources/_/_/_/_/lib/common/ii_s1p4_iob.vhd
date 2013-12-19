-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_s1p4_iob
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.3
--*
--*     @short Serial to Parallel converter
--*
--* Description:
--*
--*   This module converts the differential serial input into parallel
--*   output using an IBUFDS, IODELAY, and ISERDES elements.
--*
--*
--*   @port srst            : input, synchronous active high reset pulse
--*                                  @clk_div2 domain
--*   @port clk             : input, clock
--*   @port clk_180         : input, inverse of the clock
--*   @port clk_div2        : input, clock divided by 2
--*   @port iodly_rst       : input, iodelay reset
--*   @port iodly_ce        : input, iodelay enable inc/dec tap delay
--*   @port iodly_inc       : input, iodelay increment/decrement tap delay
--*   @port iodly_init_cnt  : input, iodelay initial tap count
--*   @port iodly_cnt       :output, iodelay tap count
--*   @port bitslip         : input, bitslip the ISERDES output
--*   @port din_p           : input, serial data in differential pair (side-P)
--*   @port din_n           : input, serial data in differential pair (side-N)
--*   @port dout            :output, parallel data out (4 bits)
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 11/22/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ii_s1p4_iob is
  generic (
    USE_ISERDES_BITSLIP  : boolean := TRUE;
    DIFF_TERM            : boolean := TRUE;
    IOSTANDARD           : string  := "LVDS_25"
  );
  port (
    -- Reset and clocks
    srst                 : in  std_logic;
    clk                  : in  std_logic;
    clk_180              : in  std_logic;
    clk_div2             : in  std_logic;

    -- IODELAY control and status
    iodly_rst            : in  std_logic;
    iodly_ce             : in  std_logic;
    iodly_inc            : in  std_logic;
    iodly_init_cnt       : in  std_logic_vector(4 downto 0);
    iodly_cnt            : out std_logic_vector(4 downto 0);
    bitslip              : in  std_logic;

    -- Serial data input
    din_p                : in  std_logic;
    din_n                : in  std_logic;

    -- Parallel data output
    dout                 : out std_logic_vector(3 downto 0)
  );
end ii_s1p4_iob;


architecture arch of ii_s1p4_iob is

  signal din_ibufds           : std_logic;
  signal din_idelay           : std_logic;
  signal iserdes_bitslip      : std_logic;
  signal bitslip_cnt          : integer range 0 to 4;
  signal iserdes_do           : std_logic_vector(3 downto 0);
  signal iserdes_do_d         : std_logic_vector(3 downto 0);

begin

  -- Convert differential din to single ended
  -- From PAD to IBUFDS
  IBUFDS_inst : IBUFDS
    generic map (
      DIFF_TERM            => DIFF_TERM,
      IOSTANDARD           => IOSTANDARD
    )
    port map (
      I                    => din_p,
      IB                   => din_n,
      O                    => din_ibufds
    );

  -- Delay the input data through an IODELAY
  IODELAY_inst : IODELAYE1
    generic map (
      CINVCTRL_SEL         => FALSE,
      DELAY_SRC            => "I",
      HIGH_PERFORMANCE_MODE=> TRUE,
      IDELAY_TYPE          => "VAR_LOADABLE",
      IDELAY_VALUE         => 0,
      ODELAY_TYPE          => "FIXED",
      ODELAY_VALUE         => 0,
      REFCLK_FREQUENCY     => 200.0,
      SIGNAL_PATTERN       => "DATA"
    )
    port map (
      CNTVALUEOUT          => iodly_cnt,
      DATAOUT              => din_idelay,
      C                    => clk_div2,
      CE                   => iodly_ce,
      CINVCTRL             => '0',
      CLKIN                => 'Z',
      CNTVALUEIN           => iodly_init_cnt,
      DATAIN               => 'Z',
      IDATAIN              => din_ibufds,
      INC                  => iodly_inc,
      ODATAIN              => 'Z',
      RST                  => iodly_rst,
      T                    => '1'
    );

  -- Deserialize using an ISERDES
  ISERDESE1_inst : ISERDESE1
    generic map (
      DATA_RATE            => "DDR",
      DATA_WIDTH           => 4,
      DYN_CLKDIV_INV_EN    => FALSE,
      DYN_CLK_INV_EN       => FALSE,
      INIT_Q1              => '0',
      INIT_Q2              => '0',
      INIT_Q3              => '0',
      INIT_Q4              => '0',
      INTERFACE_TYPE       => "NETWORKING",
      IOBDELAY             => "IFD",
      NUM_CE               => 1,
      OFB_USED             => FALSE,
      SERDES_MODE          => "MASTER",
      SRVAL_Q1             => '0',
      SRVAL_Q2             => '0',
      SRVAL_Q3             => '0',
      SRVAL_Q4             => '0'
    )
    port map (
      O                    => open,
      Q1                   => iserdes_do(3),
      Q2                   => iserdes_do(2),
      Q3                   => iserdes_do(1),
      Q4                   => iserdes_do(0),
      Q5                   => open,
      Q6                   => open,
      SHIFTOUT1            => open,
      SHIFTOUT2            => open,
      BITSLIP              => iserdes_bitslip,
      CE1                  => '1',
      CE2                  => '0',
      CLK                  => clk,
      CLKB                 => clk_180,
      CLKDIV               => clk_div2,
      D                    => '0',
      DDLY                 => din_idelay,
      DYNCLKDIVSEL         => '0',
      DYNCLKSEL            => '0',
      OCLK                 => '0',
      OFB                  => '0',
      RST                  => srst,
      SHIFTIN1             => '0',
      SHIFTIN2             => '0'
    );

  gen_iserdes_bitslip : if (USE_ISERDES_BITSLIP = TRUE) generate
    iserdes_bitslip <= bitslip;
    dout            <= iserdes_do;
  end generate;

  gen_logic_bitslip : if (USE_ISERDES_BITSLIP /= TRUE) generate
    iserdes_bitslip <= '0';

    -- Count the bitslips and use it to select the output samples
    process (clk_div2)
    begin
      if (rising_edge(clk_div2)) then
        if (srst = '1') then
          bitslip_cnt <= 0;
        elsif (bitslip = '1') then
          if (bitslip_cnt = 4) then
            bitslip_cnt <= 0;
          else
            bitslip_cnt <= bitslip_cnt + 1;
          end if;
        end if;
      end if;
    end process;

    process (clk_div2)
    begin
      if (rising_edge(clk_div2)) then
        iserdes_do_d <= iserdes_do;
        case bitslip_cnt is
          when 0 => dout <= iserdes_do_d;
          when 1 => dout <= iserdes_do(0) & iserdes_do_d(3 downto 1);
          when 2 => dout <= iserdes_do(1 downto 0) & iserdes_do_d(3 downto 2);
          when 3 => dout <= iserdes_do(2 downto 0) & iserdes_do_d(3);
          when 4 => dout <= iserdes_do;
        end case;
      end if;
    end process;
  end generate;

end arch;
