-- Copyright 2011 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design name: ii_afe_intf_top
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 13.2
--*
--*     @short Analog front end interface
--*
--* Description:
--*
--*   This component is the top level analog front end interface which includes
--*   intefaces to 2 ADS5400 ADCs, 2 DAC5682Z DACs, a CDCE72010 PLL, a wishbone
--*   slave, and trigger logic.
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 4/29/2011
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity ii_afe_intf_top is
  generic (
    G_SIM                : boolean;
    SYS_CLK_FREQ         : integer := 250;
    offset               : std_logic_vector(15 downto 0)
  );
  port (
    -- Reset and Clock
    srst                 : in    std_logic;
    sys_clk              : in    std_logic;

    -- reference clock
    ref_clk200           : in    std_logic;
    clk200_locked        : in    std_logic;

    -- Slave Wishbone interface
    wb_rst_i             : in    std_logic;
    wb_clk_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(15 downto 0);
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_we_i              : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_ack_o             : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- Alerts
    adc_trigger_o        : out   std_logic;
    dac_trigger_o        : out   std_logic;
    adc0_overrange       : out   std_logic;
    adc1_overrange       : out   std_logic;
    adc0_overflow        : out   std_logic;
    adc1_overflow        : out   std_logic;
    dac0_underflow       : out   std_logic;
    dac1_underflow       : out   std_logic;

    -- System interface
    ref_adc_clk          : out   std_logic;
    ref_dac_clk          : out   std_logic;
    adc_run_o            : out   std_logic;
    dac_run_o            : out   std_logic;

    -- DAC stream ID
    dac0_stream_id       : out std_logic_vector(15 downto 0);
    dac1_stream_id       : out std_logic_vector(15 downto 0);

    -- ADC0 fifo interface
    adc0_fifo_empty      : out   std_logic;
    adc0_fifo_aempty     : out   std_logic;
    adc0_fifo_rd         : in    std_logic;
    adc0_fifo_vld        : out   std_logic;
    adc0_fifo_dout       : out   std_logic_vector(127 downto 0);

    -- ADC1 fifo interface
    adc1_fifo_empty      : out   std_logic;
    adc1_fifo_aempty     : out   std_logic;
    adc1_fifo_rd         : in    std_logic;
    adc1_fifo_vld        : out   std_logic;
    adc1_fifo_dout       : out   std_logic_vector(127 downto 0);

    -- DAC0 data source fifo interface
    dac0_src_aempty      : in    std_logic;
    dac0_src_empty       : in    std_logic;
    dac0_src_rden        : out   std_logic;
    dac0_src_vld         : in    std_logic;
    dac0_src_din         : in    std_logic_vector(127 downto 0);

    -- DAC1 data source fifo interface
    dac1_src_aempty      : in    std_logic;
    dac1_src_empty       : in    std_logic;
    dac1_src_rden        : out   std_logic;
    dac1_src_vld         : in    std_logic;
    dac1_src_din         : in    std_logic_vector(127 downto 0);

    -- PLL interface
    pll_vcxo_en          : out   std_logic;
    pll_vcxo_scl         : out   std_logic;
    pll_vcxo_sda         : inout std_logic;
    pll_pwr_down_n       : out   std_logic;
    pll_reset_n          : out   std_logic;
    pll_spi_sclk         : out   std_logic;
    pll_spi_le           : out   std_logic;
    pll_spi_mosi         : out   std_logic;
    pll_spi_miso         : in    std_logic;
    pll_ext_clk_sel      : out   std_logic;
    pll_lock             : in    std_logic;
    ref_adc_clk_p        : in    std_logic;
    ref_adc_clk_n        : in    std_logic;
    ref_dac_clk_p        : in    std_logic;
    ref_dac_clk_n        : in    std_logic;

    -- External sync
    ext_sync_sel         : out   std_logic;
    adc0_ext_sync_p      : in    std_logic;
    adc0_ext_sync_n      : in    std_logic;
    adc1_ext_sync_p      : in    std_logic;
    adc1_ext_sync_n      : in    std_logic;
    dac0_ext_sync_p      : in    std_logic;
    dac0_ext_sync_n      : in    std_logic;
    dac1_ext_sync_p      : in    std_logic;
    dac1_ext_sync_n      : in    std_logic;

    -- ADC0 and ADC1 interface
    adc0_spi_sclk        : out   std_logic;
    adc0_spi_sdenb       : out   std_logic;
    adc0_spi_sdio        : inout std_logic;
    adc0_reset_p         : out   std_logic;
    adc0_reset_n         : out   std_logic;
    adc0_da_dclk_p       : in    std_logic;
    adc0_da_dclk_n       : in    std_logic;
    adc0_da_p            : in    std_logic_vector(11 downto 0);
    adc0_da_n            : in    std_logic_vector(11 downto 0);
    adc0_ovra_p          : in    std_logic;
    adc0_ovra_n          : in    std_logic;
    adc1_spi_sclk        : out   std_logic;
    adc1_spi_sdenb       : out   std_logic;
    adc1_spi_sdio        : inout std_logic;
    adc1_reset_p         : out   std_logic;
    adc1_reset_n         : out   std_logic;
    adc1_da_dclk_p       : in    std_logic;
    adc1_da_dclk_n       : in    std_logic;
    adc1_da_p            : in    std_logic_vector(11 downto 0);
    adc1_da_n            : in    std_logic_vector(11 downto 0);
    adc1_ovra_p          : in    std_logic;
    adc1_ovra_n          : in    std_logic;

    -- DAC0 and DAC1 interface signals
    dac0_resetb          : out   std_logic;
    dac0_spi_sclk        : out   std_logic;
    dac0_spi_sdenb       : out   std_logic;
    dac0_spi_sdio        : inout std_logic;
    dac0_spi_sdo         : in    std_logic;
    dac0_clk_in_p        : in    std_logic;
    dac0_clk_in_n        : in    std_logic;
    dac0_dclk_p          : out   std_logic;
    dac0_dclk_n          : out   std_logic;
    dac0_sync_p          : out   std_logic;
    dac0_sync_n          : out   std_logic;
    dac0_sync2_p         : out   std_logic;
    dac0_sync2_n         : out   std_logic;
    dac0_data_p          : out   std_logic_vector(15 downto 0);
    dac0_data_n          : out   std_logic_vector(15 downto 0);
    dac1_resetb          : out   std_logic;
    dac1_spi_sclk        : out   std_logic;
    dac1_spi_sdenb       : out   std_logic;
    dac1_spi_sdio        : inout std_logic;
    dac1_spi_sdo         : in    std_logic;
    dac1_clk_in_p        : in    std_logic;
    dac1_clk_in_n        : in    std_logic;
    dac1_dclk_p          : out   std_logic;
    dac1_dclk_n          : out   std_logic;
    dac1_sync_p          : out   std_logic;
    dac1_sync_n          : out   std_logic;
    dac1_sync2_p         : out   std_logic;
    dac1_sync2_n         : out   std_logic;
    dac1_data_p          : out   std_logic_vector(15 downto 0);
    dac1_data_n          : out   std_logic_vector(15 downto 0);

    -- DAC output digitizer interface
    dac_dig_en           : out   std_logic;
    dac0_dig_p           : in    std_logic;
    dac0_dig_n           : in    std_logic;
    dac1_dig_p           : in    std_logic;
    dac1_dig_n           : in    std_logic;

    -- PPS pulse input (ie. GPS)
    ts_pps_pls           : in    std_logic
  );
