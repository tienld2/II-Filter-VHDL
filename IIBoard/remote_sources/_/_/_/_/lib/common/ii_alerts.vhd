-- Copyright 2007 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_alerts
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.1
--*
--*     @short Alerts
--*
--* Description:
--*
--*   This component is the alert log. When an alert trigger occurs,
--*   this causes the alert log to generate an alert message that goes into
--*   the alert FIFO. This alert message includes a timestamp, source and
--*   other information. This allows the user to create a time log of alerts
--*   that occured such as start or stop triggers during the data collection.
--*
--*   @port srst               : input, synchronous active high reset
--*   @port sys_clk            : input, system clock
--*   @port ref_clk            : input, reference clock used for timebase
--*   @port alert_data         : input, alert data
--*   @port alert              : input, alert data trigger inputs
--*   @port alert_enable       : input, alert triggers enable
--*   @port trigger            : input, trigger
--*   @port timestamp_run      : input, enable timestamp
--*   @port timestamp_rollover :output, indicates that the 32-bit timestamp
--*                                     counter had rolled from X"FFFFFFFF" to 0
--*   @port alert_fifo_rst     : input, reset the alert FIFO
--*   @port alert_fifo_wrd_cnt :output, alert FIFO word count
--*   @port alert_fifo_aempty  :output, alert FIFO almost empty
--*   @port alert_fifo_empty   :output, alert FIFO empty
--*   @port alert_fifo_rd      : input, alert FIFO read enable
--*   @port alert_dout_vld     :output, alert FIFO data output is valid
--*   @port alert_dout         :output, alert FIFO data output
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 03/19/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unimacro;
use unimacro.vcomponents.all;

library work;
use work.x6_pkg.all;

entity ii_alerts is
  port (
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;
    ref_clk              : in  std_logic;
    alert_data           : in  width_32_alrt_array;
    alert                : in  std_logic_vector(num_alerts-1 downto 0);
    alert_enable         : in  std_logic_vector(num_alerts-1 downto 0);
    trigger              : in  std_logic;
    timestamp_run        : in  std_logic;
    timestamp_rollover   : out std_logic;
    alert_fifo_rst       : in  std_logic;
    alert_fifo_wrd_cnt   : out std_logic_vector(8 downto 0);
    alert_fifo_aempty    : out std_logic;
    alert_fifo_empty     : out std_logic;
    alert_fifo_rd        : in  std_logic;
    alert_dout_vld       : out std_logic;
    alert_dout           : out std_logic_vector(127 downto 0)
  );
end ii_alerts;

architecture arch of ii_alerts is

  component ii_timestamp
    port (
      clk                  : in  std_logic;
      ce                   : in  std_logic;
      timestamp_run        : in  std_logic;
      timestamp_timer      : out std_logic_vector(31 downto 0);
      timestamp_rollover   : out std_logic
    );
  end component;

  component ii_xdom_pulse
    port (
      src_clk              : in  std_logic;
      pls_i                : in  std_logic;
      dst_clk              : in  std_logic;
      pls_o                : out std_logic
    );
  end component;

  constant alert_size_dqwrds  : integer := (num_alerts/4);
  constant pyld_size_dqwrds   : integer := alert_size_dqwrds + 1;
  constant fifo_ae_thresh     : bit_vector(19 downto 0) := to_bitvector(std_logic_vector(
                                                  to_unsigned(pyld_size_dqwrds-1,20)),'0');
  constant alert_non_zero     : std_logic_vector(num_alerts-1 downto 0) := (others => '0');
  signal trigger_d            : std_logic;
  signal trigger_dd           : std_logic;
  signal trigger_re           : std_logic;
  signal ts_run               : std_logic;
  signal ts_run_sreg          : std_logic_vector(2 downto 0);
  signal ts_timer             : std_logic_vector(31 downto 0);
  signal ts_timer_latched     : std_logic_vector(31 downto 0);
  signal ts_rollover          : std_logic;
  signal ts_rollover_xdom     : std_logic;
  signal ts_rollover_sreg     : std_logic_vector(3 downto 0);
  signal ts_get               : std_logic;
  signal ts_get_xdom          : std_logic;
  signal ts_latched           : std_logic;
  signal alert_d              : std_logic_vector(num_alerts-1 downto 0);
  signal alert_dd             : std_logic_vector(num_alerts-1 downto 0);
  signal alert_flag           : std_logic_vector(num_alerts-1 downto 0);
  signal alert_flag_latched   : std_logic_vector(num_alerts-1 downto 0);
  signal clr_alert_flag       : std_logic_vector(num_alerts-1 downto 0);
  signal dqwrd_cnt            : natural range 1 to alert_size_dqwrds;
  signal data_latched         : width_32_alrt_array;
  type   state_type is (idle, timestamp_wait, timestamping, payload, complete);
  signal state                : state_type;

  signal fifo_afull           : std_logic;
  signal fifo_afull_d         : std_logic;
  signal fifo_aempty          : std_logic;
  signal fifo_empty           : std_logic;
  signal fifo_reset           : std_logic;
  signal fifo_rdcount_hi      : std_logic_vector(8 downto 0);
  signal fifo_wrcount_hi      : std_logic_vector(8 downto 0);
  signal fifo_din_hi          : std_logic_vector(63 downto 0);
  signal fifo_din_lo          : std_logic_vector(63 downto 0);
  signal fifo_rdcount_lo      : std_logic_vector(8 downto 0);
  signal fifo_wrcount_lo      : std_logic_vector(8 downto 0);
  signal alert_dout_hi        : std_logic_vector(63 downto 0);
  signal alert_dout_lo        : std_logic_vector(63 downto 0);
  signal alert_wr             : std_logic;
  signal fifo_wrd_cnt         : unsigned(8 downto 0);

