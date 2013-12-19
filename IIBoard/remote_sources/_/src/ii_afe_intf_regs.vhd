-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_afe_intf_regs
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.3
--*
--*     @short Slave Wishbone bridge
--*
--* Description:
--*
--*   Wishbone slave bridge from PCIe interface to ii_afe_intf
--*
--*   @generic addr_bits     : bits to decode from address in this slave
--*   @generic offset        : Slave offset address
--*   @port wb_rst_i         : input, WB synchronous active high reset
--*   @port wb_clk_i         : input, WB clock
--*   @port wb_adr_i         : input, WB address in
--*   @port wb_dat_i         : input, WB data in
--*   @port wb_we_i          : input, WB write enable
--*   @port wb_stb_i         : input, WB strobe from master
--*   @port wb_ack_o         :output, WB acknowledge out
--*   @port wb_dat_o         :output, WB data out
--*
--*   -- User registers
--*   @port ...              : input, read user register
--*   @port ...              :output, write user register
--*
--*     @author Innovative Integration Inc.
--*     @version 1.0
--*     @date Created 11/23/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_afe_intf_regs is
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
end ii_afe_intf_regs;

architecture arch of ii_afe_intf_regs is

  component ii_regs_core
    generic (
      addr_bits            : integer;
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- Wishbone slave interface
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);
      -- Core to slave register interface signals
      wr_stb               : out std_logic_vector(2**addr_bits-1 downto 0);
      rd_stb               : out std_logic_vector(2**addr_bits-1 downto 0);
      wb_reg_init_core     : in  std_logic_vector((2**addr_bits*32)-1 downto 0);
      wb_reg_i_core        : in  std_logic_vector((2**addr_bits*32)-1 downto 0);
      wb_reg_o_core        : out std_logic_vector((2**addr_bits*32)-1 downto 0)
    );
  end component;

  constant addr_range         : integer := 2**addr_bits;

  subtype wb_reg_width is std_logic_vector(31 downto 0);
  type wb_reg_t is array (addr_range-1 downto 0) of wb_reg_width;
  constant WB_REG_ZEROS       : wb_reg_width := (others => '0');

  signal wr_stb               : std_logic_vector(addr_range-1 downto 0);
  signal rd_stb               : std_logic_vector(addr_range-1 downto 0);
  signal wb_reg_init          : wb_reg_t := (others => WB_REG_ZEROS);
  signal wb_reg_i             : wb_reg_t;
  signal wb_reg_o             : wb_reg_t;
  signal wb_reg_i_slv         : std_logic_vector((addr_range*32)-1 downto 0);
  signal wb_reg_o_slv         : std_logic_vector((addr_range*32)-1 downto 0);
  signal wb_reg_init_slv      : std_logic_vector((addr_range*32)-1 downto 0);

  begin

  -- Form incoming and outgoing data array
  process (wb_reg_i, wb_reg_i_slv, wb_reg_init)
  begin
    for i in 1 to addr_range loop
      wb_reg_o_slv((i*32)-1 downto (i-1)*32) <= wb_reg_i(i-1);
      wb_reg_init_slv((i*32)-1 downto (i-1)*32) <= wb_reg_init(i-1);
      wb_reg_o(i-1) <= wb_reg_i_slv((i*32)-1 downto (i-1)*32);
    end loop;
  end process;

  inst_core: ii_regs_core
    generic map (
      addr_bits            => addr_bits,
      offset               => offset
    )
    port map(
      wb_rst_i             => wb_rst_i,
      wb_clk_i             => wb_clk_i,
      wb_adr_i             => wb_adr_i,
      wb_dat_i             => wb_dat_i,
      wb_we_i              => wb_we_i,
      wb_stb_i             => wb_stb_i,
      wb_ack_o             => wb_ack_o,
      wb_dat_o             => wb_dat_o,
      wr_stb               => wr_stb,
      rd_stb               => rd_stb,
      wb_reg_init_core     => wb_reg_init_slv,
      wb_reg_i_core        => wb_reg_o_slv,
      wb_reg_o_core        => wb_reg_i_slv
    );

  -- ************************************************************************
  -- All the assignments below this line can be modified according to the
  -- required register map.

  pll_pwr_down_n             <= wb_reg_o(0)(0);           -- PLL power down
  pll_reset_n                <= wb_reg_o(0)(1);           -- PLL reset
  wb_reg_i(0)(3 downto 0)    <= wb_reg_o(0)(3 downto 0);
  wb_reg_i(0)(4)             <= pll_lock;                 -- PLL lock
  wb_reg_i(0)(29 downto 5)   <= wb_reg_o(0)(29 downto 5);
  wb_reg_i(0)(30)            <= pll_spi_rdy;              -- PLL SPI ready
  wb_reg_i(0)(31)            <= pll_spi_rdata_valid;      -- PLL SPI data valid

  pll_spi_wr_strb            <= wr_stb(1);                -- SPI reg write strobe
  pll_spi_addr               <= wb_reg_o(1)(3 downto 0);  -- SPI address
  pll_spi_wdata              <= wb_reg_o(1)(31 downto 4); -- SPI write data
  wb_reg_i(1)(31 downto 0)   <= pll_spi_rdata;            -- SPI read data

  pll_vcxo_sdo               <= wb_reg_o(2)(0);           -- PLL VCXO I2C data out
  pll_vcxo_scl               <= wb_reg_o(2)(1);           -- PLL VCXO I2C clock
  wb_reg_i(2)(1 downto 0)    <= wb_reg_o(2)(1 downto 0);
  wb_reg_i(2)(2)             <= pll_vcxo_sdi;             -- PLL VCXO I2C data in
  wb_reg_i(2)(3)             <= wb_reg_o(2)(1);           -- PLL VCXO I2C clock (readback)
  pll_vcxo_en                <= wb_reg_o(2)(7);           -- VCXO output enable
  wb_reg_i(2)(7)             <= wb_reg_o(2)(7);

  pll_ext_clk_sel            <= wb_reg_o(3)(0);           -- PLL external clock select 0=J6,1=P16
  wb_reg_i(3)(0)             <= wb_reg_o(3)(0);

  adc_test_en                <= wb_reg_o(4)(0);           -- enable ADC test mode
  adc_test_mode              <= wb_reg_o(4)(4);           -- ADC test mode 1=paced,0=unpaced
  dac_test_en                <= wb_reg_o(4)(16);          -- enable DAC test mode
  dac_test_mode              <= wb_reg_o(4)(22 downto 20);-- DAC test mode
  wb_reg_i(4)                <= wb_reg_o(4);

  adc_run                    <= wb_reg_o(5)(0);           -- ADC run
  dac_run                    <= wb_reg_o(5)(16);          -- DAC run
  wb_reg_i(5)                <= wb_reg_o(5);

  adc_sw_trig                <= wb_reg_o(6)(0);           -- ADC sw trig
  dac_sw_trig                <= wb_reg_o(6)(16);          -- DAC sw trig
  wb_reg_i(6)                <= wb_reg_o(6);

  ext_sync_sel               <= wb_reg_o(7)(0);           -- External sync select (0=J5, 1=P16)
  wb_reg_i(7)(0)             <= wb_reg_o(7)(0);

  adc_ch_en                  <= wb_reg_o(8)(1 downto 0);  -- ADC channel enables
  adc_pdwn_n                 <= wb_reg_o(8)(17 downto 16);-- ADC power down
  wb_reg_i(8)                <= wb_reg_o(8);

  adc_window_size            <= wb_reg_o(9)(23 downto 0); -- ADC trigger window size
  adc_trigger_mode           <= wb_reg_o(9)(31 downto 29);-- ADC trigger mode
  wb_reg_i(9)                <= wb_reg_o(9);

  adc_decimation             <= wb_reg_o(10)(11 downto 0);-- ADC decimation factor
  wb_reg_i(10)(11 downto 0)  <= wb_reg_o(10)(11 downto 0);

  adc_en_pri_trig            <= wb_reg_o(11)(0);          -- enable ADC PRI trigger mode
  adc_stop_pri               <= wb_reg_o(11)(1);          -- stop ADC PRI triggering
  wb_reg_init(11)(1)         <= '1';
  wb_reg_i(11)(7 downto 0)   <= wb_reg_o(11)(7 downto 0);
  wb_reg_i(11)(8)            <= adc_pri_busy;             -- ADC PRI is running
  wb_reg_i(11)(31 downto 9)  <= wb_reg_o(11)(31 downto 9);

  adc_pri                    <= wb_reg_o(12)(31 downto 0);-- ADC PRI (pulse repetition interval)
  wb_reg_i(12)               <= wb_reg_o(12);

  adc_trig_cycle_del         <= wb_reg_o(13)(23 downto 0);-- delay between the ADC trigger and sof
  wb_reg_i(13)(23 downto 0)  <= wb_reg_o(13)(23 downto 0);

  adc_trig_fifo_wr_strb      <= wr_stb(14);               -- write to the ADC PRI trigger parameters' fifo
  adc_trig_width             <= wb_reg_o(14)(23 downto 0);-- ADC trigger width
  wb_reg_i(14)               <= wb_reg_o(14);

  adc0_spi_access_strb       <= wr_stb(16);               -- ADC0 SPI reg write strobe
  adc0_spi_wdata             <= wb_reg_o(16)(7 downto 0); -- ADC0 SPI write data
  adc0_spi_addr              <= wb_reg_o(16)(20 downto 16);-- ADC0 SPI address
  adc0_spi_rd_wrn            <= wb_reg_o(16)(28);         -- ADC0 SPI read/write enable
  wb_reg_i(16)               <= wb_reg_o(16);

  wb_reg_i(17)(7 downto 0)   <= adc0_spi_rdata;           -- ADC0 SPI read data
  wb_reg_i(17)(30)           <= adc0_spi_rdy;             -- ADC0 SPI ready
  wb_reg_i(17)(31)           <= adc0_spi_rdata_valid;     -- ADC0 SPI data valid

  adc1_spi_access_strb       <= wr_stb(18);               -- ADC1 SPI reg write strobe
  adc1_spi_wdata             <= wb_reg_o(18)(7 downto 0); -- ADC1 SPI write data
  adc1_spi_addr              <= wb_reg_o(18)(20 downto 16);-- ADC1 SPI address
  adc1_spi_rd_wrn            <= wb_reg_o(18)(28);         -- ADC1 SPI read/write enable
  wb_reg_i(18)               <= wb_reg_o(18);

  wb_reg_i(19)(7 downto 0)   <= adc1_spi_rdata;           -- ADC1 SPI read data
  wb_reg_i(19)(30)           <= adc1_spi_rdy;             -- ADC1 SPI ready
  wb_reg_i(19)(31)           <= adc1_spi_rdata_valid;     -- ADC1 SPI data valid

  adc_phy_init               <= wb_reg_o(20)(0);          -- Initialize ADC PHY
  skip_adc_phy_cal           <= wb_reg_o(20)(1);          -- Skip ADC PHY calibration
  wb_reg_i(20)(1 downto 0)   <= wb_reg_o(20)(1 downto 0);

  wb_reg_i(25)(12 downto 0)  <= adc0_eye_aligned;         -- ADC0 data eye is aligned
  wb_reg_i(25)(13)           <= adc0_prbs_locked;         -- local PRBS is locked to ADC0 bit0
  wb_reg_i(25)(14)           <= adc0_prbs_aligned;        -- ADC0 PRBS data sequence is aligned
  wb_reg_i(25)(15)           <= adc0_phy_rdy;             -- ADC0 PHY is calibrated and ready

  wb_reg_i(26)(12 downto 0)  <= adc1_eye_aligned;         -- ADC1 data eye is aligned
  wb_reg_i(26)(13)           <= adc1_prbs_locked;         -- local PRBS is locked to ADC1 bit0
  wb_reg_i(26)(14)           <= adc1_prbs_aligned;        -- ADC1 PRBS data sequence is aligned
  wb_reg_i(26)(15)           <= adc1_phy_rdy;             -- ADC1 PHY is calibrated and ready


  ts_initial                 <= wb_reg_o(32);             -- Timestamp initial
  ts_load                    <= wr_stb(32);               -- Loading strobe
  wb_reg_i(32)               <= wb_reg_o(32);

  ts_arm                     <= wb_reg_o(33)(0);          -- Timestamp Arming
  ts_pps_mode                <= wb_reg_o(33)(1);          -- PPS mode enable
  ts_tsi                     <= wb_reg_o(33)(3 downto 2); -- VITA-49 TSI
  wb_reg_init(33)(3 downto 2)<= "11";                     -- Other
  ts_tsf                     <= wb_reg_o(33)(5 downto 4); -- VITA-49 TSF
  wb_reg_init(33)(5 downto 4)<= "01";                     -- Sample count
  wb_reg_i(33)(5 downto 0)   <= wb_reg_o(33)(5 downto 0);


  adc0_frame_size            <= wb_reg_o(48)(15 downto 0);
  wb_reg_init(48)(15 downto 0) <= X"1000";
  wb_reg_i(48)(15 downto 0)  <= wb_reg_o(48)(15 downto 0);

  adc1_frame_size            <= wb_reg_o(49)(15 downto 0);
  wb_reg_init(49)(15 downto 0) <= X"1000";
  wb_reg_i(49)(15 downto 0)  <= wb_reg_o(49)(15 downto 0);


  adc0_stream_id             <= wb_reg_o(64);
  wb_reg_init(64)            <= X"00010001";
  wb_reg_i(64)               <= wb_reg_o(64);

  adc1_stream_id             <= wb_reg_o(65);
  wb_reg_init(65)            <= X"00020002";
  wb_reg_i(65)               <= wb_reg_o(65);


  adc0_gain                  <= wb_reg_o(80)(11 downto 0); -- ADC0 Gain
  wb_reg_i(80)               <= wb_reg_o(80);

  adc1_gain                  <= wb_reg_o(81)(11 downto 0); -- ADC1 Gain
  wb_reg_i(81)               <= wb_reg_o(81);


  adc0_offset                <= wb_reg_o(96)(8 downto 0);  -- ADC0 Offset
  wb_reg_init(96)            <= X"00000100";
  wb_reg_i(96)               <= wb_reg_o(96);

  adc1_offset                <= wb_reg_o(97)(8 downto 0);  -- ADC1 Offset
  wb_reg_init(97)            <= X"00000100";
  wb_reg_i(97)               <= wb_reg_o(97);


  dac_ch_en                  <= wb_reg_o(128)(3 downto 0);  -- DAC channel enables
  wb_reg_i(128)              <= wb_reg_o(128);

  dac_window_size            <= wb_reg_o(129)(23 downto 0); -- DAC trigger window size
  dac_trigger_mode           <= wb_reg_o(129)(31 downto 29);-- DAC trigger mode
  wb_reg_i(129)              <= wb_reg_o(129);


  dac_reset                  <= wb_reg_o(131)(3 downto 0);  -- DAC reset
  wb_reg_i(131)              <= wb_reg_o(131);

  phase_inc_wr               <= wr_stb(132);                -- DDS phase write strobe
  phase_inc                  <= wb_reg_o(132);              -- DDS phase increment
  wb_reg_i(132)              <= wb_reg_o(132);

  dac_en_pri_trig            <= wb_reg_o(133)(0);           -- enable DAC PRI trigger mode
  dac_stop_pri               <= wb_reg_o(133)(1);           -- stop DAC PRI triggering
  wb_reg_init(133)(1)        <= '1';
  wb_reg_i(133)(7 downto 0)  <= wb_reg_o(133)(7 downto 0);
  wb_reg_i(133)(8)           <= dac_pri_busy;               -- DAC PRI is running
  wb_reg_i(133)(31 downto 9) <= wb_reg_o(133)(31 downto 9);

  dac_pri                    <= wb_reg_o(134)(31 downto 0); -- DAC PRI (pulse repetition interval)
  wb_reg_i(134)              <= wb_reg_o(134);

  dac_trig_cycle_del         <= wb_reg_o(135)(23 downto 0); -- delay between the DAC trigger and sof
  wb_reg_i(135)(23 downto 0) <= wb_reg_o(135)(23 downto 0);

  dac_trig_fifo_wr_strb      <= wr_stb(136);                -- write to the DAC PRI trigger parameters' fifo
  dac_trig_width             <= wb_reg_o(136)(23 downto 0); -- DAC trigger width
  wb_reg_i(136)              <= wb_reg_o(136);


  dac0_spi_access_strb       <= wr_stb(144);                -- DAC0 SPI reg write strobe
  dac0_spi_wdata             <= wb_reg_o(144)(7 downto 0);  -- DAC0 SPI write data
  dac0_spi_addr              <= wb_reg_o(144)(20 downto 16);-- DAC0 SPI address
  dac0_spi_rd_wrn            <= wb_reg_o(144)(28);          -- DAC0 SPI rd/wr_n select
  wb_reg_i(144)              <= wb_reg_o(144);

  wb_reg_i(145)(7 downto 0)  <= dac0_spi_rdata;             -- DAC0 SPI read data
  wb_reg_i(145)(23 downto 8) <= wb_reg_o(145)(23 downto 8);
  wb_reg_i(145)(24)          <= dac0_spi_sdo;               -- DAC0 status
  wb_reg_i(145)(29 downto 25)<= wb_reg_o(145)(29 downto 25);
  wb_reg_i(145)(30)          <= dac0_spi_rdy;               -- DAC0 SPI ready
  wb_reg_i(145)(31)          <= dac0_spi_rdata_valid;       -- DAC0 SPI read data valid

  dac1_spi_access_strb       <= wr_stb(146);                -- DAC1 SPI reg write strobe
  dac1_spi_wdata             <= wb_reg_o(146)(7 downto 0);  -- DAC1 SPI write data
  dac1_spi_addr              <= wb_reg_o(146)(20 downto 16);-- DAC1 SPI address
  dac1_spi_rd_wrn            <= wb_reg_o(146)(28);          -- DAC1 SPI rd/wr_n select
  wb_reg_i(146)              <= wb_reg_o(146);

  wb_reg_i(147)(7 downto 0)  <= dac1_spi_rdata;             -- DAC1 SPI read data
  wb_reg_i(147)(23 downto 8) <= wb_reg_o(147)(23 downto 8);
  wb_reg_i(147)(24)          <= dac1_spi_sdo;               -- DAC1 status
  wb_reg_i(147)(29 downto 25)<= wb_reg_o(147)(29 downto 25);
  wb_reg_i(147)(30)          <= dac1_spi_rdy;               -- DAC1 SPI ready
  wb_reg_i(147)(31)          <= dac1_spi_rdata_valid;       -- DAC1 SPI read data valid


  dac_cal_en                 <= wb_reg_o(152)(0);           -- enable DAC latency calibration
  wb_reg_i(152)(3 downto 0)  <= wb_reg_o(152)(3 downto 0);
  wb_reg_i(152)(4)           <= dac0_cal0_done;             -- DAC0 calibration 0 done
  wb_reg_i(152)(5)           <= dac0_cal1_done;             -- DAC0 calibration 1 done
  wb_reg_i(152)(6)           <= dac1_cal0_done;             -- DAC1 calibration 0 done
  wb_reg_i(152)(7)           <= dac1_cal1_done;             -- DAC1 calibration 1 done
  wb_reg_i(152)(12 downto 8) <= dac0_iodly_cnt;             -- DAC0 iodelay tap count
  wb_reg_i(152)(15 downto 13)<= wb_reg_o(152)(15 downto 13);
  wb_reg_i(152)(20 downto 16)<= dac1_iodly_cnt;             -- DAC1 iodelay tap count
  wb_reg_i(152)(23 downto 21)<= wb_reg_o(152)(23 downto 21);
  wb_reg_i(152)(27 downto 24)<= dac0_shift_cnt;             -- DAC0 output shift count
  wb_reg_i(152)(31 downto 28)<= dac1_shift_cnt;             -- DAC1 output shift count


  dac0_stream_id             <= wb_reg_o(192)(15 downto 0);
  wb_reg_init(192)(15 downto 0) <= X"0001";
  wb_reg_i(192)              <= wb_reg_o(192);

  dac1_stream_id             <= wb_reg_o(193)(15 downto 0);
  wb_reg_init(193)(15 downto 0) <= X"0002";
  wb_reg_i(193)              <= wb_reg_o(193);


  dac0_a_gain                <= wb_reg_o(208)(17 downto 0); -- DAC0_A Gain
  wb_reg_init(208)           <= X"00010000";
  wb_reg_i(208)              <= wb_reg_o(208);

  dac0_b_gain                <= wb_reg_o(209)(17 downto 0); -- DAC0_B Gain
  wb_reg_init(209)           <= X"00010000";
  wb_reg_i(209)              <= wb_reg_o(209);

  dac1_a_gain                <= wb_reg_o(210)(17 downto 0); -- DAC1_A Gain
  wb_reg_init(210)           <= X"00010000";
  wb_reg_i(210)              <= wb_reg_o(210);

  dac1_b_gain                <= wb_reg_o(211)(17 downto 0); -- DAC1_B Gain
  wb_reg_init(211)           <= X"00010000";
  wb_reg_i(211)              <= wb_reg_o(211);


  dac0_a_offset              <= wb_reg_o(224)(15 downto 0); -- DAC0_A Offset
  wb_reg_i(224)              <= wb_reg_o(224);

  dac0_b_offset              <= wb_reg_o(225)(15 downto 0); -- DAC0_B Offset
  wb_reg_i(225)              <= wb_reg_o(225);

  dac1_a_offset              <= wb_reg_o(226)(15 downto 0); -- DAC1_A Offset
  wb_reg_i(226)              <= wb_reg_o(226);

  dac1_b_offset              <= wb_reg_o(227)(15 downto 0); -- DAC1_B Offset
  wb_reg_i(227)              <= wb_reg_o(227);

end arch;

