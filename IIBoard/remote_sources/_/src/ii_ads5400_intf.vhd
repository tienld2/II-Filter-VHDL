-- Copyright 2011 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_ads5400_intf
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 13.1
--*
--*     @short A/D interface for TI ADS5400
--*
--* Description:
--*
--*   This file is the interface to ADS5400. It wraps the ADC interface physical
--*   layer module, aligns the PHY data with the external sync, generates test
--*   data when in test mode, generates overflow and over range indicators, and
--*   outputs either the test data or adc data based on test_en setting.
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

entity ii_ads5400_intf is
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
end ii_ads5400_intf;

architecture arch of ii_ads5400_intf is

  component ii_ads5400_phy_top
    port (
      -- Reset and clocks
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;
      ref_clk200           : in  std_logic;

      -- Controls
      idelayctrl_rst       : in  std_logic;
      phy_init_strb        : in  std_logic;
      skip_adc_phy_cal     : in  std_logic;
      ch_en                : in  std_logic;
      gain                 : in  std_logic_vector(11 downto 0);
      offset               : in  std_logic_vector(8 downto 0);

      -- Status
      adc_eye_aligned      : out std_logic_vector(12 downto 0);
      adc_prbs_locked      : out std_logic;
      adc_prbs_aligned     : out std_logic;
      adc_phy_rdy          : out std_logic;
      adc_sync_phase       : out std_logic;

      -- ADC SPI user interface
      usr_spi_access_strb  : in  std_logic;
      usr_spi_wdata        : in  std_logic_vector(7 downto 0);
      usr_spi_addr         : in  std_logic_vector(4 downto 0);
      usr_spi_rd_wrn       : in  std_logic;
      usr_spi_rdy          : out std_logic;
      usr_spi_rdata_valid  : out std_logic;
      usr_spi_rdata        : out std_logic_vector(7 downto 0);

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

      -- PHY clock and data output
      adc_dclk             : out std_logic;
      adc_dclk_180         : out std_logic;
      adc_dclk_div2        : out std_logic;
      adc_dout             : out std_logic_vector(47 downto 0);
      adc_ovr_out          : out std_logic_vector(3 downto 0)
    );
  end component;

  component ii_sample_sort
    port (
      -- Clock
      clk                  : in  std_logic;

      -- Controls
      adc_sync_phase       : in  std_logic;
      ext_sync_phase       : in  std_logic_vector(1 downto 0);

      -- Data in and out
      din                  : in  std_logic_vector(47 downto 0);
      dout                 : out std_logic_vector(47 downto 0)
    );
  end component;

  -- Set the pipeline delay on the trigger to align the first captured
  -- sample with the external sync
  constant pipe_depth         : integer := 1;

  signal pipe_rst             : std_logic;
  signal adc_phy_init_d       : std_logic;
  signal adc_phy_init_re      : std_logic;
  signal trig_frame_sreg      : std_logic_vector(pipe_depth-1 downto 0);
  signal trig_sreg            : std_logic_vector(pipe_depth-1 downto 0);
  signal adc_trig_frame       : std_logic;
  signal adc_trig             : std_logic;
  signal adc_phy_rdy_l        : std_logic;
  signal adc_sync_phase       : std_logic;
  signal dclk_div2            : std_logic;
  signal adc_dout             : std_logic_vector(47 downto 0);
  signal adc_ovr_out          : std_logic_vector(3 downto 0);
  signal sorted_data          : std_logic_vector(47 downto 0);
  signal din_vld              : std_logic;
  signal adc_trig_d           : std_logic;
  signal adc_trig_re          : std_logic;
  signal test_gen_en          : std_logic;
  signal ramp                 : unsigned(9 downto 0);
  signal ramp_up              : std_logic;
  signal test_data            : std_logic_vector(47 downto 0);
  signal adc_trig_frame_d     : std_logic;
  signal din_vld_d            : std_logic;

begin

