-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_ext_sync_s1p4
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.3
--*
--*     @short External sync (trigger) interface
--*
--* Description:
--*
--*   This module interface to the external sync signal, samples it using an
--*   ISERDES (S1P4), and latches its phase when it asserts.
--*
--*
--*   @port reset           : input, async active high reset
--*   @port clk_bufio       : input, IO clock
--*   @port clk_bufr        : input, BUFR clock
--*   @port ext_sync_p      : input, external sync (trigger) differential pair (side-P)
--*   @port ext_sync_n      : input, external sync (trigger) differential pair (side-N)
--*   @port trigger_en      : input, trigger enable
--*   @port idelay_rst      : input, software programmable idelay reset
--*   @port idelay          : input, software programmable idelay value
--*   @port ext_sync        :output, detected external sync (in clk_bufr domain)
--*   @port ext_sync_phase  :output, calculated external sync phase
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 12/1/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;

entity ii_ext_sync_s1p4 is
  port (
    -- reset and clocks
    reset                : in  std_logic;
    clk_bufio            : in  std_logic;
    clk_bufr             : in  std_logic;

    -- external sync input
    ext_sync_p           : in  std_logic;
    ext_sync_n           : in  std_logic;

    -- controls
    trigger_en           : in  std_logic;
    idelay_rst           : in  std_logic;
    idelay               : in  std_logic_vector(4 downto 0);

    -- outputs
    ext_sync             : out std_logic;
    ext_sync_phase       : out std_logic_vector(1 downto 0)
  );
end ii_ext_sync_s1p4;

architecture arch of ii_ext_sync_s1p4 is

  component ii_s1p4_iob
    generic (
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
  end component;

  signal rst_clkbufr_sreg     : std_logic_vector(7 downto 0);
  signal rst_clkbufr          : std_logic;
  signal rst_clkbufr_dly      : std_logic;
  signal iodly_rst            : std_logic;
  signal idelay_rdy_sreg      : std_logic_vector(7 downto 0);
  signal clk_bufio_180        : std_logic;
  signal ext_sync_sreg        : std_logic_vector(3 downto 0);
  signal es_raw               : std_logic;
  signal trigger_en_d         : std_logic;
  signal trigger_en_fe        : std_logic;
  signal wait_es_raw          : std_logic;
  signal mask                 : std_logic;
  signal es                   : std_logic;
  signal es_d                 : std_logic;

begin

  -- Synchronize reset to clk_bufr domain
  process (reset, clk_bufr)
  begin
    if (reset = '1') then
      rst_clkbufr_sreg <= (others => '1');
    elsif (rising_edge(clk_bufr)) then
      rst_clkbufr_sreg <= rst_clkbufr_sreg(rst_clkbufr_sreg'high-1 downto 0) & '0';
    end if;
  end process;

  rst_clkbufr     <= rst_clkbufr_sreg(3);
  rst_clkbufr_dly <= rst_clkbufr_sreg(rst_clkbufr_sreg'high);

  iodly_rst <= rst_clkbufr or idelay_rst;

  -- Generate a ready signal after finishing loading the IODELAY tap count
  -- and also allow it a few clock cycles to settle down.
  process (clk_bufr)
  begin
    if (rising_edge(clk_bufr)) then
      if (iodly_rst = '1') then
        idelay_rdy_sreg <= (others => '0');
      else
        idelay_rdy_sreg <= idelay_rdy_sreg(idelay_rdy_sreg'high-1 downto 0) & '1';
      end if;
    end if;
  end process;

--------------------------------------------------------------------------------
-- Serial to parallel converter on external sync input
--------------------------------------------------------------------------------
  clk_bufio_180 <= not clk_bufio;

  ext_sync_s1p4_iob : ii_s1p4_iob
    generic map (
      DIFF_TERM            => FALSE,
      IOSTANDARD           => "LVPECL_25"
    )
    port map (
      -- Reset and clocks
      srst                 => rst_clkbufr,
      clk                  => clk_bufio,
      clk_180              => clk_bufio_180,
      clk_div2             => clk_bufr,

      -- IODELAY control and status
      iodly_rst            => iodly_rst,
      iodly_ce             => '0',
      iodly_inc            => '0',
      iodly_init_cnt       => idelay,
      iodly_cnt            => open,
      bitslip              => '0',

      -- Serial data input
      din_p                => ext_sync_p,
      din_n                => ext_sync_n,

      -- Parallel data output
      dout                 => ext_sync_sreg
    );

------------------------------------------------------------------------------
-- Calculate external sync phase
------------------------------------------------------------------------------
  es_raw <= ext_sync_sreg(3) or ext_sync_sreg(2) or
            ext_sync_sreg(1) or ext_sync_sreg(0);

  trigger_en_fe <= not trigger_en and trigger_en_d;

  -- Mask ext_sync output until a falling edge of trigger_en and
  -- es_raw are deasserted to avoid generating an immediate (partial)
  -- ext_sync output just after the logic is enabled to start capturing
  process (clk_bufr)
  begin
    if (rising_edge(clk_bufr)) then
      if (rst_clkbufr_dly = '1' or
          idelay_rdy_sreg(idelay_rdy_sreg'high) = '0') then
        wait_es_raw <= '1';
        mask        <= '1';
      elsif (trigger_en_fe = '1') then
        wait_es_raw <= '1';
      elsif (es_raw = '0' and wait_es_raw = '1') then
        wait_es_raw <= '0';
        mask        <= '0';
      end if;
      trigger_en_d <= trigger_en;
    end if;
  end process;

  es <= es_raw and not mask;

  -- Detect a rising edge on ext_sync_p/n and convert the 4-bit parallel
  -- ext_sync_sreg into ext_sync_phase only when not already triggered
  process (clk_bufr)
  begin
    if (rising_edge(clk_bufr)) then
      if (rst_clkbufr = '1') then
        es_d           <= '0';
        ext_sync_phase <= (others => '0');
      else
        es_d <= es;
        if (es = '1' and es_d = '0' and trigger_en = '0') then
          if (ext_sync_sreg(0) = '1') then
            ext_sync_phase <= "00";
          elsif (ext_sync_sreg(1) = '1') then
            ext_sync_phase <= "01";
          elsif (ext_sync_sreg(2) = '1') then
            ext_sync_phase <= "10";
          elsif (ext_sync_sreg(3) = '1') then
            ext_sync_phase <= "11";
          end if;
        end if;
      end if;
    end if;
  end process;

  ext_sync <= es_d;

end arch;