end ii_afe_intf_top;

architecture arch of ii_afe_intf_top is

  component ii_afe_intf_regs
    generic (
      addr_bits            : integer := 8;
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- Wishbone interface signals
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);

      -- User registers
      pll_pwr_down_n       : out std_logic;
      pll_reset_n          : out std_logic;
      pll_lock             : in  std_logic;
      pll_spi_rdy          : in  std_logic;
      pll_spi_rdata_valid  : in  std_logic;
      pll_spi_wr_strb      : out std_logic;
      pll_spi_addr         : out std_logic_vector(3 downto 0);
      pll_spi_wdata        : out std_logic_vector(27 downto 0);
      pll_spi_rdata        : in  std_logic_vector(31 downto 0);
      pll_vcxo_sdo         : out std_logic;
      pll_vcxo_scl         : out std_logic;
      pll_vcxo_sdi         : in  std_logic;
      pll_vcxo_en          : out std_logic;
      pll_ext_clk_sel      : out std_logic;
      adc_test_en          : out std_logic;
      adc_test_mode        : out std_logic;
      dac_test_en          : out std_logic;
      dac_test_mode        : out std_logic_vector(2 downto 0);
      adc_run              : out std_logic;
      dac_run              : out std_logic;
      adc_sw_trig          : out std_logic;
      dac_sw_trig          : out std_logic;
      ext_sync_sel         : out std_logic;
      adc_ch_en            : out std_logic_vector(1 downto 0);
      adc_pdwn_n           : out std_logic_vector(1 downto 0);
      adc_window_size      : out std_logic_vector(23 downto 0);
      adc_trigger_mode     : out std_logic_vector(2 downto 0);
      adc_decimation       : out std_logic_vector(11 downto 0);
      adc_en_pri_trig      : out std_logic;
      adc_stop_pri         : out std_logic;
      adc_pri_busy         : in  std_logic;
      adc_pri              : out std_logic_vector(31 downto 0);
      adc_trig_fifo_wr_strb: out std_logic;
      adc_trig_cycle_del   : out std_logic_vector(23 downto 0);
      adc_trig_width       : out std_logic_vector(23 downto 0);
      adc0_spi_access_strb : out std_logic;
      adc0_spi_wdata       : out std_logic_vector(7 downto 0);
      adc0_spi_addr        : out std_logic_vector(4 downto 0);
      adc0_spi_rd_wrn      : out std_logic;
      adc0_spi_rdy         : in  std_logic;
      adc0_spi_rdata_valid : in  std_logic;
      adc0_spi_rdata       : in  std_logic_vector(7 downto 0);
      adc1_spi_access_strb : out std_logic;
      adc1_spi_wdata       : out std_logic_vector(7 downto 0);
      adc1_spi_addr        : out std_logic_vector(4 downto 0);
      adc1_spi_rd_wrn      : out std_logic;
      adc1_spi_rdy         : in  std_logic;
      adc1_spi_rdata_valid : in  std_logic;
      adc1_spi_rdata       : in  std_logic_vector(7 downto 0);
      adc_phy_init         : out std_logic;
      skip_adc_phy_cal     : out std_logic;
      adc0_eye_aligned     : in  std_logic_vector(12 downto 0);
      adc0_prbs_locked     : in  std_logic;
      adc0_prbs_aligned    : in  std_logic;
      adc0_phy_rdy         : in  std_logic;
      adc1_eye_aligned     : in  std_logic_vector(12 downto 0);
      adc1_prbs_locked     : in  std_logic;
      adc1_prbs_aligned    : in  std_logic;
      adc1_phy_rdy         : in  std_logic;
      ts_initial           : out std_logic_vector(31 downto 0);
      ts_load              : out std_logic;
      ts_arm               : out std_logic;
      ts_pps_mode          : out std_logic;
      ts_tsi               : out std_logic_vector(1 downto 0);
      ts_tsf               : out std_logic_vector(1 downto 0);
      adc0_frame_size      : out std_logic_vector(15 downto 0);
      adc1_frame_size      : out std_logic_vector(15 downto 0);
      adc0_stream_id       : out std_logic_vector(31 downto 0);
      adc1_stream_id       : out std_logic_vector(31 downto 0);
      adc0_gain            : out std_logic_vector(11 downto 0);
      adc1_gain            : out std_logic_vector(11 downto 0);
      adc0_offset          : out std_logic_vector(8 downto 0);
      adc1_offset          : out std_logic_vector(8 downto 0);
      dac_ch_en            : out std_logic_vector(3 downto 0);
      dac_window_size      : out std_logic_vector(23 downto 0);
      dac_trigger_mode     : out std_logic_vector(2 downto 0);
      dac_reset            : out std_logic_vector(3 downto 0);
      phase_inc_wr         : out std_logic;
      phase_inc            : out std_logic_vector(31 downto 0);
      dac_en_pri_trig      : out std_logic;
      dac_stop_pri         : out std_logic;
      dac_pri_busy         : in  std_logic;
      dac_pri              : out std_logic_vector(31 downto 0);
      dac_trig_fifo_wr_strb: out std_logic;
      dac_trig_cycle_del   : out std_logic_vector(23 downto 0);
      dac_trig_width       : out std_logic_vector(23 downto 0);
      dac0_spi_access_strb : out std_logic;
      dac0_spi_wdata       : out std_logic_vector(7 downto 0);
      dac0_spi_addr        : out std_logic_vector(4 downto 0);
      dac0_spi_rd_wrn      : out std_logic;
      dac0_spi_sdo         : in  std_logic;
      dac0_spi_rdy         : in  std_logic;
      dac0_spi_rdata_valid : in  std_logic;
      dac0_spi_rdata       : in  std_logic_vector(7 downto 0);
      dac1_spi_access_strb : out std_logic;
      dac1_spi_wdata       : out std_logic_vector(7 downto 0);
      dac1_spi_addr        : out std_logic_vector(4 downto 0);
      dac1_spi_rd_wrn      : out std_logic;
      dac1_spi_sdo         : in  std_logic;
      dac1_spi_rdy         : in  std_logic;
      dac1_spi_rdata_valid : in  std_logic;
      dac1_spi_rdata       : in  std_logic_vector(7 downto 0);
      dac_cal_en           : out std_logic;
      dac0_cal0_done       : in  std_logic;
      dac0_cal1_done       : in  std_logic;
      dac1_cal0_done       : in  std_logic;
      dac1_cal1_done       : in  std_logic;
      dac0_iodly_cnt       : in  std_logic_vector(4 downto 0);
      dac1_iodly_cnt       : in  std_logic_vector(4 downto 0);
      dac0_shift_cnt       : in  std_logic_vector(3 downto 0);
      dac1_shift_cnt       : in  std_logic_vector(3 downto 0);
      dac0_stream_id       : out std_logic_vector(15 downto 0);
      dac1_stream_id       : out std_logic_vector(15 downto 0);
      dac0_a_gain          : out std_logic_vector(17 downto 0);
      dac0_b_gain          : out std_logic_vector(17 downto 0);
      dac1_a_gain          : out std_logic_vector(17 downto 0);
      dac1_b_gain          : out std_logic_vector(17 downto 0);
      dac0_a_offset        : out std_logic_vector(15 downto 0);
      dac0_b_offset        : out std_logic_vector(15 downto 0);
      dac1_a_offset        : out std_logic_vector(15 downto 0);
      dac1_b_offset        : out std_logic_vector(15 downto 0)
    );
  end component;

  component ii_cdce72010_spi
    port (
      srst                 : in  std_logic;
      clk                  : in  std_logic;

      -- User interface
      spi_wr_strb          : in  std_logic;
      spi_wdata            : in  std_logic_vector(27 downto 0);
      spi_addr             : in  std_logic_vector(3 downto 0);
      spi_rdy              : out std_logic;
      spi_rdata_valid      : out std_logic;
      spi_rdata            : out std_logic_vector(31 downto 0);

      -- PLL spi interface
      spi_sclk             : out std_logic;
      spi_le               : out std_logic;
      spi_mosi             : out std_logic;
      spi_miso             : in  std_logic
    );
  end component;

  component ii_dac5682z_intf_top
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
  end component;

  component ii_ads5400_intf_top
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
  end component;

  signal pll_spi_rdy          : std_logic;
  signal pll_spi_rdata_valid  : std_logic;
  signal pll_spi_wr_strb      : std_logic;
  signal pll_spi_addr         : std_logic_vector(3 downto 0);
  signal pll_spi_wdata        : std_logic_vector(27 downto 0);
  signal pll_spi_rdata        : std_logic_vector(31 downto 0);
  signal pll_vcxo_sdo         : std_logic;
  signal adc_test_en          : std_logic;
  signal adc_test_mode        : std_logic;
  signal dac_test_en          : std_logic;
  signal dac_test_mode        : std_logic_vector(2 downto 0);
  signal adc_run              : std_logic;
  signal dac_run              : std_logic;
  signal adc_sw_trig          : std_logic;
  signal dac_sw_trig          : std_logic;
  signal adc_ch_en            : std_logic_vector(1 downto 0);
  signal adc_pdwn_n           : std_logic_vector(1 downto 0);
  signal adc_window_size      : std_logic_vector(23 downto 0);
  signal adc_trigger_mode     : std_logic_vector(2 downto 0);
  signal adc_decimation       : std_logic_vector(11 downto 0);
  signal adc_en_pri_trig      : std_logic;
  signal adc_stop_pri         : std_logic;
  signal adc_pri_busy         : std_logic;
  signal adc_pri              : std_logic_vector(31 downto 0);
  signal adc_trig_fifo_wr_strb: std_logic;
  signal adc_trig_cycle_del   : std_logic_vector(23 downto 0);
  signal adc_trig_width       : std_logic_vector(23 downto 0);
  signal adc0_spi_access_strb : std_logic;
  signal adc0_spi_wdata       : std_logic_vector(7 downto 0);
  signal adc0_spi_addr        : std_logic_vector(4 downto 0);
  signal adc0_spi_rd_wrn      : std_logic;
  signal adc0_spi_rdy         : std_logic;
  signal adc0_spi_rdata_valid : std_logic;
  signal adc0_spi_rdata       : std_logic_vector(7 downto 0);
  signal adc1_spi_access_strb : std_logic;
  signal adc1_spi_wdata       : std_logic_vector(7 downto 0);
  signal adc1_spi_addr        : std_logic_vector(4 downto 0);
  signal adc1_spi_rd_wrn      : std_logic;
  signal adc1_spi_rdy         : std_logic;
  signal adc1_spi_rdata_valid : std_logic;
  signal adc1_spi_rdata       : std_logic_vector(7 downto 0);
  signal adc_phy_init         : std_logic;
  signal skip_adc_phy_cal     : std_logic;
  signal adc0_eye_aligned     : std_logic_vector(12 downto 0);
  signal adc0_prbs_locked     : std_logic;
  signal adc0_prbs_aligned    : std_logic;
  signal adc0_phy_rdy         : std_logic;
  signal adc1_eye_aligned     : std_logic_vector(12 downto 0);
  signal adc1_prbs_locked     : std_logic;
  signal adc1_prbs_aligned    : std_logic;
  signal adc1_phy_rdy         : std_logic;
  signal ts_initial           : std_logic_vector(31 downto 0);
  signal ts_load              : std_logic;
  signal ts_arm               : std_logic;
  signal ts_pps_mode          : std_logic;
  signal ts_tsi               : std_logic_vector(1 downto 0);
  signal ts_tsf               : std_logic_vector(1 downto 0);
  signal adc0_frame_size      : std_logic_vector(15 downto 0);
  signal adc1_frame_size      : std_logic_vector(15 downto 0);
  signal adc0_stream_id       : std_logic_vector(31 downto 0);
  signal adc1_stream_id       : std_logic_vector(31 downto 0);
  signal adc0_gain            : std_logic_vector(11 downto 0);
  signal adc1_gain            : std_logic_vector(11 downto 0);
  signal adc0_offset          : std_logic_vector(8 downto 0);
  signal adc1_offset          : std_logic_vector(8 downto 0);
  signal dac_ch_en            : std_logic_vector(3 downto 0);
  signal dac_window_size      : std_logic_vector(23 downto 0);
  signal dac_trigger_mode     : std_logic_vector(2 downto 0);
  signal dac_reset_reg        : std_logic_vector(3 downto 0);
  signal dac0_reset           : std_logic;
  signal dac1_reset           : std_logic;
  signal phase_inc_wr         : std_logic;
  signal phase_inc            : std_logic_vector(31 downto 0);
  signal dac_en_pri_trig      : std_logic;
  signal dac_stop_pri         : std_logic;
  signal dac_pri_busy         : std_logic;
  signal dac_pri              : std_logic_vector(31 downto 0);
  signal dac_trig_fifo_wr_strb: std_logic;
  signal dac_trig_cycle_del   : std_logic_vector(23 downto 0);
  signal dac_trig_width       : std_logic_vector(23 downto 0);
  signal dac0_spi_access_strb : std_logic;
  signal dac0_spi_wdata       : std_logic_vector(7 downto 0);
  signal dac0_spi_addr        : std_logic_vector(4 downto 0);
  signal dac0_spi_rd_wrn      : std_logic;
  signal dac0_spi_rdy         : std_logic;
  signal dac0_spi_rdata_valid : std_logic;
  signal dac0_spi_rdata       : std_logic_vector(7 downto 0);
  signal dac1_spi_access_strb : std_logic;
  signal dac1_spi_wdata       : std_logic_vector(7 downto 0);
  signal dac1_spi_addr        : std_logic_vector(4 downto 0);
  signal dac1_spi_rd_wrn      : std_logic;
  signal dac1_spi_rdy         : std_logic;
  signal dac1_spi_rdata_valid : std_logic;
  signal dac1_spi_rdata       : std_logic_vector(7 downto 0);
  signal dac_cal_en           : std_logic;
  signal dac0_cal0_done       : std_logic;
  signal dac0_cal1_done       : std_logic;
  signal dac1_cal0_done       : std_logic;
  signal dac1_cal1_done       : std_logic;
  signal dac0_iodly_cnt       : std_logic_vector(4 downto 0);
  signal dac1_iodly_cnt       : std_logic_vector(4 downto 0);
  signal dac0_shift_cnt       : std_logic_vector(3 downto 0);
  signal dac1_shift_cnt       : std_logic_vector(3 downto 0);
  signal dac0_a_gain          : std_logic_vector(17 downto 0);
  signal dac0_b_gain          : std_logic_vector(17 downto 0);
  signal dac1_a_gain          : std_logic_vector(17 downto 0);
  signal dac1_b_gain          : std_logic_vector(17 downto 0);
  signal dac0_a_offset        : std_logic_vector(15 downto 0);
  signal dac0_b_offset        : std_logic_vector(15 downto 0);
  signal dac1_a_offset        : std_logic_vector(15 downto 0);
  signal dac1_b_offset        : std_logic_vector(15 downto 0);
  signal clk200_locked_d      : std_logic;
  signal clk200_locked_dd     : std_logic;
  signal clk200_locked_re     : std_logic;
  signal idelayctrl_rst_sreg  : std_logic_vector(9 downto 0);
  signal idelayctrl_rst       : std_logic;
  signal dac0_spi_sdo_xdom    : std_logic;
  signal dac0_spi_sdo_demet   : std_logic;
  signal dac0_resetb_sreg     : std_logic_vector(7 downto 0);
  signal dac1_spi_sdo_xdom    : std_logic;
  signal dac1_spi_sdo_demet   : std_logic;
  signal dac1_resetb_sreg     : std_logic_vector(7 downto 0);
  signal ref_adc_clk_ibufg    : std_logic;
  signal ref_adc_clk_bufg     : std_logic;
  signal ref_dac_clk_ibufg    : std_logic;
  signal ref_dac_clk_bufg     : std_logic;
  signal adc0_rst             : std_logic;
  signal adc1_rst             : std_logic;
  signal adc0_trig_alert      : std_logic;
  signal adc1_trig_alert      : std_logic;
  signal dac0_trig_alrt       : std_logic;
  signal dac1_trig_alrt       : std_logic;
  signal adc0_pri_busy        : std_logic;
  signal adc1_pri_busy        : std_logic;
  signal dac0_pri_busy        : std_logic;
  signal dac1_pri_busy        : std_logic;
  signal dac0_src_aempty_d    : std_logic;
  signal dac0_src_empty_d     : std_logic;
  signal dac0_src_vld_d       : std_logic;
  signal dac0_src_din_d       : std_logic_vector(127 downto 0);
  signal dac1_src_aempty_d    : std_logic;
  signal dac1_src_empty_d     : std_logic;
  signal dac1_src_vld_d       : std_logic;
  signal dac1_src_din_d       : std_logic_vector(127 downto 0);

