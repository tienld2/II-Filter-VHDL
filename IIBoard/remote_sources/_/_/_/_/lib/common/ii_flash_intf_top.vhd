-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--
--************************************************************************
--* Design name: ii_flash_intf_top
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short Top level module for flash along with ii_flash_regs
--*
--* Description:
--*
--*   This component is the top level module for the flash interface
--*   and logic for wishbone registers.
--*
--*   @generic offset          : Slave offset address
--*   @port srst               : input, synchronous active high reset
--*   @port sys_clk            : input, system clock
--*   @port wb_rst_i           : input, WB synchronous active high reset
--*   @port wb_clk_i           : input, WB clock
--*   @port wb_adr_i           : input, WB address in
--*   @port wb_dat_i           : input, WB data in
--*   @port wb_we_i            : input, WB write enable
--*   @port wb_stb_i           : input, WB strobe from master
--*   @port wb_ack_o           :output, WB acknowledge out
--*   @port wb_dat_o           :output, WB data out
--*   @port rom_sck            :output, serial clock to flash
--*   @port rom_cs_n           :output, chip select to flash
--*   @port rom_sdi            :output, serial data in to flash
--*   @port rom_sdo            : input, serial data out from flash
--*   @port rom_hold_n         :output, hold flash interface
--*   @port rom_wp_n           :output, flash write protect
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date created 07/14/2010
--*
--************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_flash_intf_top is
  generic (
    addr_bits           : integer := 2;
    offset              : std_logic_vector(15 downto 0)
  );
  port (
    srst                : in    std_logic;
    sys_clk             : in    std_logic;

    -- Slave Wishbone interface
    wb_rst_i            : in    std_logic;
    wb_clk_i            : in    std_logic;
    wb_adr_i            : in    std_logic_vector(15 downto 0);
    wb_dat_i            : in    std_logic_vector(31 downto 0);
    wb_we_i             : in    std_logic;
    wb_stb_i            : in    std_logic;
    wb_ack_o            : out   std_logic;
    wb_dat_o            : out   std_logic_vector(31 downto 0);

    -- Flash spi interface
    rom_sck             : out   std_logic;
    rom_cs_n            : out   std_logic;
    rom_sdi             : out   std_logic;
    rom_sdo             : in    std_logic;
    rom_hold_n          : out   std_logic;
    rom_wp_n            : out   std_logic
  );

end ii_flash_intf_top;

architecture arch of ii_flash_intf_top is

  component ii_flash_regs
    generic (
      addr_bits         : integer;
      offset            : std_logic_vector(15 downto 0)
      );
      port (
      -- Wishbone interface signals
      wb_rst_i          : in  std_logic;
      wb_clk_i          : in  std_logic;
      wb_adr_i          : in  std_logic_vector(15 downto 0);
      wb_dat_i          : in  std_logic_vector(31 downto 0);
      wb_we_i           : in  std_logic;
      wb_stb_i          : in  std_logic;
      wb_ack_o          : out std_logic;
      wb_dat_o          : out std_logic_vector(31 downto 0);
      -- User registers
      spi_access_strb   : out std_logic;
      spi_wdata         : out std_logic_vector(31 downto 0);
      spi_addr          : out std_logic_vector(23 downto 0);
      spi_opcode        : out std_logic_vector(7 downto 0);
      fl_hold           : out std_logic;
      fl_wp             : out std_logic;
      spi_rdy           : in  std_logic;
      spi_rdata_valid   : in  std_logic;
      spi_rdata         : in  std_logic_vector(31 downto 0);
      spi_so            : in  std_logic
    );
  end component;

  component ii_flash_spi
    port(
      srst              : in  std_logic;
      sys_clk           : in  std_logic;
      -- User interface
      spi_access_strb   : in  std_logic;
      spi_wdata         : in  std_logic_vector(31 downto 0);
      spi_addr          : in  std_logic_vector(23 downto 0);
      spi_opcode        : in  std_logic_vector(7 downto 0);
      spi_rdy           : out std_logic;
      spi_rdata_valid   : out std_logic;
      spi_rdata         : out std_logic_vector(31 downto 0);
      spi_so            : out std_logic;
      -- Flash spi interface
      fl_spi_sclk       : out std_logic;
      fl_spi_csb        : out std_logic;
      fl_spi_si         : out std_logic;
      fl_spi_so         : in  std_logic
  );
  end component;

  signal spi_access_strb : std_logic;
  signal spi_wdata       : std_logic_vector(31 downto 0);
  signal spi_addr        : std_logic_vector(23 downto 0);
  signal spi_opcode      : std_logic_vector(7 downto 0);
  signal fl_hold         : std_logic;
  signal fl_wp           : std_logic;
  signal spi_rdy         : std_logic;
  signal spi_rdata_valid : std_logic;
  signal spi_rdata       : std_logic_vector(31 downto 0);
  signal spi_so          : std_logic;

begin

  -- Change flash hold# polarity (part is active low)
  rom_hold_n <= not fl_hold;

  -- Write protect (active low)
  rom_wp_n   <= not fl_wp;

  inst_flash_regs : ii_flash_regs
  generic map (
    addr_bits      => addr_bits,
    offset         => offset
    )
  port map (
    -- Wishbone interface signals
    wb_rst_i       => wb_rst_i,
    wb_clk_i       => wb_clk_i,
    wb_adr_i       => wb_adr_i,
    wb_dat_i       => wb_dat_i,
    wb_we_i        => wb_we_i,
    wb_stb_i       => wb_stb_i,
    wb_ack_o       => wb_ack_o,
    wb_dat_o       => wb_dat_o,
    -- User registers
    spi_access_strb=> spi_access_strb, 
    spi_wdata      => spi_wdata,
    spi_addr       => spi_addr,
    spi_opcode     => spi_opcode,
    fl_hold        => fl_hold,
    fl_wp          => fl_wp,
    spi_rdy        => spi_rdy,
    spi_rdata_valid=> spi_rdata_valid,
    spi_rdata      => spi_rdata,
    spi_so         => spi_so
  );

  inst_flash_spi : ii_flash_spi
  port map (
    srst           => srst,
    sys_clk        => sys_clk,
    -- User interface
    spi_access_strb=> spi_access_strb,
    spi_wdata      => spi_wdata,
    spi_addr       => spi_addr,
    spi_opcode     => spi_opcode,
    spi_rdy        => spi_rdy,
    spi_rdata_valid=> spi_rdata_valid,
    spi_rdata      => spi_rdata,
    spi_so         => spi_so,
    -- Flash spi interface
    fl_spi_sclk    => rom_sck,
    fl_spi_csb     => rom_cs_n,
    fl_spi_si      => rom_sdi,
    fl_spi_so      => rom_sdo
  );

end arch;