-----------------------------------------------------------------------------
-- Misc.
-----------------------------------------------------------------------------
  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      pipe_rst <= srst or not ch_en or not run;
    end if;
  end process;

  -- Strobe the PHY to start its initialization procedure and
  -- calibration on rising edge of adc_phy_init
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      adc_phy_init_d  <= adc_phy_init;
      adc_phy_init_re <= adc_phy_init and not adc_phy_init_d;
    end if;
  end process;

  -- Pipeline to align the first captured sample with the external trigger
  process (dclk_div2)
  begin
    if (rising_edge(dclk_div2)) then
      trig_frame_sreg <= trig_frame_sreg(trig_frame_sreg'high-1 downto 0) &
                         trigger_frame;
      trig_sreg       <= trig_sreg(trig_sreg'high-1 downto 0) & trigger;
    end if;
  end process;

  adc_trig_frame <= trig_frame_sreg(trig_frame_sreg'high);
  adc_trig       <= trig_sreg(trig_sreg'high);

-----------------------------------------------------------------------------
-- Instantiate ADC PHY TOP interface
-----------------------------------------------------------------------------
  inst_adc_phy_top : ii_ads5400_phy_top
  port map (
    -- Reset and clocks
    srst                 => srst,
    sys_clk              => sys_clk,
    ref_clk200           => ref_clk200,

    -- Controls
    idelayctrl_rst       => idelayctrl_rst,
    phy_init_strb        => adc_phy_init_re,
    skip_adc_phy_cal     => skip_adc_phy_cal,
    ch_en                => ch_en,
    gain                 => gain,
    offset               => offset,

    -- Status
    adc_eye_aligned      => adc_eye_aligned,
    adc_prbs_locked      => adc_prbs_locked,
    adc_prbs_aligned     => adc_prbs_aligned,
    adc_phy_rdy          => adc_phy_rdy_l,
    adc_sync_phase       => adc_sync_phase,

    -- ADC SPI user interface
    usr_spi_access_strb  => spi_access_strb,
    usr_spi_wdata        => spi_wdata,
    usr_spi_addr         => spi_addr,
    usr_spi_rd_wrn       => spi_rd_wrn,
    usr_spi_rdy          => spi_rdy,
    usr_spi_rdata_valid  => spi_rdata_valid,
    usr_spi_rdata        => spi_rdata,

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

    -- PHY clock and data output
    adc_dclk             => adc_dclk,
    adc_dclk_180         => adc_dclk_180,
    adc_dclk_div2        => dclk_div2,
    adc_dout             => adc_dout,
    adc_ovr_out          => adc_ovr_out
  );

  adc_dclk_div2 <= dclk_div2;

  -- If test mode enabled, assert adc_phy_rdy
  process (sys_clk)
  begin
    if rising_edge(sys_clk) then
      adc_phy_rdy <= not srst and (adc_phy_rdy_l or (test_en and ch_en));
    end if;
  end process;

-----------------------------------------------------------------------------
-- Data pipe
-----------------------------------------------------------------------------
  inst_sort : ii_sample_sort
  port map (
    -- Clock
    clk                  => dclk_div2,

    -- Controls
    adc_sync_phase       => adc_sync_phase,
    ext_sync_phase       => ext_sync_phase,

    -- Data in and out
    din                  => adc_dout,
    dout                 => sorted_data
  );

-----------------------------------------------------------------------------
-- Generate test data
-----------------------------------------------------------------------------

  -- Drop the input if its going to cause an overflow
  din_vld <= adc_trig and not data_fifo_afull;

  -- Detect the first rising edge on adc_trig and use it
  -- to enable generating test ramp
  process (dclk_div2)
  begin
    if (rising_edge(dclk_div2)) then
      if (pipe_rst = '1') then
        adc_trig_d  <= '0';
        test_gen_en <= '0';
      else
        adc_trig_d <= adc_trig;
        if (test_en = '1' and test_mode = '0') then
          if (adc_trig_re = '1') then
            test_gen_en <= '1';      -- continuous output (unpaced)
          end if;
        elsif (test_en = '1' and test_mode = '1') then
          test_gen_en <= din_vld;    -- paced output
        else
          test_gen_en <= '0';
        end if;
      end if;
    end if;
  end process;

  adc_trig_re <= not adc_trig_d and adc_trig;

  -- Sawtooth generator
  process (dclk_div2)
  begin
    if (rising_edge(dclk_div2)) then
      if (pipe_rst = '1') then
        ramp    <= (others => '0');
        ramp_up <= '1';
      elsif (test_gen_en = '1') then
        if (ramp_up = '1') then
          if (ramp = "01" & X"FF") then
            ramp_up <= '0';       -- change direction but keep ramp value
          else
            ramp    <= ramp + 1;
          end if;
        else
          if (ramp = "10" & X"00") then
            ramp_up <= '1';       -- change direction but keep ramp value
          else
            ramp    <= ramp - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  test_data <= std_logic_vector(ramp &     ramp_up &     ramp_up &
                                ramp &     ramp_up & not ramp_up &
                                ramp & not ramp_up &     ramp_up &
                                ramp & not ramp_up & not ramp_up);

-----------------------------------------------------------------------------
-- Mux between ADC data and test generator data
-----------------------------------------------------------------------------
  -- Mux between ADC data and test generator data
  process (dclk_div2)
  begin
    if (rising_edge(dclk_div2)) then
      if (test_en = '1') then
        adc_data <= test_data;
      else
        adc_data <= sorted_data;
      end if;
    end if;
  end process;

  -- Regenerate the data frame output and valid output
  process (dclk_div2)
  begin
    if (rising_edge(dclk_div2)) then
      if (pipe_rst = '1') then
        adc_trig_frame_d <= '0';
        adc_data_frame   <= '0';
        din_vld_d        <= '0';
        adc_data_vld     <= '0';
      else
        adc_trig_frame_d <= adc_trig_frame;
        adc_data_frame   <= adc_trig_frame_d;
        din_vld_d        <= din_vld;
        adc_data_vld     <= din_vld_d;
      end if;
    end if;
  end process;

  -- Detect overrange occurrence (only with ADC data)
  process (dclk_div2)
  begin
    if (rising_edge(dclk_div2)) then
      if (adc_ovr_out /= "0000" and trigger = '1' and test_en = '0') then
        adc_ovr <= '1';
      else
        adc_ovr <= '0';
      end if;
      adc_ovf <= adc_trig and data_fifo_afull;
    end if;
  end process;

end arch;