begin

  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      trigger_d  <= trigger;
      trigger_dd <= trigger_d;
    end if;
  end process;

  trigger_re <= not trigger_dd and trigger_d;

  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or timestamp_run = '0') then
        ts_run <= '0';
      elsif (trigger_re = '1') then
        ts_run <= '1';
      end if;
    end if;
  end process;

  -- sync run to timestamp clock
  process (ref_clk)
  begin
    if (rising_edge(ref_clk)) then
      ts_run_sreg <= ts_run_sreg(1 downto 0) & ts_run;
    end if;
  end process;

  -- timestamp
  timestamper : ii_timestamp
  port map (
    clk                  => ref_clk,
    ce                   => '1',
    timestamp_run        => ts_run_sreg(2),
    timestamp_timer      => ts_timer,
    timestamp_rollover   => ts_rollover
  );

  -- cross from ref_clk to sys_clk
  rollover_xdom : ii_xdom_pulse
  port map (
    src_clk              => ref_clk,
    pls_i                => ts_rollover,
    dst_clk              => sys_clk,
    pls_o                => ts_rollover_xdom
  );

  -- Generate a four sys_clk wide rollover pulse
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        ts_rollover_sreg <= (others => '0');
      elsif (ts_rollover_xdom = '1') then
        ts_rollover_sreg <= (others => '1');
      else
        ts_rollover_sreg <= ts_rollover_sreg(2 downto 0) & '0';
      end if;
    end if;
  end process;

  timestamp_rollover <= ts_rollover_sreg(3);

  -- cross from sys_clk to ref_clk
  get_xdom : ii_xdom_pulse
  port map (
    src_clk              => sys_clk,
    pls_i                => ts_get,
    dst_clk              => ref_clk,
    pls_o                => ts_get_xdom
  );

  -- cross from ref_clk to sys_clk
  ts_latched_xdom : ii_xdom_pulse
  port map (
    src_clk              => ref_clk,
    pls_i                => ts_get_xdom,
    dst_clk              => sys_clk,
    pls_o                => ts_latched
  );

  -- Latch the timestamp value
  process (ref_clk)
  begin
    if (rising_edge(ref_clk)) then
      -- latch timestamp value to cross back to sys_clk
      if (ts_get_xdom = '1') then
        ts_timer_latched <= ts_timer;
      end if;
    end if;
  end process;

  gen_alert_regs: for i in 0 to num_alerts-1 generate
    -- catch the rising edge of each alert if enabled
    process (sys_clk)
    begin
      if (rising_edge(sys_clk)) then
        alert_d(i)  <= alert(i);
        alert_dd(i) <= alert_d(i);
        if (srst = '1') then
          alert_flag(i) <= '0';
        else
          if (alert_d(i) = '1' and alert_dd(i) = '0' and
              alert_enable(i) = '1') then
            alert_flag(i) <= '1';
          elsif (clr_alert_flag(i) = '1') then
            alert_flag(i) <= '0';
          end if;
        end if;
      end if;
    end process;
  end generate;

  -- clear alerts when complete for those alerts that were signaled
  gen_alert_clear : for i in 0 to num_alerts-1 generate
    clr_alert_flag(i) <= '1' when (state = complete and
                                   alert_flag_latched(i) = '1') else
                         '0';
  end generate;

  -- the state machine for alert message creation
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        ts_get   <= '0';
        alert_wr <= '0';
        state    <= idle;
      else
        ts_get      <= '0';
        alert_wr    <= '0';
        dqwrd_cnt   <= (num_alerts/4);
        fifo_din_lo <= X"1303123413031234";
        fifo_din_hi <= X"1303123413031234";
        case (state) is
          ----------------------------------------------------------------------
          when idle =>
            alert_flag_latched <= alert_flag;
            -- if there is an alert event and alert fifo is not afull
            if (alert_flag /= alert_non_zero and fifo_afull_d = '0') then
              data_latched <= alert_data;
              ts_get       <= '1';
              state        <= timestamp_wait;
            else
              state        <= idle;
            end if;
          ----------------------------------------------------------------------
          when timestamp_wait =>
            if (ts_latched = '1') then
              state <= timestamping;
            else
              state <= timestamp_wait;
            end if;
          ----------------------------------------------------------------------
          when timestamping =>
            alert_wr    <= '1';
            state       <= payload;
            fifo_din_lo <= ts_timer_latched & alert_flag_latched;
            fifo_din_hi <= (others => '0');
          ----------------------------------------------------------------------
          when payload =>
            alert_wr <= '1';
            if (dqwrd_cnt > 1) then
              dqwrd_cnt <= dqwrd_cnt-1;
            end if;
            if (dqwrd_cnt = 1) then
              state <= complete;
            else
              state <= payload;
            end if;
            fifo_din_lo <= data_latched((num_alerts - (4*dqwrd_cnt)) + 1) &
                           data_latched((num_alerts - (4*dqwrd_cnt)));
            fifo_din_hi <= data_latched((num_alerts - (4*dqwrd_cnt)) + 3) &
                           data_latched((num_alerts - (4*dqwrd_cnt)) + 2);
          ----------------------------------------------------------------------
          when complete =>
            state <= idle;
          ----------------------------------------------------------------------
          when others =>
            state <= idle;
          ----------------------------------------------------------------------
        end case;
      end if;
    end if;
  end process;

  alert_fifo_aempty <= fifo_aempty;
  alert_fifo_empty  <= fifo_empty;

  -- fifo for msb of alert log
  inst_alert_fifo_hi : fifo_sync_macro
  generic map (
    DEVICE                 => "VIRTEX6",
    ALMOST_FULL_OFFSET     => x"0020",
    ALMOST_EMPTY_OFFSET    => fifo_ae_thresh,
    DATA_WIDTH             => 64,
    FIFO_SIZE              => "36Kb",
    SIM_MODE               => "SAFE"
  )
  port map (
    ALMOSTEMPTY            => fifo_aempty,
    ALMOSTFULL             => fifo_afull,
    DO                     => alert_dout_hi,
    EMPTY                  => fifo_empty,
    FULL                   => open,
    RDCOUNT                => fifo_rdcount_hi,
    RDERR                  => open,
    WRCOUNT                => fifo_wrcount_hi,
    WRERR                  => open,
    CLK                    => sys_clk,
    DI                     => fifo_din_hi,
    RDEN                   => alert_fifo_rd,
    RST                    => fifo_reset,
    WREN                   => alert_wr
  );

  -- fifo for lsb of alert log
  inst_alert_fifo_lo : fifo_sync_macro
  generic map (
    DEVICE                 => "VIRTEX6",
    ALMOST_FULL_OFFSET     => x"0020",
    ALMOST_EMPTY_OFFSET    => x"0008",
    DATA_WIDTH             => 64,
    FIFO_SIZE              => "36Kb",
    SIM_MODE               => "SAFE"
  )
  port map (
    ALMOSTEMPTY            => open,
    ALMOSTFULL             => open,
    DO                     => alert_dout_lo,
    EMPTY                  => open,
    FULL                   => open,
    RDCOUNT                => fifo_rdcount_lo,
    RDERR                  => open,
    WRCOUNT                => fifo_wrcount_lo,
    WRERR                  => open,
    CLK                    => sys_clk,
    DI                     => fifo_din_lo,
    RDEN                   => alert_fifo_rd,
    RST                    => fifo_reset,
    WREN                   => alert_wr
  );

  alert_dout <= alert_dout_hi & alert_dout_lo;

  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      fifo_afull_d   <= fifo_afull;
      fifo_reset     <= srst or alert_fifo_rst;
      alert_dout_vld <= alert_fifo_rd and not fifo_empty;
    end if;
  end process;

  -- Calculate the number of points in the fifo
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        fifo_wrd_cnt <= (others => '0');
      else
        if (alert_wr = '1' and (alert_fifo_rd = '0' or fifo_empty = '1')) then
          fifo_wrd_cnt <= fifo_wrd_cnt + 1;
        elsif (alert_wr = '0' and alert_fifo_rd = '1' and fifo_empty = '0') then
          fifo_wrd_cnt <= fifo_wrd_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  alert_fifo_wrd_cnt <= std_logic_vector(fifo_wrd_cnt);

end arch;