begin

-----------------------------------------------------------------------------
-- Instantiate AFE registers
-----------------------------------------------------------------------------
  inst_afe_regs: ii_afe_intf_regs
  generic map (
    addr_bits            => 8,
    offset               => offset
  )
  port map (
    -- Wishbone interface signals
    wb_rst_i             => wb_rst_i,
    wb_clk_i             => wb_clk_i,
    wb_adr_i             => wb_adr_i,
    wb_dat_i             => wb_dat_i,
    wb_we_i              => wb_we_i,
    wb_stb_i             => wb_stb_i,
    wb_ack_o             => wb_ack_o,
    wb_dat_o             => wb_dat_o,

    -- User registers
    pll_pwr_down_n       => pll_pwr_down_n,
    pll_reset_n          => pll_reset_n,
    pll_lock             => pll_lock,
    pll_spi_rdy          => pll_spi_rdy,
    pll_spi_rdata_valid  => pll_spi_rdata_valid,
    pll_spi_wr_strb      => pll_spi_wr_strb,
    pll_spi_addr         => pll_spi_addr,
    pll_spi_wdata        => pll_spi_wdata,
    pll_spi_rdata        => pll_spi_rdata,
    pll_vcxo_sdo         => pll_vcxo_sdo,
    pll_vcxo_scl         => pll_vcxo_scl,
    pll_vcxo_sdi         => pll_vcxo_sda,
    pll_vcxo_en          => pll_vcxo_en,
    pll_ext_clk_sel      => pll_ext_clk_sel,
    adc_test_en          => adc_test_en,
    adc_test_mode        => adc_test_mode,
    dac_test_en          => dac_test_en,
    dac_test_mode        => dac_test_mode,
    adc_run              => adc_run,
    dac_run              => dac_run,
    adc_sw_trig          => adc_sw_trig,
    dac_sw_trig          => dac_sw_trig,
    ext_sync_sel         => ext_sync_sel,
    adc_ch_en            => adc_ch_en,
    adc_pdwn_n           => adc_pdwn_n,
    adc_window_size      => adc_window_size,
    adc_trigger_mode     => adc_trigger_mode,
    adc_decimation       => adc_decimation,
    adc_en_pri_trig      => adc_en_pri_trig,
    adc_stop_pri         => adc_stop_pri,
    adc_pri_busy         => adc_pri_busy,
    adc_pri              => adc_pri,
    adc_trig_fifo_wr_strb=> adc_trig_fifo_wr_strb,
    adc_trig_cycle_del   => adc_trig_cycle_del,
    adc_trig_width       => adc_trig_width,
    adc0_spi_access_strb => adc0_spi_access_strb,
    adc0_spi_wdata       => adc0_spi_wdata,
    adc0_spi_addr        => adc0_spi_addr,
    adc0_spi_rd_wrn      => adc0_spi_rd_wrn,
    adc0_spi_rdy         => adc0_spi_rdy,
    adc0_spi_rdata_valid => adc0_spi_rdata_valid,
    adc0_spi_rdata       => adc0_spi_rdata,
    adc1_spi_access_strb => adc1_spi_access_strb,
    adc1_spi_wdata       => adc1_spi_wdata,
    adc1_spi_addr        => adc1_spi_addr,
    adc1_spi_rd_wrn      => adc1_spi_rd_wrn,
    adc1_spi_rdy         => adc1_spi_rdy,
    adc1_spi_rdata_valid => adc1_spi_rdata_valid,
    adc1_spi_rdata       => adc1_spi_rdata,
    adc_phy_init         => adc_phy_init,
    skip_adc_phy_cal     => skip_adc_phy_cal,
    adc0_eye_aligned     => adc0_eye_aligned,
    adc0_prbs_locked     => adc0_prbs_locked,
    adc0_prbs_aligned    => adc0_prbs_aligned,
    adc0_phy_rdy         => adc0_phy_rdy,
    adc1_eye_aligned     => adc1_eye_aligned,
    adc1_prbs_locked     => adc1_prbs_locked,
    adc1_prbs_aligned    => adc1_prbs_aligned,
    adc1_phy_rdy         => adc1_phy_rdy,
    ts_initial           => ts_initial,
    ts_load              => ts_load,
    ts_arm               => ts_arm,
    ts_pps_mode          => ts_pps_mode,
    ts_tsi               => ts_tsi,
    ts_tsf               => ts_tsf,
    adc0_frame_size      => adc0_frame_size,
    adc1_frame_size      => adc1_frame_size,
    adc0_stream_id       => adc0_stream_id,
    adc1_stream_id       => adc1_stream_id,
    adc0_gain            => adc0_gain,
    adc1_gain            => adc1_gain,
    adc0_offset          => adc0_offset,
    adc1_offset          => adc1_offset,
    dac_ch_en            => dac_ch_en,
    dac_window_size      => dac_window_size,
    dac_trigger_mode     => dac_trigger_mode,
    dac_reset            => dac_reset_reg,
    phase_inc_wr         => phase_inc_wr,
    phase_inc            => phase_inc,
    dac_en_pri_trig      => dac_en_pri_trig,
    dac_stop_pri         => dac_stop_pri,
    dac_pri_busy         => dac_pri_busy,
    dac_pri              => dac_pri,
    dac_trig_fifo_wr_strb=> dac_trig_fifo_wr_strb,
    dac_trig_cycle_del   => dac_trig_cycle_del,
    dac_trig_width       => dac_trig_width,
    dac0_spi_access_strb => dac0_spi_access_strb,
    dac0_spi_wdata       => dac0_spi_wdata,
    dac0_spi_addr        => dac0_spi_addr,
    dac0_spi_rd_wrn      => dac0_spi_rd_wrn,
    dac0_spi_sdo         => dac0_spi_sdo_demet,
    dac0_spi_rdy         => dac0_spi_rdy,
    dac0_spi_rdata_valid => dac0_spi_rdata_valid,
    dac0_spi_rdata       => dac0_spi_rdata,
    dac1_spi_access_strb => dac1_spi_access_strb,
    dac1_spi_wdata       => dac1_spi_wdata,
    dac1_spi_addr        => dac1_spi_addr,
    dac1_spi_rd_wrn      => dac1_spi_rd_wrn,
    dac1_spi_sdo         => dac1_spi_sdo_demet,
    dac1_spi_rdy         => dac1_spi_rdy,
    dac1_spi_rdata_valid => dac1_spi_rdata_valid,
    dac1_spi_rdata       => dac1_spi_rdata,
    dac_cal_en           => dac_cal_en,
    dac0_cal0_done       => dac0_cal0_done,
    dac0_cal1_done       => dac0_cal1_done,
    dac1_cal0_done       => dac1_cal0_done,
    dac1_cal1_done       => dac1_cal1_done,
    dac0_iodly_cnt       => dac0_iodly_cnt,
    dac1_iodly_cnt       => dac1_iodly_cnt,
    dac0_shift_cnt       => dac0_shift_cnt,
    dac1_shift_cnt       => dac1_shift_cnt,
    dac0_stream_id       => dac0_stream_id,
    dac1_stream_id       => dac1_stream_id,
    dac0_a_gain          => dac0_a_gain,
    dac0_b_gain          => dac0_b_gain,
    dac1_a_gain          => dac1_a_gain,
    dac1_b_gain          => dac1_b_gain,
    dac0_a_offset        => dac0_a_offset,
    dac0_b_offset        => dac0_b_offset,
    dac1_a_offset        => dac1_a_offset,
    dac1_b_offset        => dac1_b_offset
  );

  adc_run_o <= adc_run;
  dac_run_o <= dac_run;

  dac0_reset <= dac_reset_reg(0);
  dac1_reset <= dac_reset_reg(2);

