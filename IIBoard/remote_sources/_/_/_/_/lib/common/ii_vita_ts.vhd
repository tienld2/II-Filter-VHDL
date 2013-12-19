-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_vita_ts
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.x
--*
--*     @short VITA-49 Timestamp
--*
--* Description:
--*
--*   This module generates a VITA-49 compliant timestamp upon request.
--*   It sets the initial timestamp value by software, which then can be
--*   enabled through the 'arm' input, or by the PPS pulse input.
--*   The integer-seconds timestamp counts in the system clock domain at 200MHz
--*   by keeping track of time as close as possible, or by the PPS pulse
--*   coming from a GPS input.
--*   When the integer-seconds timestamp increments, it generates a pulse
--*   to the fractional-seconds counter (running on fs clock) to reset it.
--*
--*
--*   @generic G_SIM          : boolean, in simulation mode
--*   @generic SYS_CLK_FREQ   : integer, system clock frequency in MHz
--*   @port srst              : input, Synchronous active high software reset
--*   @port sys_clk           : input, System clock
--*   @port fs_clk            : input, Sample clock
--*   @port ts_initial        : input, Initial timestamp integer-seconds value
--*   @port ts_load           : input, Load initial value
--*   @port ts_arm            : input, Start timestamp counter
--*   @port pps_pls           : input, PPS pulse input from ie. GPS (on sys_clk)
--*   @port pps_mode          : input, PPS mode enabled or internal seconds
--*   @port tsf               : input, TSF mode
--*   @port ts_int_secs       :output, Timestamp integer-seconds value
--*   @port ts_frc_secs       :output, Timestamp fractional-seconds value
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date Created 6/23/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ii_vita_ts is
  generic (
    G_SIM                : boolean;
    SYS_CLK_FREQ         : integer := 250
  );
  port (
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;
    fs_clk               : in  std_logic;
    ts_initial           : in  std_logic_vector(31 downto 0);
    ts_load              : in  std_logic;
    ts_arm               : in  std_logic;
    pps_pls              : in  std_logic;
    pps_mode             : in  std_logic;
    tsf                  : in  std_logic_vector(1 downto 0);
    ts_int_secs          : out std_logic_vector(31 downto 0);
    ts_frc_secs          : out std_logic_vector(63 downto 0)
  );
end ii_vita_ts;

architecture arch of ii_vita_ts is

  constant SYS_CLK_FREQ_HZ    : integer := SYS_CLK_FREQ * 1000000;

  function asecond return integer is
  begin
    if (G_SIM = true) then
      return SYS_CLK_FREQ_HZ/100000;
    else
      return SYS_CLK_FREQ_HZ;
    end if;
  end function;

  constant ONE_SEC            : integer := asecond - 1;
  signal fs_rst_sreg          : std_logic_vector(3 downto 0);
  signal fs_rst               : std_logic;
  signal ts_en                : std_logic;
  signal int_secs_cnt         : integer range 0 to ONE_SEC;
  signal int_secs_pls         : std_logic;
  signal int_secs             : unsigned(31 downto 0);
  signal int_secs_tog         : std_logic;
  signal int_secs_xdom        : std_logic;
  signal int_secs_demet       : std_logic;
  signal int_secs_demet_d     : std_logic;
  signal int_secs_inc         : std_logic;
  signal int_secs_fs          : unsigned(31 downto 0);
  signal frc_secs_cnt         : unsigned(63 downto 0);

begin

  ------------------------------------------------------------------------------
  -- Synchronize srst to fs_clk domain
  ------------------------------------------------------------------------------
  process (srst, fs_clk)
  begin
    if (srst = '1') then
      fs_rst_sreg <= (others => '1');
    elsif (rising_edge(fs_clk)) then
      fs_rst_sreg <= fs_rst_sreg(fs_rst_sreg'high-1 downto 0) & '0';
    end if;
  end process;

  fs_rst <= fs_rst_sreg(fs_rst_sreg'high);

  ------------------------------------------------------------------------------
  -- Integer-seconds counter
  ------------------------------------------------------------------------------
  -- Timestamp enable: enable in pps_mode or when software arms it
  process (sys_clk)
  begin
    if rising_edge(sys_clk) then
      if (srst = '1' or ts_load = '1') then
        ts_en <= '0';
      elsif (pps_mode = '1' or ts_arm = '1') then
        ts_en <= '1';
      end if;
    end if;
  end process;

  -- Downcounter from ONE_SEC to 0
  process (sys_clk)
  begin
    if rising_edge(sys_clk) then
      if (ts_en = '1' and pps_mode = '0') then
        if (int_secs_pls = '1') then
          int_secs_cnt <= ONE_SEC;
        else
          int_secs_cnt <= int_secs_cnt - 1;
        end if;
      else
        int_secs_cnt <= ONE_SEC;
      end if;
    end if;
  end process;

  -- Pulse whenever integer-seconds downcount to zero
  -- or when in pps_mode, the pps input pulses
  process (sys_clk)
  begin
    if rising_edge(sys_clk) then
      if (pps_mode = '0') then
        if (int_secs_cnt = 1) then
          int_secs_pls <= '1';
        else
          int_secs_pls <= '0';
        end if;
      else
        int_secs_pls <= pps_pls;
      end if;
    end if;
  end process;

  -- Load the initial value and Increment integer-seconds
  -- counter if timestamp is enabled
  process (sys_clk)
  begin
    if rising_edge(sys_clk) then
      if (ts_load = '1') then
        int_secs <= unsigned(ts_initial);
      elsif (ts_en = '1' and int_secs_pls = '1') then
        int_secs <= int_secs + 1;
      end if;
    end if;
  end process;

  -- Toggle to cross to fs_clk domain when integer-seconds increments
  -- or when the integer-seconds is loaded by software
  process (sys_clk)
  begin
    if rising_edge(sys_clk) then
      if (srst = '1') then
        int_secs_tog <= '0';
      elsif (int_secs_pls = '1' or ts_load = '1') then
        int_secs_tog <= not int_secs_tog;
      end if;
    end if;
  end process;

  -- Catch int_secs_tog and generate a pulse on fs_clk domain
  process (fs_clk)
  begin
    if rising_edge(fs_clk) then
      int_secs_xdom    <= int_secs_tog;
      int_secs_demet   <= int_secs_xdom;
      int_secs_demet_d <= int_secs_demet;
    end if;
  end process;

  int_secs_inc <= int_secs_demet xor int_secs_demet_d;

  -- The int_secs_inc pulse latches the int_secs_cnt on fs_clk domain
  process (fs_clk)
  begin
    if rising_edge(fs_clk) then
      if (fs_rst = '1') then
        int_secs_fs <= (others => '0');
      elsif (int_secs_inc = '1') then
        int_secs_fs <= int_secs;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Fractional-seconds counter
  ------------------------------------------------------------------------------
  -- The fractional-seconds counter
  -- Reset counter when integer-seconds counter increments
  -- or don't reset it when it's freerunning mode (TFS=11)
  process (fs_clk)
  begin
    if rising_edge(fs_clk) then
      if (fs_rst = '1' or (tsf = "01" and int_secs_inc = '1')) then
        frc_secs_cnt <= (others => '0');
      else
        frc_secs_cnt <= frc_secs_cnt + 1;
      end if;
    end if;
  end process;

  -- Latch the outputs
  process (fs_clk)
  begin
    if rising_edge(fs_clk) then
      ts_int_secs <= std_logic_vector(int_secs_fs);
      ts_frc_secs <= std_logic_vector(frc_secs_cnt);
    end if;
  end process;

end arch;

