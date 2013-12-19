-- Copyright 2011 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_ads5400_intf_top
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 13.2
--*
--*     @short ADS5400 interface top
--*
--* Description:
--*
--*   This component is the top level interface to ADS5400.
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 5/3/11
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_ads5400_intf_top is
  generic (
    G_SIM                : boolean;
    SYS_CLK_FREQ         : integer := 250
  );
  port (
    -- Reset and clocks
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;
    ref_clk200           : in  std_logic;

    -- Controls
    idelayctrl_rst       : in  std_logic;
    adc_phy_init         : in  std_logic;
    skip_adc_phy_cal     : in  std_logic;
    ch_en                : in  std_logic;
    run                  : in  std_logic;
    sw_trig              : in  std_logic;
    window_size          : in  std_logic_vector(23 downto 0);
    trigger_mode         : in  std_logic_vector(2 downto 0);
    decimation           : in  std_logic_vector(11 downto 0);
    en_pri_trig          : in  std_logic;
    stop_pri             : in  std_logic;
    pri_busy             : out std_logic;
    pri                  : in  std_logic_vector(31 downto 0);
    trig_fifo_wr_strb    : in  std_logic;
    trig_cycle_del       : in  std_logic_vector(23 downto 0);
    trig_width           : in  std_logic_vector(23 downto 0);
    test_en              : in  std_logic;
    test_mode            : in  std_logic;
    gain                 : in  std_logic_vector(11 downto 0);
    offset               : in  std_logic_vector(8 downto 0);
    frame_size           : in  std_logic_vector(15 downto 0);
    stream_id            : in  std_logic_vector(31 downto 0);
    ts_initial           : in  std_logic_vector(31 downto 0);
    ts_load              : in  std_logic;
    ts_arm               : in  std_logic;
    ts_pps_mode          : in  std_logic;
    ts_pps_pls           : in  std_logic;
    ts_tsi               : in  std_logic_vector(1 downto 0);
    ts_tsf               : in  std_logic_vector(1 downto 0);
    spi_access_strb      : in  std_logic;
    spi_wdata            : in  std_logic_vector(7 downto 0);
    spi_addr             : in  std_logic_vector(4 downto 0);
    spi_rd_wrn           : in  std_logic;
    spi_rdy              : out std_logic;
    spi_rdata_valid      : out std_logic;
    spi_rdata            : out std_logic_vector(7 downto 0);

    -- Status
    adc_eye_aligned      : out std_logic_vector(12 downto 0);
    adc_prbs_locked      : out std_logic;
    adc_prbs_aligned     : out std_logic;
    adc_phy_rdy          : out std_logic;

    -- Alerts
    adc_trig_alrt        : out std_logic;
    adc_overrange        : out std_logic;
    adc_overflow         : out std_logic;

    -- ADC external sync
    ext_sync_p           : in  std_logic;
    ext_sync_n           : in  std_logic;

    -- ADC VITA-49 framer interface
    adc_fifo_empty       : out std_logic;
    adc_fifo_aempty      : out std_logic;
    adc_fifo_rden        : in  std_logic;
    adc_fifo_vld         : out std_logic;
    adc_fifo_dout        : out std_logic_vector(127 downto 0);

    -- ADC data (sync'd to adc_dclk_div2)
    adc_dclk_div2        : out std_logic;
    adc_raw_vld          : out std_logic;
    adc_raw_data         : out std_logic_vector(47 downto 0);
    adc_raw_ovr          : out std_logic;
    adc_raw_ovf          : out std_logic;
    adc_trigger          : out std_logic;

    -- ADC interface
    adc_spi_sclk         : out std_logic;
    adc_spi_sdenb        : out std_logic;
    adc_spi_sdio         : inout std_logic;
    adc_reset_p          : out std_logic;
    adc_reset_n          : out std_logic;
    adc_da_dclk_p        : in  std_logic;
    adc_da_dclk_n        : in  std_logic;
    adc_da_p             : in  std_logic_vector(11 downto 0);
    adc_da_n             : in  std_logic_vector(11 downto 0);
    adc_ovra_p           : in  std_logic;
    adc_ovra_n           : in  std_logic
  );
end ii_ads5400_intf_top;

architecture arch of ii_ads5400_intf_top is

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

  component ii_trigger
    generic (
      SAMPLES_PER_CLK      : integer := 1
    );
    port (
      reset                : in  std_logic;
      clk                  : in  std_logic;
      ce                   : in  std_logic;
      ext_sync             : in  std_logic;
      sw_trig              : in  std_logic;
      trig_mode            : in  std_logic_vector(2 downto 0);
      frame_size           : in  std_logic_vector(23 downto 0);
      decimation_coeff     : in  std_logic_vector(11 downto 0);
      decimation_en        : out std_logic;
      trigger              : out std_logic;
      trigger_en           : out std_logic
    );
  end component;

  component ii_ads5400_intf
    port (
      -- Reset and clocks
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;
      ref_clk200           : in  std_logic;

      -- Controls
      idelayctrl_rst       : in  std_logic;
      adc_phy_init         : in  std_logic;
      skip_adc_phy_cal     : in  std_logic;
      ch_en                : in  std_logic;
      run                  : in  std_logic;
      test_en              : in  std_logic;
      test_mode            : in  std_logic;
      gain                 : in  std_logic_vector(11 downto 0);
      offset               : in  std_logic_vector(8 downto 0);
      spi_access_strb      : in  std_logic;
      spi_wdata            : in  std_logic_vector(7 downto 0);
      spi_addr             : in  std_logic_vector(4 downto 0);
      spi_rd_wrn           : in  std_logic;
      spi_rdy              : out std_logic;
      spi_rdata_valid      : out std_logic;
      spi_rdata            : out std_logic_vector(7 downto 0);
      trigger              : in  std_logic;
      trigger_frame        : in  std_logic;
      ext_sync_phase       : in  std_logic_vector(1 downto 0);
      data_fifo_afull      : in  std_logic;

      -- Status
      adc_eye_aligned      : out std_logic_vector(12 downto 0);
      adc_prbs_locked      : out std_logic;
      adc_prbs_aligned     : out std_logic;
      adc_phy_rdy          : out std_logic;

      -- ADC interface
      adc_spi_sclk         : out std_logic;
      adc_spi_sdenb        : out std_logic;
      adc_spi_sdio         : inout std_logic;
      adc_reset_p          : out std_logic;
      adc_reset_n          : out std_logic;
      adc_da_dclk_p        : in  std_logic;
      adc_da_dclk_n        : in  std_logic;
      adc_da_p             : in  std_logic_vector(11 downto 0);
      adc_da_n             : in  std_logic_vector(11 downto 0);
      adc_ovra_p           : in  std_logic;
      adc_ovra_n           : in  std_logic;

      -- A/D data (sync'd to adc_dclk_div2)
      adc_dclk             : out std_logic;
      adc_dclk_180         : out std_logic;
      adc_dclk_div2        : out std_logic;
      adc_data_frame       : out std_logic;
      adc_data_vld         : out std_logic;
      adc_data             : out std_logic_vector(47 downto 0);
      adc_ovr              : out std_logic;
      adc_ovf              : out std_logic
    );
  end component;

  component ii_vita_framer
    generic (
      ibw                  : integer := 8
    );
    port (
      -- Reset and clocks
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;
      fs_clk               : in  std_logic;

      -- Controls
      frame_size           : in  std_logic_vector(15 downto 0);
      stream_id            : in  std_logic_vector(31 downto 0);
      packet_type          : in  std_logic_vector(3 downto 0);

      -- VITA-49 Timestamp interface
      ts_int_secs          : in  std_logic_vector(31 downto 0);
      ts_frc_secs          : in  std_logic_vector(63 downto 0);
      tsi                  : in  std_logic_vector(1 downto 0);
      tsf                  : in  std_logic_vector(1 downto 0);

      -- Data source interface
      din_frame            : in  std_logic;
      din_vld              : in  std_logic;
      din                  : in  std_logic_vector(ibw-1 downto 0);

      -- Data source FIFO interface
      src_fifo_afull       : in  std_logic;
      src_fifo_wren        : out std_logic;
      src_fifo_din         : out std_logic_vector(127 downto 0);
      src_fifo_empty       : in  std_logic;
      src_fifo_rden        : out std_logic;
      src_fifo_vld         : in  std_logic;
      src_fifo_dout        : in  std_logic_vector(127 downto 0);

      -- VITA-49 FIFO interface
      dst_fifo_empty       : out std_logic;
      dst_fifo_aempty      : out std_logic;
      dst_fifo_rden        : in  std_logic;
      dst_fifo_vld         : out std_logic;
      dst_fifo_dout        : out std_logic_vector(127 downto 0)
    );
  end component;

  component afifo_2kx96_bram
    port (
      rst                  : in  std_logic;
      wr_clk               : in  std_logic;
      rd_clk               : in  std_logic;
      din                  : in  std_logic_vector(95 downto 0);
      wr_en                : in  std_logic;
      rd_en                : in  std_logic;
      prog_empty_thresh    : in  std_logic_vector(10 downto 0);
      prog_full_thresh     : in  std_logic_vector(10 downto 0);
      dout                 : out std_logic_vector(95 downto 0);
      full                 : out std_logic;
      empty                : out std_logic;
      valid                : out std_logic;
      prog_full            : out std_logic;
      prog_empty           : out std_logic
    );
  end component;

  component ii_vita_ts
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
  end component;

  component ii_trig_alert
    port (
      rst_sys_clk          : in  std_logic;
      sys_clk              : in  std_logic;
      rst_fs_clk           : in  std_logic;
      fs_clk               : in  std_logic;
      trig_in              : in  std_logic;
      trig_alert           : out std_logic
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

  signal pipe_rst             : std_logic := '1';
  signal ext_sync_rst         : std_logic;
  alias  en_framed_mode       : std_logic is trigger_mode(1);
  alias  en_ext_sync          : std_logic is trigger_mode(2);
  signal sw_trig_xdom         : std_logic;
  signal sw_trig_demet        : std_logic;
  signal en_pri_trig_xdom     : std_logic;
  signal en_pri_trig_demet    : std_logic;
  signal stop_pri_xdom        : std_logic;
  signal stop_pri_demet       : std_logic;
  signal trig_fifo_wr         : std_logic;
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
  signal sel_ext_sync         : std_logic;
  signal sel_frame_size       : std_logic_vector(23 downto 0);
  signal sel_en_framed_mode   : std_logic;
  signal sel_sw_trig          : std_logic;
  signal sel_en_ext_sync      : std_logic;
  signal sel_trig_mode        : std_logic_vector(2 downto 0);
  signal decimation_en        : std_logic;
  signal trigger              : std_logic;
  signal trigger_en           : std_logic;
  signal adc_phy_rdy_l        : std_logic;
  signal adc_dclk             : std_logic;
  signal adc_dclk_180         : std_logic;
  signal adc_dclk_div2_l      : std_logic;
  signal adc_data_frame       : std_logic;
  signal adc_data_vld         : std_logic;
  signal adc_data             : std_logic_vector(47 downto 0);
  signal adc_data_sext        : std_logic_vector(63 downto 0);
  signal adc_ovr              : std_logic;
  signal adc_ovf              : std_logic;
  signal ovr_xdom             : std_logic;
  signal ovr_demet            : std_logic;
  signal ovf_l                : std_logic;
  signal ovf_l_d              : std_logic;
  signal ovf_l_re             : std_logic;
  signal ovf_re               : std_logic;
  signal ovf_re_sreg          : std_logic_vector(3 downto 0);
  signal data_fifo_wren       : std_logic;
  signal data_fifo_din_sext   : std_logic_vector(127 downto 0);
  signal data_fifo_din        : std_logic_vector(95 downto 0);
  signal data_fifo_empty      : std_logic;
  signal data_fifo_rden       : std_logic;
  signal data_fifo_valid      : std_logic;
  signal data_fifo_afull      : std_logic;
  signal data_fifo_dout       : std_logic_vector(95 downto 0);
  signal data_fifo_dout_sext  : std_logic_vector(127 downto 0);
  signal ts_int_secs          : std_logic_vector(31 downto 0);
  signal ts_frc_secs          : std_logic_vector(63 downto 0);

begin

  -- Set channel reset based on the channel enable bit
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      pipe_rst     <= srst or not adc_phy_rdy_l or not run;
      ext_sync_rst <= pipe_rst or not en_ext_sync;
    end if;
  end process;

  -- Sync to adc_dclk_div2_l domain
  process (adc_dclk_div2_l)
  begin
    if (rising_edge(adc_dclk_div2_l)) then
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
    dst_clk              => adc_dclk_div2_l,
    pls_o                => trig_fifo_wr
  );

  trigger_ip <= trigger_en or pri_busy_l;

  inst_ext_sync_intf : ii_ext_sync_s1p4
  port map (
    -- reset and clocks
    reset                => ext_sync_rst,
    clk_bufio            => adc_dclk,
    clk_bufr             => adc_dclk_div2_l,

    -- external sync input
    ext_sync_p           => ext_sync_p,
    ext_sync_n           => ext_sync_n,

    -- controls
    trigger_en           => trigger_ip,
    idelay_rst           => '0',
    idelay               => "00000",

    -- outputs
    ext_sync             => ext_sync,
    ext_sync_phase       => ext_sync_phase
  );

  trig_in <= ext_sync or sw_trig_demet;

  trigger_pri_inst : ii_trigger_pri
  port map (
    -- Reset and clock
    srst                 => pipe_rst,
    clk                  => adc_dclk_div2_l,

    -- Controls
    en_pri_trig          => en_pri_trig_demet,
    trig_in              => trig_in,
    stop_pri             => stop_pri_demet,
    pri_busy             => pri_busy_l,
    pri                  => pri,

    -- Parameter FIFO interface
    trig_fifo_rst        => srst,
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

  -- MUX on the trigger signals based on the PRI mode enable bit
  process (adc_dclk_div2_l)
  begin
    if (rising_edge(adc_dclk_div2_l)) then
      if (en_pri_trig_demet = '1') then
        sel_ext_sync   <= dig_trig_pls;
        sel_frame_size <= dig_trig_width;
      else
        sel_ext_sync   <= ext_sync;
        sel_frame_size <= window_size;
      end if;
      sel_en_framed_mode <= en_framed_mode or en_pri_trig_demet;
      sel_sw_trig        <= sw_trig_demet and not en_pri_trig_demet;
      sel_en_ext_sync    <= en_ext_sync or en_pri_trig_demet;
    end if;
  end process;

  sel_trig_mode <= sel_en_ext_sync & sel_en_framed_mode & trigger_mode(0);

  inst_trigger : ii_trigger
  generic map (
    SAMPLES_PER_CLK      => 4
  )
  port map (
    reset                => pipe_rst,
    clk                  => adc_dclk_div2_l,
    ce                   => run,
    ext_sync             => sel_ext_sync,
    sw_trig              => sel_sw_trig,
    trig_mode            => sel_trig_mode,
    frame_size           => sel_frame_size,
    decimation_coeff     => decimation,
    decimation_en        => decimation_en,
    trigger              => trigger,
    trigger_en           => trigger_en
  );

  adc_trigger <= trigger;

  -- ADC Interface
  inst_adc_intf : ii_ads5400_intf
  port map (
    -- Reset and clocks
    srst                 => srst,
    sys_clk              => sys_clk,
    ref_clk200           => ref_clk200,

    -- Controls
    idelayctrl_rst       => idelayctrl_rst,
    adc_phy_init         => adc_phy_init,
    skip_adc_phy_cal     => skip_adc_phy_cal,
    ch_en                => ch_en,
    run                  => run,
    test_en              => test_en,
    test_mode            => test_mode,
    gain                 => gain,
    offset               => offset,
    spi_access_strb      => spi_access_strb,
    spi_wdata            => spi_wdata,
    spi_addr             => spi_addr,
    spi_rd_wrn           => spi_rd_wrn,
    spi_rdy              => spi_rdy,
    spi_rdata_valid      => spi_rdata_valid,
    spi_rdata            => spi_rdata,
    trigger              => trigger,
    trigger_frame        => trigger_en,
    ext_sync_phase       => ext_sync_phase,
    data_fifo_afull      => data_fifo_afull,

    -- Status
    adc_eye_aligned      => adc_eye_aligned,
    adc_prbs_locked      => adc_prbs_locked,
    adc_prbs_aligned     => adc_prbs_aligned,
    adc_phy_rdy          => adc_phy_rdy_l,

    -- ADC interface
    adc_spi_sclk         => adc_spi_sclk,
    adc_spi_sdenb        => adc_spi_sdenb,
    adc_spi_sdio         => adc_spi_sdio,
    adc_reset_p          => adc_reset_p,
    adc_reset_n          => adc_reset_n,
    adc_da_dclk_p        => adc_da_dclk_p,
    adc_da_dclk_n        => adc_da_dclk_n,
    adc_da_p             => adc_da_p,
    adc_da_n             => adc_da_n,
    adc_ovra_p           => adc_ovra_p,
    adc_ovra_n           => adc_ovra_n,

    -- A/D data (sync'd to adc_dclk_div2)
    adc_dclk             => adc_dclk,
    adc_dclk_180         => adc_dclk_180,
    adc_dclk_div2        => adc_dclk_div2_l,
    adc_data_frame       => adc_data_frame,
    adc_data_vld         => adc_data_vld,
    adc_data             => adc_data,
    adc_ovr              => adc_ovr,
    adc_ovf              => adc_ovf
  );

  adc_phy_rdy   <= adc_phy_rdy_l;
  adc_dclk_div2 <= adc_dclk_div2_l;
  adc_raw_vld   <= adc_data_vld;
  adc_raw_data  <= adc_data;
  adc_raw_ovr   <= adc_ovr;
  adc_raw_ovf   <= adc_ovf;

  -- Sign extend the adc data to 64-bits (4 16-bits)
  process (adc_data)
  begin
    for i in 0 to 3 loop
      adc_data_sext(i*16+15 downto i*16) <=
      std_logic_vector(resize(signed(adc_data(i*12+11 downto i*12)),16));
    end loop;
  end process;

  -- VITA-49 framer
  inst_vita_framer : ii_vita_framer
  generic map (
    ibw                  => 64
  )
  port map (
    -- Reset and clocks
    srst                 => pipe_rst,
    sys_clk              => sys_clk,
    fs_clk               => adc_dclk_div2_l,

    -- Controls
    frame_size           => frame_size,
    stream_id            => stream_id,
    packet_type          => "0001",

    -- VITA-49 Timestamp interface
    ts_int_secs          => ts_int_secs,
    ts_frc_secs          => ts_frc_secs,
    tsi                  => ts_tsi,
    tsf                  => ts_tsf,

    -- Data source interface
    din_frame            => adc_data_frame,
    din_vld              => adc_data_vld,
    din                  => adc_data_sext,

    -- Data source FIFO interface
    src_fifo_afull       => data_fifo_afull,
    src_fifo_wren        => data_fifo_wren,
    src_fifo_din         => data_fifo_din_sext,
    src_fifo_empty       => data_fifo_empty,
    src_fifo_rden        => data_fifo_rden,
    src_fifo_vld         => data_fifo_valid,
    src_fifo_dout        => data_fifo_dout_sext,

    -- VITA-49 FIFO interface
    dst_fifo_empty       => adc_fifo_empty,
    dst_fifo_aempty      => adc_fifo_aempty,
    dst_fifo_rden        => adc_fifo_rden,
    dst_fifo_vld         => adc_fifo_vld,
    dst_fifo_dout        => adc_fifo_dout
  );

  -- Remove the sign extension bits to use smaller FIFOs
  -- (8X16-bits --> 8X12-bits)
  process (data_fifo_din_sext)
  begin
    for i in 0 to 7 loop
      data_fifo_din(i*12+11 downto i*12) <=
      data_fifo_din_sext(i*16+11 downto i*16);
    end loop;
  end process;

  -- Sign extend the FIFO's output data to 128-bits (8x16-bits)
  process (data_fifo_dout)
  begin
    for i in 0 to 7 loop
      data_fifo_dout_sext(i*16+15 downto i*16) <=
      std_logic_vector(resize(signed(data_fifo_dout(i*12+11 downto i*12)),16));
    end loop;
  end process;

  -- ADC data FIFO, 2K deep, 96-bit wide
  data_fifo : afifo_2kx96_bram
  port map (
    rst                  => pipe_rst,
    wr_clk               => adc_dclk_div2_l,
    rd_clk               => sys_clk,
    din                  => data_fifo_din,
    wr_en                => data_fifo_wren,
    rd_en                => data_fifo_rden,
    prog_empty_thresh    => ("000" & x"09"),
    prog_full_thresh     => ("111" & x"F0"),
    dout                 => data_fifo_dout,
    full                 => open,
    empty                => data_fifo_empty,
    valid                => data_fifo_valid,
    prog_full            => data_fifo_afull,
    prog_empty           => open
  );

  -- VITA-49 Timestamp
  vita_ts : ii_vita_ts
  generic map (
    G_SIM                => G_SIM,
    SYS_CLK_FREQ         => SYS_CLK_FREQ
  )
  port map (
    srst                 => srst,
    sys_clk              => sys_clk,
    fs_clk               => adc_dclk_div2_l,
    ts_initial           => ts_initial,
    ts_load              => ts_load,
    ts_arm               => ts_arm,
    pps_pls              => ts_pps_pls,
    pps_mode             => ts_pps_mode,
    tsf                  => ts_tsf,
    ts_int_secs          => ts_int_secs,
    ts_frc_secs          => ts_frc_secs
  );

  -- Alerts
  inst_adc_trig_alert : ii_trig_alert
  port map (
    rst_sys_clk          => pipe_rst,
    sys_clk              => sys_clk,
    rst_fs_clk           => pipe_rst,
    fs_clk               => adc_dclk_div2_l,
    trig_in              => trigger,
    trig_alert           => adc_trig_alrt
  );

  -- Generate an overrange alert whenever input overrange occurs
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (pipe_rst = '1') then
        ovr_xdom  <= '0';
        ovr_demet <= '0';
      else
        ovr_xdom  <= adc_ovr;
        ovr_demet <= ovr_xdom;
      end if;
    end if;
  end process;

  adc_overrange <= ovr_demet;

  -- The overflow alert should pulse high for several cycles upon
  -- the detection of the first overflow in the ADC interface to
  -- not mask the detection of other alerts on the same bus.
  -- Latch an overflow flag whenever an overflow occurs and detect
  -- a rising edge on it
  process (pipe_rst, adc_dclk_div2_l)
  begin
    if (pipe_rst = '1') then
      ovf_l    <= '0';
      ovf_l_d  <= '0';
      ovf_l_re <= '0';
    elsif (rising_edge(adc_dclk_div2_l)) then
      if (adc_ovf = '1') then
        ovf_l <= '1';
      end if;
      ovf_l_d  <= ovf_l;
      ovf_l_re <= ovf_l and not ovf_l_d;
    end if;
  end process;

  -- cross into sys_clk domain
  ovf_xdom : ii_xdom_pulse
  port map (
    src_clk              => adc_dclk_div2_l,
    pls_i                => ovf_l_re,
    dst_clk              => sys_clk,
    pls_o                => ovf_re
  );

  -- Generate the alert pulse
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (pipe_rst = '1') then
        ovf_re_sreg <= (others => '0');
      elsif (ovf_re = '1') then
        ovf_re_sreg <= (others => '1');
      else
        ovf_re_sreg <= ovf_re_sreg(ovf_re_sreg'high-1 downto 0) & '0';
      end if;
    end if;
  end process;

  adc_overflow <= ovf_re_sreg(ovf_re_sreg'high);

end arch;

