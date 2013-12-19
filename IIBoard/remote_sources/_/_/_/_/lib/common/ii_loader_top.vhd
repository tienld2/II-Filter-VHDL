-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_loader_top
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short Top module for ii_loader with ii_loader_regs
--*
--* Description:
--*
--*   This component is the top level of the loader.
--*
--*   @generic addr_bits       : bits to decode from address in this slave
--*   @generic offset          : Slave offset address
--*   @port wb_rst_i           : input, WB synchronous active high reset
--*   @port wb_clk_i           : input, WB clock
--*   @port wb_adr_i           : input, WB address in
--*   @port wb_dat_i           : input, WB data in
--*   @port wb_we_i            : input, WB write enable
--*   @port wb_stb_i           : input, WB strobe from master
--*   @port wb_ack_o           :output, WB acknowledge out
--*   @port wb_dat_o           :output, WB data out
--*   @port srst               : input, synchronous active high reset
--*   @port sys_clk            : input, system clock
--*   @port loader_clk         :output, serial clock
--*   @port loader_cs          :output, chip select
--*   @port loader_dio         :output, serial data output
--*   @port loader_bus         : inout, parallel data in/out
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 05/18/2010
--*
--************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_loader_top is
  generic (
    addr_bits            : integer := 2;
    offset               : std_logic_vector(15 downto 0) := x"0100"
  );
  port (
    -- Wishbone interface signals
    wb_rst_i              : in    std_logic;
    wb_clk_i              : in    std_logic;
    wb_adr_i              : in    std_logic_vector(15 downto 0);
    wb_dat_i              : in    std_logic_vector(31 downto 0);
    wb_we_i               : in    std_logic;
    wb_stb_i              : in    std_logic;
    wb_ack_o              : out   std_logic;
    wb_dat_o              : out   std_logic_vector(31 downto 0);

    -- Reset and clock
    srst                  : in    std_logic;
    sys_clk               : in    std_logic;

    -- FPA interface pins (Flash Programming & Authentication)
    loader_clk            : out   std_logic;
    loader_cs             : out   std_logic;
    loader_dio            : out   std_logic;
    loader_bus            : inout std_logic_vector(15 downto 0)
  );
end ii_loader_top;

architecture arch of ii_loader_top is

  component ii_loader
    port (
      srst                 : in    std_logic;
      sys_clk              : in    std_logic;
      loader_clk           : out   std_logic;
      loader_cs            : out   std_logic;
      loader_dio           : out   std_logic;
      loader_bus           : inout std_logic_vector(15 downto 0);
      addr                 : in    std_logic_vector(26 downto 0);
      addr_wr              : in    std_logic;
      data_o               : in    std_logic_vector(31 downto 0);
      data_i               : out   std_logic_vector(31 downto 0);
      data_wr              : in    std_logic;
      cmd                  : in    std_logic_vector(6 downto 0);
      cmd_wr               : in    std_logic;
      status               : out   std_logic_vector(15 downto 0)
    );
  end component;

  component ii_loader_regs
    generic (
      addr_bits            : integer := 2;
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- wishbone interface signals
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);

      -- User registers
      addr                 : out std_logic_vector(26 downto 0);
      addr_wr              : out std_logic;
      data_i               : in  std_logic_vector(31 downto 0);
      data_o               : out std_logic_vector(31 downto 0);
      data_wr              : out std_logic;
      cmd                  : out std_logic_vector(6 downto 0);
      cmd_wr               : out std_logic;
      status               : in  std_logic_vector(15 downto 0)
    );
  end component;

  signal addr                 : std_logic_vector(26 downto 0);
  signal addr_wr              : std_logic;
  signal data_i               : std_logic_vector(31 downto 0);
  signal data_o               : std_logic_vector(31 downto 0);
  signal data_wr              : std_logic;
  signal data_rd              : std_logic;
  signal cmd                  : std_logic_vector(6 downto 0);
  signal cmd_wr               : std_logic;
  signal status               : std_logic_vector(15 downto 0);

begin

  inst_loader : ii_loader
  port map (
    srst                 => srst,
    sys_clk              => sys_clk,
    loader_clk           => loader_clk,
    loader_cs            => loader_cs,
    loader_dio           => loader_dio,
    loader_bus           => loader_bus,
    addr                 => addr,
    addr_wr              => addr_wr,
    data_i               => data_i,    -- take host POV
    data_o               => data_o,
    data_wr              => data_wr,
    cmd                  => cmd,
    cmd_wr               => cmd_wr,
    status               => status
  );

  inst_loader_regs : ii_loader_regs
  generic map(
    addr_bits            => addr_bits,
    offset               => offset
  )
  port map (
    -- wishbone interface signals
    wb_rst_i             => wb_rst_i,
    wb_clk_i             => wb_clk_i,
    wb_adr_i             => wb_adr_i,
    wb_dat_i             => wb_dat_i,
    wb_we_i              => wb_we_i,
    wb_stb_i             => wb_stb_i,
    wb_ack_o             => wb_ack_o,
    wb_dat_o             => wb_dat_o,

    -- User registers
    addr                 => addr,
    addr_wr              => addr_wr,
    data_i               => data_i,
    data_o               => data_o,
    data_wr              => data_wr,
    cmd                  => cmd,
    cmd_wr               => cmd_wr,
    status               => status
  );

end arch;
