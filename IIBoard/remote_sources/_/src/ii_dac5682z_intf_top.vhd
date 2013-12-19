-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_dac5682z_intf_top
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.3
--*
--*     @short DAC5682Z interface top
--*
--* Description:
--*
--*   This component is the top level interface to DAC5682Z.
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 12/1/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;

entity ii_dac5682z_intf_top is
  port (
    -- Resets and clock
    srst                 : in  std_logic;
    dac_reset            : in  std_logic;
    sys_clk              : in  std_logic;

    -- Control
    dac_ch_en            : in  std_logic_vector(1 downto 0);
    dac_run              : in  std_logic;
    test_en              : in  std_logic;
    test_mode            : in  std_logic_vector(2 downto 0);
    phase_inc_wr         : in  std_logic;
    phase_inc            : in  std_logic_vector(31 downto 0);
    sw_trig              : in  std_logic;
    window_size          : in  std_logic_vector(23 downto 0);
    trigger_mode         : in  std_logic_vector(2 downto 0);
    en_pri_trig          : in  std_logic;
    stop_pri             : in  std_logic;
    pri_busy             : out std_logic;
    pri                  : in  std_logic_vector(31 downto 0);
    trig_fifo_wr_strb    : in  std_logic;
    trig_cycle_del       : in  std_logic_vector(23 downto 0);
    trig_width           : in  std_logic_vector(23 downto 0);
    dac_spi_access_strb  : in  std_logic;
    dac_spi_wdata        : in  std_logic_vector(7 downto 0);
    dac_spi_addr         : in  std_logic_vector(4 downto 0);
    dac_spi_rd_wrn       : in  std_logic;
    dac_spi_rdy          : out std_logic;
    dac_spi_rdata_valid  : out std_logic;
    dac_spi_rdata        : out std_logic_vector(7 downto 0);
    dac_a_gain           : in  std_logic_vector(17 downto 0);
    dac_a_offset         : in  std_logic_vector(15 downto 0);
    dac_b_gain           : in  std_logic_vector(17 downto 0);
    dac_b_offset         : in  std_logic_vector(15 downto 0);

    -- Latency calibration control and status
    dac_cal_en           : in  std_logic;
    dac_cal0_done        : out std_logic;
    dac_cal1_done        : out std_logic;
    dac_iodly_cnt        : out std_logic_vector(4 downto 0);
    dac_shift_cnt        : out std_logic_vector(3 downto 0);

    -- Alerts
    dac_trig_alrt        : out std_logic;
    underflow            : out std_logic;

    -- Data fifo interface
    dac_src_aempty       : in  std_logic;
    dac_src_empty        : in  std_logic;
    dac_src_rden         : out std_logic;
    dac_src_vld          : in  std_logic;
    dac_src_din          : in  std_logic_vector(127 downto 0);

    -- reference clock
    idelayctrl_rst       : in  std_logic;
    ref_clk200           : in  std_logic;

    -- DAC external sync
    dac_ext_sync_p       : in  std_logic;
    dac_ext_sync_n       : in  std_logic;

    -- DAC output digitizer interface
    dac_dig_p            : in  std_logic;
    dac_dig_n            : in  std_logic;

    -- DAC interface signals
    dac_spi_sclk         : out std_logic;
    dac_spi_sdenb        : out std_logic;
    dac_spi_sdio         : inout std_logic;
    dac_clk_in_p         : in  std_logic;
    dac_clk_in_n         : in  std_logic;
    dac_clk_out_p        : out std_logic;
    dac_clk_out_n        : out std_logic;
    sync_out_p           : out std_logic;
    sync_out_n           : out std_logic;
    sync2_out_p          : out std_logic;
    sync2_out_n          : out std_logic;
    data_out_p           : out std_logic_vector(15 downto 0);
    data_out_n           : out std_logic_vector(15 downto 0)
  );
end ii_dac5682z_intf_top;

