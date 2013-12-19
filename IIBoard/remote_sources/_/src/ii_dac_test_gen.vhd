-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_dac_test_gen
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.3
--*
--*     @short Test Generator for DACs
--*
--* Description:
--*
--*   This component generates 4 sequential samples 16-bit each either
--*   sinewave from a DDS, ramp, or an alternating DAC test pattern of
--*   5555AAAA5555AAAA and AAAA5555AAAA5555 output.
--*   The sine generator uses a DDS, and the output frequency is controlled
--*   by the phase increment.
--*
--*   phase increment = Fout * 2^(accumulator width) / Fclk,
--*   where accumulator width = 32, Fclk = sys_clk frequency = 250e6 Hz.
--*
--*
--*   @port srst            : input, synchronous active high reset
--*   @port sys_clk         : input, system clock
--*   @port test_en         : input, test enable
--*   @port test_mode       : input, test mode select (slow square wave = 7,
--*                                  fast square wave = 6, max neg = 5,
--*                                  max pos = 4, zeros = 3, dac test
--*                                  pattern = 2, sine = 1, ramp = 0)
--*   @port phase_inc_wr    : input, phase increment write strobe
--*   @port phase_inc       : input, phase increment
--*   @port test_data_req   : input, test data request
--*   @port dout            :output, output data (64 bits)
--*   @port valid           :output, output data valid
--*   @port pattern_test    :output, pattern test mode is selected
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 11/23/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ii_dac_test_gen is
  port (
    -- Reset and clock
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;

    -- Control
    test_en              : in  std_logic;
    test_mode            : in  std_logic_vector(2 downto 0);
    phase_inc_wr         : in  std_logic;
    phase_inc            : in  std_logic_vector(31 downto 0);

    -- Data
    test_data_req        : in  std_logic;
    dout                 : out std_logic_vector(63 downto 0);
    valid                : out std_logic;
    pattern_test         : out std_logic
  );
end ii_dac_test_gen;

architecture arch of ii_dac_test_gen is

  component dds_16b
    port (
      clk                  : in  std_logic;
      sclr                 : in  std_logic;
      ce                   : in  std_logic;
      we                   : in  std_logic;
      reg_select           : in  std_logic;
      data                 : in  std_logic_vector(31 downto 0);
      rdy                  : out std_logic;
      sine                 : out std_logic_vector(15 downto 0)
    );
  end component;

  signal ramp_vld             : std_logic;
  signal ramp                 : std_logic_vector(13 downto 0);
  signal sine_gen_en          : std_logic;
  signal sine_gen_en_d        : std_logic;
  signal phase_inc_int        : std_logic_vector(31 downto 0);
  signal phase_offset_0       : std_logic_vector(31 downto 0);
  signal phase_offset_1       : std_logic_vector(31 downto 0);
  signal phase_offset_2       : std_logic_vector(31 downto 0);
  signal phase_offset_3       : std_logic_vector(31 downto 0);
  signal phase_inc_wr_d       : std_logic;
  signal dds_we               : std_logic;
  signal dds_reg_select       : std_logic;
  signal dds0_data            : std_logic_vector(31 downto 0);
  signal dds1_data            : std_logic_vector(31 downto 0);
  signal dds2_data            : std_logic_vector(31 downto 0);
  signal dds3_data            : std_logic_vector(31 downto 0);
  signal sine0                : std_logic_vector(15 downto 0);
  signal sine1                : std_logic_vector(15 downto 0);
  signal sine2                : std_logic_vector(15 downto 0);
  signal sine3                : std_logic_vector(15 downto 0);
  signal sine_valid           : std_logic;
  signal dac_pattern_valid    : std_logic;
  signal dac_pattern          : std_logic_vector(31 downto 0);

