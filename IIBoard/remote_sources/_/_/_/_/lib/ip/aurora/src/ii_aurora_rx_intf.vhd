-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_aurora_rx_intf
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.1
--*
--*     @short Aurora RX FIFO Interface
--*
--* Description:
--*
--*   This component drains the Aurora core RX FIFO into a data destination FIFO
--*   and also compares the incoming data with a locally generated test pattern
--*   to detect errors when the test checker is enabled.
--*
--*   @port srst              : input, synchronous active high reset
--*   @port clk               : input, system clock
--*   @port channel_en        : input, channel enable
--*   @port test_chk_en       : input, Test checker enable
--*   @port test_errors       :output, Test checker error count
--*   @port src_empty         : input, Source RX FIFO empty flag
--*   @port src_aempty        : input, Source RX FIFO almost empty flag
--*   @port src_rden          :output, Source RX FIFO read enable
--*   @port src_din           : input, Source RX FIFO data output bus
--*   @port src_valid         : input, Source RX FIFO data output valid
--*   @port dest_dout         :output, Destination FIFO data input
--*   @port dest_valid        :output, Destination FIFO data input valid
--*   @port dest_rdy          : input, Destination FIFO room available
--*
--*     @author Innovative Integration Inc.
--*     @version 1.0
--*     @date Created 06/09/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_aurora_rx_intf is
  generic (
    WIDTH                : integer := 128
  );
  port (
    srst                 : in  std_logic;
    clk                  : in  std_logic;

    channel_en           : in  std_logic;
    test_chk_en          : in  std_logic;
    test_errors          : out std_logic_vector(15 downto 0);

    src_empty            : in  std_logic;
    src_aempty           : in  std_logic;
    src_rden             : out std_logic;
    src_din              : in  std_logic_vector(WIDTH-1 downto 0);
    src_valid            : in  std_logic;

    dest_dout            : out std_logic_vector(WIDTH-1 downto 0);
    dest_valid           : out std_logic;
    dest_rdy             : in  std_logic
  );
end ii_aurora_rx_intf;


architecture arch of ii_aurora_rx_intf is

  component ii_fifo_drainer
    port (
      srst            : in  std_logic;
      clk             : in  std_logic;
      ce              : in  std_logic;

      src_empty       : in  std_logic;
      src_aempty      : in  std_logic;
      dest_rdy        : in  std_logic;

      src_rden        : out std_logic
    );
  end component;

  signal gen_data          : std_logic_vector(WIDTH-1 downto 0);
  signal gen_errors        : unsigned(15 downto 0);
  signal gen_err_top       : std_logic;
  signal src_din_d         : std_logic_vector(WIDTH-1 downto 0);
  signal src_valid_d       : std_logic;

  ------------------------------------------------------------------------------
  begin

  -- Register input datapath to ease timing
  process (clk)
  begin
    if rising_edge(clk) then
      src_din_d   <= src_din;
      src_valid_d <= src_valid;
    end if;
  end process;

  dest_dout  <= src_din_d;
  dest_valid <= src_valid_d;

  -- Bleed enabled source FIFO channel
  inst_drainer : ii_fifo_drainer
    port map (
      srst             => srst,
      clk              => clk,
      ce               => channel_en,
      src_empty        => src_empty,
      src_aempty       => src_aempty,
      dest_rdy         => dest_rdy,
      src_rden         => src_rden
    );

------------------------------------------------------------------------------
-- Pattern checker
------------------------------------------------------------------------------
  -- Pattern generator to compare against
  -- Walking-one test pattern generator
  -- 0x00000001,
  -- 0x00000002,
  -- 0x00000004,
  -- 0x00000008,
  --              etc.
  process (clk)
  begin
    if rising_edge(clk) then
      if (srst = '1') then
        gen_data(0)                <= '1';
        gen_data(WIDTH-1 downto 1) <= (others => '0');
        gen_errors <= (others => '0');
      elsif (src_valid_d = '1' and test_chk_en = '1') then
        gen_data <= gen_data(WIDTH-2 downto 0) & gen_data(WIDTH-1);
        if (gen_err_top = '0' and src_din_d /= gen_data) then
          gen_errors <= gen_errors + 1;
        end if;
      end if;
    end if;
  end process;

  test_errors <= std_logic_vector(gen_errors);

  -- Stop counting when error counter is maxed
  process (clk)
  begin
    if rising_edge(clk) then
      if (srst = '1') then
        gen_err_top <= '0';
      elsif (gen_errors = X"FFFE") then
        gen_err_top <= '1';
      end if;
    end if;
  end process;

end arch;
