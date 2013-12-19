-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_aurora_tx_intf
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.1
--*
--*     @short Aurora TX FIFO Interface
--*
--* Description:
--*
--*   This component drains a data source FIFO into the Aurora core TX FIFO or
--*   injects test pattern data into this FIFO when the test generator is
--*   enabled.
--*
--*   @port srst              : input, synchronous active high reset
--*   @port clk               : input, system clock
--*   @port channel_en        : input, channel enable
--*   @port test_gen_en       : input, Test generator enable
--*   @port src_rdy           :output, Source is ready for data
--*   @port src_valid         : input, Source data valid
--*   @port src_din           : input, Source data input (little endian)
--*   @port dest_rdy          : input, Destination TX FIFO room available
--*   @port dest_valid        :output, Destination TX FIFO data input valid
--*   @port dest_dout         :output, Destination TX FIFO data input
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

entity ii_aurora_tx_intf is
  generic (
    WIDTH                : integer := 128
  );
  port (
    srst                 : in  std_logic;
    clk                  : in  std_logic;

    channel_en           : in  std_logic;
    test_gen_en          : in  std_logic;

    src_rdy              : out std_logic;
    src_valid            : in  std_logic;
    src_din              : in  std_logic_vector(WIDTH-1 downto 0);

    dest_rdy             : in  std_logic;
    dest_valid           : out std_logic;
    dest_dout            : out std_logic_vector(WIDTH-1 downto 0)
  );
end ii_aurora_tx_intf;


architecture arch of ii_aurora_tx_intf is

  signal src_din_d         : std_logic_vector(WIDTH-1 downto 0);
  signal src_valid_d       : std_logic;
  signal gen_data          : std_logic_vector(WIDTH-1 downto 0);
  signal gen_valid         : std_logic;

  ------------------------------------------------------------------------------
  begin

  -- Register inputs from source to ease timing (long paths)
  process (clk)
  begin
    if rising_edge(clk) then
      src_din_d   <= src_din;
      src_valid_d <= src_valid;
    end if;
  end process;

  -- Set src_rdy when destination is ready, channel is enabled, and
  -- not in test mode
  process (clk)
  begin
    if rising_edge(clk) then
      if (srst = '1' or test_gen_en = '1') then
        src_rdy <= '0';
      else
        src_rdy <= dest_rdy and channel_en;
      end if;
    end if;
  end process;

------------------------------------------------------------------------------
-- Pattern generator
------------------------------------------------------------------------------
  -- Walking-one test pattern generator
  -- Will put out {0x00000008,0x00000004,0x00000002,0x00000001},
  --              {0x00000080,0x00000040,0x00000020,0x00000010},
  --              {0x00000800,0x00000400,0x00000200,0x00000100},
  --              etc.
  process (clk)
  begin
    if rising_edge(clk) then
      if (srst = '1' or test_gen_en = '0') then
        gen_data(WIDTH-1)          <= '1';
        gen_data(WIDTH-2 downto 0) <= (others => '0');
        gen_valid                  <= '0';
      elsif (dest_rdy = '1' and channel_en = '1') then
        gen_data  <= gen_data(WIDTH-2 downto 0) & gen_data(WIDTH-1);
        gen_valid <= '1';
      else
        gen_valid <= '0';
      end if;
    end if;
  end process;

------------------------------------------------------------------------------
-- Data output: Mux selection of dest_dout and dest_valid
------------------------------------------------------------------------------
  dest_dout  <= gen_data when (test_gen_en = '1') else src_din_d;
  dest_valid <= gen_valid when (test_gen_en = '1') else src_valid_d;

end arch;