architecture arch of ii_dac5682z_intf_top is

  function REDUCTION_OR(A: in std_logic_vector) return std_logic is
    variable tmp : std_logic := '0';
  begin
    for i in A'range loop
      tmp := tmp or A(i);
    end loop;
    return tmp;
  end function REDUCTION_OR;

  component ii_vita_deframer
    port (
      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- Source interface
      src_aempty           : in  std_logic;
      src_empty            : in  std_logic;
      src_rden             : out std_logic;
      src_vld              : in  std_logic;
      src_din              : in  std_logic_vector(127 downto 0);

      -- Packet header info
      pkt_hdr_vld          : out std_logic;
      pkt_pyld_size        : out std_logic_vector(13 downto 0);
      pkt_idx              : out std_logic_vector(3 downto 0);
      pkt_tsi              : out std_logic_vector(1 downto 0);
      pkt_tsf              : out std_logic_vector(1 downto 0);
      pkt_stream_id        : out std_logic_vector(31 downto 0);
      pkt_ts_int_secs      : out std_logic_vector(31 downto 0);
      pkt_ts_frc_secs      : out std_logic_vector(63 downto 0);

      -- Destination interface
      dst_rdy              : in  std_logic;
      dst_frame            : out std_logic;
      dst_byte_vld         : out std_logic_vector(15 downto 0);
      dst_dout             : out std_logic_vector(127 downto 0)
    );
  end component;

  component ii_dac5682z_intf
    port (
      -- Resets and clocks
      srst                 : in  std_logic;
      dac_reset            : in  std_logic;
      sys_clk              : in  std_logic;
      dac_clk_bufio        : out std_logic;
      dac_clk_bufr         : out std_logic;

      -- Control
      dac_run              : in  std_logic;
      test_en              : in  std_logic;
      test_mode            : in  std_logic_vector(2 downto 0);
      phase_inc_wr         : in  std_logic;
      phase_inc            : in  std_logic_vector(31 downto 0);
      dac_dual_ch          : in  std_logic;
      dac_dll_bypass       : in  std_logic;
      dac_a_gain           : in  std_logic_vector(17 downto 0);
      dac_a_offset         : in  std_logic_vector(15 downto 0);
      dac_b_gain           : in  std_logic_vector(17 downto 0);
      dac_b_offset         : in  std_logic_vector(15 downto 0);

      -- External Sync and trigger interface
      ext_sync             : in  std_logic;
      ext_sync_phase       : in  std_logic_vector(1 downto 0);
      sw_trig              : in  std_logic;
      window_size          : in  std_logic_vector(23 downto 0);
      trigger_mode         : in  std_logic_vector(2 downto 0);
      dac_trigger_en       : out std_logic;

      -- Alerts
      dac_trig_alrt        : out std_logic;
      underflow            : out std_logic;

      -- Data fifo interface
      din_wr               : in  std_logic;
      din                  : in  std_logic_vector(63 downto 0);
      fifo_rdy             : out std_logic;

      -- reference clock
      idelayctrl_rst       : in  std_logic;
      ref_clk200           : in  std_logic;

      -- Latency calibration control and status
      dac_cal_en           : in  std_logic;
      dac_cal0_done        : out std_logic;
      dac_cal1_done        : out std_logic;
      dac_iodly_cnt        : out std_logic_vector(4 downto 0);
      dac_shift_cnt        : out std_logic_vector(3 downto 0);

      -- DAC output digitizer interface
      dac_dig_p            : in  std_logic;
      dac_dig_n            : in  std_logic;

      -- DAC interface signals
      dac_clk_in_p         : in  std_logic;
      dac_clk_in_n         : in  std_logic;
      dac_clk_out_p        : out std_logic;
      dac_clk_out_n        : out std_logic;
      sync_out_p           : out std_logic;
      sync_out_n           : out std_logic;
      sync2_out_p          : out std_logic;
      sync2_out_n          : out std_logic;
      data_out_p           : out std_logic_vector(15 downto 0);
      data_out_n           : out std_logic_vector(15 downto 0)
    );
  end component;

  component ii_dac5682z_spi
    port (
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- User interface
      spi_access_strb      : in  std_logic;
      spi_wdata            : in  std_logic_vector(7 downto 0);
      spi_addr             : in  std_logic_vector(4 downto 0);
      spi_rd_wrn           : in  std_logic;
      spi_rdy              : out std_logic;
      spi_rdata_valid      : out std_logic;
      spi_rdata            : out std_logic_vector(7 downto 0);

      -- dac spi interface
      dac_spi_sclk         : out std_logic;
      dac_spi_sdenb        : out std_logic;
      dac_spi_sdio         : inout std_logic
    );
  end component;

  component ii_ext_sync_s1p4
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
  end component;

  component ii_trigger_pri
    port (
      -- Reset and clock
      srst                 : in  std_logic;
      clk                  : in  std_logic;

      -- Controls
      en_pri_trig          : in  std_logic;
      trig_in              : in  std_logic;
      stop_pri             : in  std_logic;
      pri_busy             : out std_logic;
      pri                  : in  std_logic_vector(31 downto 0);

      -- Parameter FIFO interface
      trig_fifo_rst        : in  std_logic;
      trig_fifo_wr         : in  std_logic;
      trig_cycle_del       : in  std_logic_vector(23 downto 0);
      trig_width           : in  std_logic_vector(23 downto 0);

      -- Outputs
      dig_trig_pls         : out std_logic;
      dig_trig_idx         : out std_logic_vector(5 downto 0);
      dig_trig_width       : out std_logic_vector(23 downto 0);
      pri_idx              : out std_logic_vector(23 downto 0);
      pri_sof              : out std_logic
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

  signal phy_rst_sreg         : std_logic_vector(3 downto 0);
  signal phy_rst              : std_logic;
  signal ch_rst               : std_logic;
  signal pipe_rst             : std_logic;
  signal ext_sync_intf_rst    : std_logic;
  alias  en_framed_mode       : std_logic is trigger_mode(1);
  alias  en_ext_sync          : std_logic is trigger_mode(2);
  signal sw_trig_xdom         : std_logic;
  signal sw_trig_demet        : std_logic;
  signal en_pri_trig_xdom     : std_logic;
  signal en_pri_trig_demet    : std_logic;
  signal stop_pri_xdom        : std_logic;
  signal stop_pri_demet       : std_logic;
  signal trig_fifo_wr         : std_logic;
  signal sel_ext_sync         : std_logic;
  signal sel_frame_size       : std_logic_vector(23 downto 0);
  signal sel_en_framed_mode   : std_logic;
  signal sel_sw_trig          : std_logic;
  signal sel_en_ext_sync      : std_logic;
  signal sel_trig_mode        : std_logic_vector(2 downto 0);
  signal def_dst_rdy          : std_logic;
  signal def_dst_vld          : std_logic;
  signal def_dst_vld_d        : std_logic;
  signal def_dst_byte_vld     : std_logic_vector(15 downto 0);
  signal def_dst_dout         : std_logic_vector(127 downto 0);
  signal def_dst_dout_d       : std_logic_vector(63 downto 0);
  signal dac_fifo_wr          : std_logic;
  signal dac_fifo_din         : std_logic_vector(63 downto 0);
  signal dac_fifo_rdy         : std_logic;
  signal dac_dual_ch          : std_logic;
  signal dac_dll_bypass       : std_logic;
  signal dac_clk_bufio        : std_logic;
  signal dac_clk_bufr         : std_logic;
  signal dac_trigger_en       : std_logic;
  signal trigger_ip           : std_logic;
  signal ext_sync             : std_logic;
  signal ext_sync_phase       : std_logic_vector(1 downto 0);
  signal trig_in              : std_logic;
  signal pri_busy_l           : std_logic;
  signal dig_trig_pls         : std_logic;
  signal dig_trig_idx         : std_logic_vector(5 downto 0);
  signal dig_trig_width       : std_logic_vector(23 downto 0);
  signal pri_idx              : std_logic_vector(23 downto 0);
  signal pri_sof              : std_logic;

begin

-----------------------------------------------------------------------------
-- Misc.
-----------------------------------------------------------------------------
  -- Generate a reset signal that asserts asynchronously with the input srst,
  -- and deasserts synchronously at dac_clk_bufr domain
  process (srst, dac_clk_bufr)
  begin
    if (srst = '1') then
      phy_rst_sreg <= (others => '1');
    elsif (rising_edge(dac_clk_bufr)) then
      phy_rst_sreg <= phy_rst_sreg(phy_rst_sreg'high-1 downto 0) & '0';
    end if;
  end process;

  phy_rst <= phy_rst_sreg(phy_rst_sreg'high);

  -- Generate a reset signal that asserts with the input srst, and when dac_ch_en
  -- is all zeros
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      ch_rst <= srst or not dac_ch_en(0);
    end if;
  end process;

  -- Generate a reset signal that asserts with ch_rst, dac_reset,
  -- and when dac_run is deasserted at dac_clk_bufr domain
  process (ch_rst, dac_clk_bufr)
  begin
    if (ch_rst = '1') then
      pipe_rst <= '1';
    elsif (rising_edge(dac_clk_bufr)) then
      pipe_rst <= dac_reset or not dac_run;
    end if;
  end process;

  -- Generate a reset signal that asserts with pipe_rst, and when en_ext_sync
  -- is deasserted
  process (dac_clk_bufr)
  begin
    if (rising_edge(dac_clk_bufr)) then
      ext_sync_intf_rst <= pipe_rst or not (en_ext_sync);
    end if;
  end process;

  -- Sync to dac_clk_bufr domain
  process (dac_clk_bufr)
  begin
    if (rising_edge(dac_clk_bufr)) then
      sw_trig_xdom      <= sw_trig;
      sw_trig_demet     <= sw_trig_xdom;
      en_pri_trig_xdom  <= en_pri_trig;
      en_pri_trig_demet <= en_pri_trig_xdom;
      stop_pri_xdom     <= stop_pri;
      stop_pri_demet    <= stop_pri_xdom;
    end if;
  end process;

  fifo_wr_xdom_inst : ii_xdom_pulse
  port map (
    src_clk              => sys_clk,
    pls_i                => trig_fifo_wr_strb,
    dst_clk              => dac_clk_bufr,
    pls_o                => trig_fifo_wr
  );

  -- MUX on the trigger signals based on the PRI mode enable bit
  sel_ext_sync <= ext_sync when (en_pri_trig_demet = '0') else
                  dig_trig_pls;

  sel_frame_size <= window_size when (en_pri_trig_demet = '0') else
                    dig_trig_width;

  sel_en_framed_mode <= en_framed_mode or en_pri_trig_demet;

  sel_sw_trig <= sw_trig_demet when (en_pri_trig_demet = '0') else
                 '0';

  sel_en_ext_sync <= en_ext_sync or en_pri_trig_demet;

  sel_trig_mode <= sel_en_ext_sync & sel_en_framed_mode & trigger_mode(0);
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Destacker logic
-----------------------------------------------------------------------------
  -- Toggle def_dst_rdy whenever dac_fifo_rdy is asserted
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (ch_rst = '1' or dac_fifo_rdy = '0') then
        def_dst_rdy <= '0';
      else
        def_dst_rdy <= not def_dst_rdy;
      end if;
    end if;
  end process;

  def_dst_vld <= REDUCTION_OR(def_dst_byte_vld);

  -- Stretch def_dst_vld to generate dac_fifo_wr and also
  -- register the upper 64-bits of the deframer output
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      def_dst_vld_d  <= def_dst_vld;
      def_dst_dout_d <= def_dst_dout(127 downto 64);
    end if;
  end process;

  dac_fifo_wr  <= def_dst_vld or def_dst_vld_d;
  dac_fifo_din <= def_dst_dout(63 downto 0) when (def_dst_vld = '1') else
                  def_dst_dout_d;
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Instantiate ii_vita_deframer
-----------------------------------------------------------------------------
  inst_vita_deframer : ii_vita_deframer
  port map (
    -- Reset and clock
    srst                 => ch_rst,
    sys_clk              => sys_clk,

    -- Source interface
    src_aempty           => dac_src_aempty,
    src_empty            => dac_src_empty,
    src_rden             => dac_src_rden,
    src_vld              => dac_src_vld,
    src_din              => dac_src_din,

    -- Packet header info
    pkt_hdr_vld          => open,
    pkt_pyld_size        => open,
    pkt_idx              => open,
    pkt_tsi              => open,
    pkt_tsf              => open,
    pkt_stream_id        => open,
    pkt_ts_int_secs      => open,
    pkt_ts_frc_secs      => open,

    -- Destination interface
    dst_rdy              => def_dst_rdy,
    dst_frame            => open,
    dst_byte_vld         => def_dst_byte_vld,
    dst_dout             => def_dst_dout
  );
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Instantiate ii_dac5682z_intf
-----------------------------------------------------------------------------
  inst_dac_intf : ii_dac5682z_intf
  port map (
    -- Resets and clocks
    srst                 => ch_rst,
    dac_reset            => dac_reset,
    sys_clk              => sys_clk,
    dac_clk_bufio        => dac_clk_bufio,
    dac_clk_bufr         => dac_clk_bufr,

    -- Control
    dac_run              => dac_run,
    test_en              => test_en,
    test_mode            => test_mode,
    phase_inc_wr         => phase_inc_wr,
    phase_inc            => phase_inc,
    dac_dual_ch          => dac_dual_ch,
    dac_dll_bypass       => dac_dll_bypass,
    dac_a_gain           => dac_a_gain,
    dac_a_offset         => dac_a_offset,
    dac_b_gain           => dac_b_gain,
    dac_b_offset         => dac_b_offset,

    -- External Sync and trigger interface
    ext_sync             => sel_ext_sync,
    ext_sync_phase       => ext_sync_phase,
    sw_trig              => sel_sw_trig,
    window_size          => sel_frame_size,
    trigger_mode         => sel_trig_mode,
    dac_trigger_en       => dac_trigger_en,

    -- Alerts
    dac_trig_alrt        => dac_trig_alrt,
    underflow            => underflow,

    -- Data fifo interface
    din_wr               => dac_fifo_wr,
    din                  => dac_fifo_din,
    fifo_rdy             => dac_fifo_rdy,

    -- reference clock
    idelayctrl_rst       => idelayctrl_rst,
    ref_clk200           => ref_clk200,

    -- Latency calibration control and status
    dac_cal_en           => dac_cal_en,
    dac_cal0_done        => dac_cal0_done,
    dac_cal1_done        => dac_cal1_done,
    dac_iodly_cnt        => dac_iodly_cnt,
    dac_shift_cnt        => dac_shift_cnt,

    -- DAC output digitizer interface
    dac_dig_p            => dac_dig_p,
    dac_dig_n            => dac_dig_n,

    -- DAC interface signals
    dac_clk_in_p         => dac_clk_in_p,
    dac_clk_in_n         => dac_clk_in_n,
    dac_clk_out_p        => dac_clk_out_p,
    dac_clk_out_n        => dac_clk_out_n,
    sync_out_p           => sync_out_p,
    sync_out_n           => sync_out_n,
    sync2_out_p          => sync2_out_p,
    sync2_out_n          => sync2_out_n,
    data_out_p           => data_out_p,
    data_out_n           => data_out_n
  );
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Instantiate DAC SPI control interface
-----------------------------------------------------------------------------
  inst_dac_spi : ii_dac5682z_spi
  port map (
    srst                 => srst,
    sys_clk              => sys_clk,

    -- User interface
    spi_access_strb      => dac_spi_access_strb,
    spi_wdata            => dac_spi_wdata,
    spi_addr             => dac_spi_addr,
    spi_rd_wrn           => dac_spi_rd_wrn,
    spi_rdy              => dac_spi_rdy,
    spi_rdata_valid      => dac_spi_rdata_valid,
    spi_rdata            => dac_spi_rdata,

    -- dac spi interface
    dac_spi_sclk         => dac_spi_sclk,
    dac_spi_sdenb        => dac_spi_sdenb,
    dac_spi_sdio         => dac_spi_sdio
  );

  -- Intercept DAC SPI commands to detect dac_dll_bypass and
  -- dac_dual_ch settings
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (dac_reset = '1') then
        dac_dll_bypass <= '0';
        dac_dual_ch    <= '0';
      elsif (dac_spi_access_strb = '1' and dac_spi_rd_wrn = '0') then
        if (dac_spi_addr = "00101") then
          dac_dll_bypass <= dac_spi_wdata(2);
        end if;
        if (dac_spi_addr = "00010") then
          dac_dual_ch <= dac_spi_wdata(6);
        end if;
      end if;
    end if;
  end process;
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Instantiate DAC external sync interface
-----------------------------------------------------------------------------
  trigger_ip <= dac_trigger_en or pri_busy_l;

  inst_ext_sync_intf : ii_ext_sync_s1p4
  port map (
    -- reset and clocks
    reset                => ext_sync_intf_rst,
    clk_bufio            => dac_clk_bufio,
    clk_bufr             => dac_clk_bufr,

    -- external sync input
    ext_sync_p           => dac_ext_sync_p,
    ext_sync_n           => dac_ext_sync_n,

    -- controls
    trigger_en           => trigger_ip,
    idelay_rst           => '0',
    idelay               => "00000",

    -- outputs
    ext_sync             => ext_sync,
    ext_sync_phase       => ext_sync_phase
  );
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Instantiate trigger PRI
-----------------------------------------------------------------------------
  trig_in <= ext_sync or sw_trig_demet;

  trigger_pri_inst : ii_trigger_pri
  port map (
    -- Reset and clock
    srst                 => pipe_rst,
    clk                  => dac_clk_bufr,

    -- Controls
    en_pri_trig          => en_pri_trig_demet,
    trig_in              => trig_in,
    stop_pri             => stop_pri_demet,
    pri_busy             => pri_busy_l,
    pri                  => pri,

    -- Parameter FIFO interface
    trig_fifo_rst        => phy_rst,
    trig_fifo_wr         => trig_fifo_wr,
    trig_cycle_del       => trig_cycle_del,
    trig_width           => trig_width,

    -- Outputs
    dig_trig_pls         => dig_trig_pls,
    dig_trig_idx         => dig_trig_idx,
    dig_trig_width       => dig_trig_width,
    pri_idx              => pri_idx,
    pri_sof              => pri_sof
  );

  pri_busy <= pri_busy_l;
-----------------------------------------------------------------------------

end arch;