-----------------------------------------------------------------------------
-- Misc logic
-----------------------------------------------------------------------------
  -- Detect a rising edge on clk200_locked and generate a synchronous
  -- active high idelayctrl_rst for at least 50ns after ref_clk200 stabilizes
  process (ref_clk200)
  begin
    if (rising_edge(ref_clk200)) then
      clk200_locked_d  <= clk200_locked;
      clk200_locked_dd <= clk200_locked_d;
      clk200_locked_re <= clk200_locked_d and not clk200_locked_dd;
      if (clk200_locked_re = '1') then
        idelayctrl_rst_sreg <= (others => '1');
      else
        idelayctrl_rst_sreg <= (idelayctrl_rst_sreg(8 downto 0) & '0');
      end if;
      idelayctrl_rst <= idelayctrl_rst_sreg(9);
    end if;
  end process;

  -- Sync dac_spi_sdo to sys_clk domain
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      dac0_spi_sdo_xdom  <= dac0_spi_sdo;
      dac0_spi_sdo_demet <= dac0_spi_sdo_xdom;
      dac1_spi_sdo_xdom  <= dac1_spi_sdo;
      dac1_spi_sdo_demet <= dac1_spi_sdo_xdom;
    end if;
  end process;

  -- dac_reset should be toggled by the software when CLKIN/C clock inputs to
  -- the DAC5682z chips are stable.
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (dac0_reset = '1') then
        dac0_resetb_sreg <= (others => '0');
      else
        dac0_resetb_sreg <= (dac0_resetb_sreg(dac0_resetb_sreg'high-1 downto 0) & '1');
      end if;
      if (dac1_reset = '1') then
        dac1_resetb_sreg <= (others => '0');
      else
        dac1_resetb_sreg <= (dac1_resetb_sreg(dac1_resetb_sreg'high-1 downto 0) & '1');
      end if;
    end if;
  end process;

  dac0_resetb <= 'Z' when (dac0_resetb_sreg(dac0_resetb_sreg'high) = '1') else '0';
  dac1_resetb <= 'Z' when (dac1_resetb_sreg(dac1_resetb_sreg'high) = '1') else '0';

  -- Instantiate an extra IDELAYCTRL since DAC0 ports
  -- span into FPGA bank 16
  inst_idelayctrl : IDELAYCTRL
  port map (
    rdy                  => open,
    refclk               => ref_clk200,
    rst                  => idelayctrl_rst
  );

-----------------------------------------------------------------------------
-- Instantiate cdce72010 pll spi control interface
-----------------------------------------------------------------------------
  inst_pll : ii_cdce72010_spi
  port map (
    srst                 => srst,
    clk                  => sys_clk,

    -- User interface
    spi_wr_strb          => pll_spi_wr_strb,
    spi_wdata            => pll_spi_wdata,
    spi_addr             => pll_spi_addr,
    spi_rdy              => pll_spi_rdy,
    spi_rdata_valid      => pll_spi_rdata_valid,
    spi_rdata            => pll_spi_rdata,

    -- PLL spi interface
    spi_sclk             => pll_spi_sclk,
    spi_le               => pll_spi_le,
    spi_mosi             => pll_spi_mosi,
    spi_miso             => pll_spi_miso
  );

  -- pll vcxo i2c data
  pll_vcxo_sda <= '0' when (pll_vcxo_sdo = '0') else 'Z';

-----------------------------------------------------------------------------
-- Instantiate DAC interfaces
-----------------------------------------------------------------------------
  inst_dac0_intf : ii_dac5682z_intf_top
  port map (
    -- Resets and clocks
    srst                 => srst,
    dac_reset            => dac0_reset,
    sys_clk              => sys_clk,

    -- Control
    dac_ch_en            => dac_ch_en(1 downto 0),
    dac_run              => dac_run,
    test_en              => dac_test_en,
    test_mode            => dac_test_mode,
    phase_inc_wr         => phase_inc_wr,
    phase_inc            => phase_inc,
    sw_trig              => dac_sw_trig,
    window_size          => dac_window_size,
    trigger_mode         => dac_trigger_mode,
    en_pri_trig          => dac_en_pri_trig,
    stop_pri             => dac_stop_pri,
    pri_busy             => dac0_pri_busy,
    pri                  => dac_pri,
    trig_fifo_wr_strb    => dac_trig_fifo_wr_strb,
    trig_cycle_del       => dac_trig_cycle_del,
    trig_width           => dac_trig_width,
    dac_spi_access_strb  => dac0_spi_access_strb,
    dac_spi_wdata        => dac0_spi_wdata,
    dac_spi_addr         => dac0_spi_addr,
    dac_spi_rd_wrn       => dac0_spi_rd_wrn,
    dac_spi_rdy          => dac0_spi_rdy,
    dac_spi_rdata_valid  => dac0_spi_rdata_valid,
    dac_spi_rdata        => dac0_spi_rdata,
    dac_a_gain           => dac0_a_gain,
    dac_a_offset         => dac0_a_offset,
    dac_b_gain           => dac0_b_gain,
    dac_b_offset         => dac0_b_offset,

    -- Latency calibration control and status
    dac_cal_en           => dac_cal_en,
    dac_cal0_done        => dac0_cal0_done,
    dac_cal1_done        => dac0_cal1_done,
    dac_iodly_cnt        => dac0_iodly_cnt,
    dac_shift_cnt        => dac0_shift_cnt,

    -- Alerts
    dac_trig_alrt        => dac0_trig_alrt,
    underflow            => dac0_underflow,

    -- Data fifo interface
    dac_src_aempty       => dac0_src_aempty_d,
    dac_src_empty        => dac0_src_empty_d,
    dac_src_rden         => dac0_src_rden,
    dac_src_vld          => dac0_src_vld_d,
    dac_src_din          => dac0_src_din_d,

    -- reference clock
    idelayctrl_rst       => idelayctrl_rst,
    ref_clk200           => ref_clk200,

    -- DAC external sync
    dac_ext_sync_p       => dac0_ext_sync_p,
    dac_ext_sync_n       => dac0_ext_sync_n,

    -- DAC output digitizer interface
    dac_dig_p            => dac0_dig_p,
    dac_dig_n            => dac0_dig_n,

    -- DAC interface signals
    dac_spi_sclk         => dac0_spi_sclk,
    dac_spi_sdenb        => dac0_spi_sdenb,
    dac_spi_sdio         => dac0_spi_sdio,
    dac_clk_in_p         => dac0_clk_in_p,
    dac_clk_in_n         => dac0_clk_in_n,
    dac_clk_out_p        => dac0_dclk_p,
    dac_clk_out_n        => dac0_dclk_n,
    sync_out_p           => dac0_sync_p,
    sync_out_n           => dac0_sync_n,
    sync2_out_p          => dac0_sync2_p,
    sync2_out_n          => dac0_sync2_n,
    data_out_p           => dac0_data_p,
    data_out_n           => dac0_data_n
  );

  inst_dac1_intf : ii_dac5682z_intf_top
  port map (
    -- Resets and clocks
    srst                 => srst,
    dac_reset            => dac1_reset,
    sys_clk              => sys_clk,

    -- Control
    dac_ch_en            => dac_ch_en(3 downto 2),
    dac_run              => dac_run,
    test_en              => dac_test_en,
    test_mode            => dac_test_mode,
    phase_inc_wr         => phase_inc_wr,
    phase_inc            => phase_inc,
    sw_trig              => dac_sw_trig,
    window_size          => dac_window_size,
    trigger_mode         => dac_trigger_mode,
    en_pri_trig          => dac_en_pri_trig,
    stop_pri             => dac_stop_pri,
    pri_busy             => dac1_pri_busy,
    pri                  => dac_pri,
    trig_fifo_wr_strb    => dac_trig_fifo_wr_strb,
    trig_cycle_del       => dac_trig_cycle_del,
    trig_width           => dac_trig_width,
    dac_spi_access_strb  => dac1_spi_access_strb,
    dac_spi_wdata        => dac1_spi_wdata,
    dac_spi_addr         => dac1_spi_addr,
    dac_spi_rd_wrn       => dac1_spi_rd_wrn,
    dac_spi_rdy          => dac1_spi_rdy,
    dac_spi_rdata_valid  => dac1_spi_rdata_valid,
    dac_spi_rdata        => dac1_spi_rdata,
    dac_a_gain           => dac1_a_gain,
    dac_a_offset         => dac1_a_offset,
    dac_b_gain           => dac1_b_gain,
    dac_b_offset         => dac1_b_offset,

    -- Latency calibration control and status
    dac_cal_en           => dac_cal_en,
    dac_cal0_done        => dac1_cal0_done,
    dac_cal1_done        => dac1_cal1_done,
    dac_iodly_cnt        => dac1_iodly_cnt,
    dac_shift_cnt        => dac1_shift_cnt,

    -- Alerts
    dac_trig_alrt        => dac1_trig_alrt,
    underflow            => dac1_underflow,

    -- Data fifo interface
    dac_src_aempty       => dac1_src_aempty_d,
    dac_src_empty        => dac1_src_empty_d,
    dac_src_rden         => dac1_src_rden,
    dac_src_vld          => dac1_src_vld_d,
    dac_src_din          => dac1_src_din_d,

    -- reference clock
    idelayctrl_rst       => idelayctrl_rst,
    ref_clk200           => ref_clk200,

    -- DAC external sync
    dac_ext_sync_p       => dac1_ext_sync_p,
    dac_ext_sync_n       => dac1_ext_sync_n,

    -- DAC output digitizer interface
    dac_dig_p            => dac1_dig_p,
    dac_dig_n            => dac1_dig_n,

    -- DAC interface signals
    dac_spi_sclk         => dac1_spi_sclk,
    dac_spi_sdenb        => dac1_spi_sdenb,
    dac_spi_sdio         => dac1_spi_sdio,
    dac_clk_in_p         => dac1_clk_in_p,
    dac_clk_in_n         => dac1_clk_in_n,
    dac_clk_out_p        => dac1_dclk_p,
    dac_clk_out_n        => dac1_dclk_n,
    sync_out_p           => dac1_sync_p,
    sync_out_n           => dac1_sync_n,
    sync2_out_p          => dac1_sync2_p,
    sync2_out_n          => dac1_sync2_n,
    data_out_p           => dac1_data_p,
    data_out_n           => dac1_data_n
  );

  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      dac_trigger_o     <= dac0_trig_alrt or dac1_trig_alrt;
      dac0_src_aempty_d <= dac0_src_aempty;
      dac0_src_empty_d  <= dac0_src_empty;
      dac0_src_vld_d    <= dac0_src_vld;
      dac0_src_din_d    <= dac0_src_din;
      dac1_src_aempty_d <= dac1_src_aempty;
      dac1_src_empty_d  <= dac1_src_empty;
      dac1_src_vld_d    <= dac1_src_vld;
      dac1_src_din_d    <= dac1_src_din;
      dac_dig_en        <= dac_cal_en;
    end if;
  end process;

-----------------------------------------------------------------------------
-- Reference clocks differential input buffering
-----------------------------------------------------------------------------
  inst_ref_adc_clk_ibufgds : IBUFGDS
  generic map (
    IOSTANDARD           => "DEFAULT"
  )
  port map (
    O                    => ref_adc_clk_ibufg,
    I                    => ref_adc_clk_p,
    IB                   => ref_adc_clk_n
  );

  -- Put clock on global routing (alternatively to MMCM)
  inst_ref_adc_clk_bufg : BUFG
  port map (
    O                    => ref_adc_clk_bufg,
    I                    => ref_adc_clk_ibufg
  );

  ref_adc_clk <= ref_adc_clk_bufg;

  inst_ref_dac_clk_ibufgds : IBUFGDS
  generic map (
    IOSTANDARD           => "DEFAULT"
  )
  port map (
    O                    => ref_dac_clk_ibufg,
    I                    => ref_dac_clk_p,
    IB                   => ref_dac_clk_n
  );

  -- Put clock on global routing (alternatively to MMCM)
  inst_ref_dac_clk_bufg : BUFG
  port map (
    O                    => ref_dac_clk_bufg,
    I                    => ref_dac_clk_ibufg
  );

  ref_dac_clk <= ref_dac_clk_bufg;

-----------------------------------------------------------------------------
-- Instantiate ADC interfaces
-----------------------------------------------------------------------------
  -- Reset the powered down ADC
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      adc0_rst <= srst or not adc_pdwn_n(0);
      adc1_rst <= srst or not adc_pdwn_n(1);
    end if;
  end process;

  inst_adc0: ii_ads5400_intf_top
  generic map (
    G_SIM                => G_SIM,
    SYS_CLK_FREQ         => SYS_CLK_FREQ
  )
  port map (
    -- Reset and clocks
    srst                 => adc0_rst,
    sys_clk              => sys_clk,
    ref_clk200           => ref_clk200,

    -- Controls
    idelayctrl_rst       => idelayctrl_rst,
    adc_phy_init         => adc_phy_init,
    skip_adc_phy_cal     => skip_adc_phy_cal,
    ch_en                => adc_ch_en(0),
    run                  => adc_run,
    sw_trig              => adc_sw_trig,
    window_size          => adc_window_size,
    trigger_mode         => adc_trigger_mode,
    decimation           => adc_decimation,
    en_pri_trig          => adc_en_pri_trig,
    stop_pri             => adc_stop_pri,
    pri_busy             => adc0_pri_busy,
    pri                  => adc_pri,
    trig_fifo_wr_strb    => adc_trig_fifo_wr_strb,
    trig_cycle_del       => adc_trig_cycle_del,
    trig_width           => adc_trig_width,
    test_en              => adc_test_en,
    test_mode            => adc_test_mode,
    gain                 => adc0_gain,
    offset               => adc0_offset,
    frame_size           => adc0_frame_size,
    stream_id            => adc0_stream_id,
    ts_initial           => ts_initial,
    ts_load              => ts_load,
    ts_arm               => ts_arm,
    ts_pps_mode          => ts_pps_mode,
    ts_pps_pls           => ts_pps_pls,
    ts_tsi               => ts_tsi,
    ts_tsf               => ts_tsf,
    spi_access_strb      => adc0_spi_access_strb,
    spi_wdata            => adc0_spi_wdata,
    spi_addr             => adc0_spi_addr,
    spi_rd_wrn           => adc0_spi_rd_wrn,
    spi_rdy              => adc0_spi_rdy,
    spi_rdata_valid      => adc0_spi_rdata_valid,
    spi_rdata            => adc0_spi_rdata,

    -- Status
    adc_eye_aligned      => adc0_eye_aligned,
    adc_prbs_locked      => adc0_prbs_locked,
    adc_prbs_aligned     => adc0_prbs_aligned,
    adc_phy_rdy          => adc0_phy_rdy,

    -- Alerts
    adc_trig_alrt        => adc0_trig_alert,
    adc_overrange        => adc0_overrange,
    adc_overflow         => adc0_overflow,

    -- ADC external sync
    ext_sync_p           => adc0_ext_sync_p,
    ext_sync_n           => adc0_ext_sync_n,

    -- ADC VITA-49 framer interface
    adc_fifo_empty       => adc0_fifo_empty,
    adc_fifo_aempty      => adc0_fifo_aempty,
    adc_fifo_rden        => adc0_fifo_rd,
    adc_fifo_vld         => adc0_fifo_vld,
    adc_fifo_dout        => adc0_fifo_dout,

    -- ADC data (sync'd to adc_dclk_div2)
    adc_dclk_div2        => open,
    adc_raw_vld          => open,
    adc_raw_data         => open,
    adc_raw_ovr          => open,
    adc_raw_ovf          => open,
    adc_trigger          => open,

    -- ADC interface
    adc_spi_sclk         => adc0_spi_sclk,
    adc_spi_sdenb        => adc0_spi_sdenb,
    adc_spi_sdio         => adc0_spi_sdio,
    adc_reset_p          => adc0_reset_p,
    adc_reset_n          => adc0_reset_n,
    adc_da_dclk_p        => adc0_da_dclk_p,
    adc_da_dclk_n        => adc0_da_dclk_n,
    adc_da_p             => adc0_da_p,
    adc_da_n             => adc0_da_n,
    adc_ovra_p           => adc0_ovra_p,
    adc_ovra_n           => adc0_ovra_n
  );

  inst_adc1: ii_ads5400_intf_top
  generic map (
    G_SIM                => G_SIM,
    SYS_CLK_FREQ         => SYS_CLK_FREQ
  )
  port map (
    -- Reset and clocks
    srst                 => adc1_rst,
    sys_clk              => sys_clk,
    ref_clk200           => ref_clk200,

    -- Controls
    idelayctrl_rst       => idelayctrl_rst,
    adc_phy_init         => adc_phy_init,
    skip_adc_phy_cal     => skip_adc_phy_cal,
    ch_en                => adc_ch_en(1),
    run                  => adc_run,
    sw_trig              => adc_sw_trig,
    window_size          => adc_window_size,
    trigger_mode         => adc_trigger_mode,
    decimation           => adc_decimation,
    en_pri_trig          => adc_en_pri_trig,
    stop_pri             => adc_stop_pri,
    pri_busy             => adc1_pri_busy,
    pri                  => adc_pri,
    trig_fifo_wr_strb    => adc_trig_fifo_wr_strb,
    trig_cycle_del       => adc_trig_cycle_del,
    trig_width           => adc_trig_width,
    test_en              => adc_test_en,
    test_mode            => adc_test_mode,
    gain                 => adc1_gain,
    offset               => adc1_offset,
    frame_size           => adc1_frame_size,
    stream_id            => adc1_stream_id,
    ts_initial           => ts_initial,
    ts_load              => ts_load,
    ts_arm               => ts_arm,
    ts_pps_mode          => ts_pps_mode,
    ts_pps_pls           => ts_pps_pls,
    ts_tsi               => ts_tsi,
    ts_tsf               => ts_tsf,
    spi_access_strb      => adc1_spi_access_strb,
    spi_wdata            => adc1_spi_wdata,
    spi_addr             => adc1_spi_addr,
    spi_rd_wrn           => adc1_spi_rd_wrn,
    spi_rdy              => adc1_spi_rdy,
    spi_rdata_valid      => adc1_spi_rdata_valid,
    spi_rdata            => adc1_spi_rdata,

    -- Status
    adc_eye_aligned      => adc1_eye_aligned,
    adc_prbs_locked      => adc1_prbs_locked,
    adc_prbs_aligned     => adc1_prbs_aligned,
    adc_phy_rdy          => adc1_phy_rdy,

    -- Alerts
    adc_trig_alrt        => adc1_trig_alert,
    adc_overrange        => adc1_overrange,
    adc_overflow         => adc1_overflow,

    -- ADC external sync
    ext_sync_p           => adc1_ext_sync_p,
    ext_sync_n           => adc1_ext_sync_n,

    -- ADC VITA-49 framer interface
    adc_fifo_empty       => adc1_fifo_empty,
    adc_fifo_aempty      => adc1_fifo_aempty,
    adc_fifo_rden        => adc1_fifo_rd,
    adc_fifo_vld         => adc1_fifo_vld,
    adc_fifo_dout        => adc1_fifo_dout,

    -- ADC data (sync'd to adc_dclk_div2)
    adc_dclk_div2        => open,
    adc_raw_vld          => open,
    adc_raw_data         => open,
    adc_raw_ovr          => open,
    adc_raw_ovf          => open,
    adc_trigger          => open,

    -- ADC interface
    adc_spi_sclk         => adc1_spi_sclk,
    adc_spi_sdenb        => adc1_spi_sdenb,
    adc_spi_sdio         => adc1_spi_sdio,
    adc_reset_p          => adc1_reset_p,
    adc_reset_n          => adc1_reset_n,
    adc_da_dclk_p        => adc1_da_dclk_p,
    adc_da_dclk_n        => adc1_da_dclk_n,
    adc_da_p             => adc1_da_p,
    adc_da_n             => adc1_da_n,
    adc_ovra_p           => adc1_ovra_p,
    adc_ovra_n           => adc1_ovra_n
  );

  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      adc_trigger_o <= adc0_trig_alert or adc1_trig_alert;
      adc_pri_busy  <= adc0_pri_busy or adc1_pri_busy;
      dac_pri_busy  <= dac0_pri_busy or dac1_pri_busy;
    end if;
  end process;

end arch;