begin

  -- ramp generator
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        ramp_vld <= '0';
        ramp     <= ("11" & x"fff");
      elsif (test_en = '1' and test_mode = "000" and test_data_req = '1') then
        ramp_vld <= '1';
        ramp     <= ramp + 1;
      else
        ramp_vld <= '0';
      end if;
    end if;
  end process;

  -- enable the sine wave generator
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        sine_gen_en <= '0';
      elsif (test_en = '1' and test_mode = "001" and test_data_req = '1') then
        sine_gen_en <= '1';
      else
        sine_gen_en <= '0';
      end if;
      sine_gen_en_d <= sine_gen_en;
    end if;
  end process;

  -- Modify the phase increment and generate phase offset
  -- values from phase_inc input to connect to 4 instances
  -- of dds_16b to get 4 consecutive sine wave samples in every clock
  phase_inc_int  <= (phase_inc(29 downto 0) & "00");            -- x4
  phase_offset_0 <= (others => '0');                            -- x0
  phase_offset_1 <= phase_inc;                                  -- x1
  phase_offset_2 <= (phase_inc(30 downto 0) & '0');             -- x2

  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      phase_offset_3 <= (phase_inc(30 downto 0) & '0') + phase_inc; -- x3
    end if;
  end process;

  -- Generate pinc & poff writing signals
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      phase_inc_wr_d <= phase_inc_wr;
      dds_we         <= phase_inc_wr or phase_inc_wr_d;
      if (phase_inc_wr_d = '1') then
        dds_reg_select <= '1';
      else
        dds_reg_select <= '0';
      end if;
    end if;
  end process;

  dds0_data <= phase_inc_int when (dds_reg_select = '0') else phase_offset_0;
  dds1_data <= phase_inc_int when (dds_reg_select = '0') else phase_offset_1;
  dds2_data <= phase_inc_int when (dds_reg_select = '0') else phase_offset_2;
  dds3_data <= phase_inc_int when (dds_reg_select = '0') else phase_offset_3;

  -- Instantiate the sine wave generators
  inst_dds0 : dds_16b
    port map (
      clk                  => sys_clk,
      sclr                 => srst,
      ce                   => sine_gen_en,
      we                   => dds_we,
      reg_select           => dds_reg_select,
      data                 => dds0_data,
      rdy                  => sine_valid,
      sine                 => sine0
    );

  inst_dds1 : dds_16b
    port map (
      clk                  => sys_clk,
      sclr                 => srst,
      ce                   => sine_gen_en,
      we                   => dds_we,
      reg_select           => dds_reg_select,
      data                 => dds1_data,
      rdy                  => open,
      sine                 => sine1
    );

  inst_dds2 : dds_16b
    port map (
      clk                  => sys_clk,
      sclr                 => srst,
      ce                   => sine_gen_en,
      we                   => dds_we,
      reg_select           => dds_reg_select,
      data                 => dds2_data,
      rdy                  => open,
      sine                 => sine2
    );

  inst_dds3 : dds_16b
    port map (
      clk                  => sys_clk,
      sclr                 => srst,
      ce                   => sine_gen_en,
      we                   => dds_we,
      reg_select           => dds_reg_select,
      data                 => dds3_data,
      rdy                  => open,
      sine                 => sine3
    );

  -- DAC pattern generator
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        dac_pattern_valid <= '0';
        dac_pattern       <= x"AAAA5555";
      elsif (test_en = '1' and test_mode = "010" and test_data_req = '1') then
        dac_pattern_valid <= '1';
        dac_pattern       <= not dac_pattern;
      else
        dac_pattern_valid <= '0';
      end if;
    end if;
  end process;

  -- select the test data to use
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or test_en = '0') then
        valid        <= '0';
        dout         <= (others => '0');
        pattern_test <= '0';
      else
        pattern_test <= '0';
        case test_mode is
          when "000" =>
            valid <= ramp_vld;
            dout  <= (ramp & "11" & ramp & "10" & ramp & "01" & ramp & "00");
          when "001" =>
            valid <= sine_valid and sine_gen_en_d;
            dout  <= (sine3 & sine2 & sine1 & sine0);
          when "010" =>
            valid        <= dac_pattern_valid;
            dout         <= (dac_pattern & dac_pattern);
            pattern_test <= '1';
          when "011" =>
            valid <= test_data_req;
            dout  <= (others => '0');      -- all zero
          when "100" =>
            valid <= test_data_req;
            dout  <= x"7fff7fff7fff7fff";  -- max positive
          when "101" =>
            valid <= test_data_req;
            dout  <= x"8000800080008000";  -- max negative
          when "110" =>
            valid <= test_data_req;
            dout  <= x"80007fff80007fff";  -- fast square wave
          when "111" =>
            valid <= test_data_req;
            dout  <= x"800080007fff7fff";  -- slow square wave
          when others =>
            valid <= test_data_req;
            dout  <= (others => '0');
        end case;
      end if;
    end if;
  end process;

end arch;
