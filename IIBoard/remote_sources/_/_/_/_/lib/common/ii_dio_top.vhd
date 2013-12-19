-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--
--* *************************************************************************
--* design name: ii_dio_top
--*
--* @li Target Device: XC6VLX240T
--* @li Tool versions:  ISE 11.4
--*
--*     @short top module for ii_dio along with ii_dio_regs
--*
--* Description:
--*   This component is the top level of a basic digital I/O component.
--*   It instantiates the dio component and a register file.
--*
--*     @generic width         : DIO width
--*     @generic addr_bits     : bits to decode from address in this slave
--*     @generic id            : unique slave id
--*     @generic id_width      : MSBs of address used to select a slave
--*     @port wb_rst_i         : input, WB synchronous active high reset
--*     @port wb_clk_i         : input, WB clock
--*     @port wb_adr_i         : input, WB address in
--*     @port wb_dat_i         : input, WB data in
--*     @port wb_we_i          : input, WB write enable
--*     @port wb_stb_i         : input, WB strobe from master
--*     @port wb_select_i      : input, WB select
--*     @port wb_ack_o         : output, WB acknowledge out
--*     @port clk              : system clock
--*     @port dio_p            : diff-p digital input/output port
--*     @port dio_n            : diff-n digital input/output port
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 03/23/2010
--*
--************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_dio_top is
  generic (
    width                 : integer := 8;
    diff_en               : boolean := FALSE;
    addr_bits             : integer := 2;
    offset                : std_logic_vector(15 downto 0)
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
    -- DIO signals
    clk                   : in    std_logic;
    dio_p                 : inout std_logic_vector(width-1 downto 0);
    dio_n                 : inout std_logic_vector(width-1 downto 0)
  );
end ii_dio_top;

architecture arch of ii_dio_top is

  -- Calculate data width based on whether the DIO port is differential
  -- or single ended.
  function calc_width (wi : in integer) return integer is
  begin
    if (diff_en = TRUE) then
      return wi;
    else
      return wi*2;
    end if;
  end function;

  -- Used in data port definitions
  constant width_data     : integer := calc_width(width);

  component ii_dio
    generic (
      width_io          : integer;
      width_data        : integer
    );
    port (
      clk               : in    std_logic;
      dio_p             : inout std_logic_vector(width_io-1 downto 0);
      dio_n             : inout std_logic_vector(width_io-1 downto 0);
      host_dout         : in    std_logic_vector(width_data-1 downto 0);
      host_din          : out   std_logic_vector(width_data-1 downto 0);
      dio_oe            : in    std_logic_vector(width_data-1 downto 0);
      dio_wr            : in    std_logic
    );
  end component;

  component ii_dio_regs
    generic (
      width             : integer;
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
      host_dout         : out std_logic_vector(width-1 downto 0);
      host_din          : in  std_logic_vector(width-1 downto 0);
      dio_oe            : out std_logic_vector(width-1 downto 0);
      dio_wr            : out std_logic
    );
  end component;

  signal host_din      : std_logic_vector(width_data-1 downto 0);
  signal host_dout     : std_logic_vector(width_data-1 downto 0);  
  signal dio_oe        : std_logic_vector(width_data-1 downto 0);
  signal dio_wr        : std_logic;

begin

  inst_dio : ii_dio
  generic map(
    width_io      => width,
    width_data    => width_data
  )
  port map(
    clk           => clk,
    dio_p         => dio_p,
    dio_n         => dio_n,
    host_dout     => host_dout,
    host_din      => host_din,
    dio_oe        => dio_oe,
    dio_wr        => dio_wr
  );

  inst_dio_regs : ii_dio_regs
  generic map(
    width         => width_data,
    addr_bits     => addr_bits,
    offset        => offset
  )
  port map(
    wb_rst_i      => wb_rst_i,
    wb_clk_i      => wb_clk_i,
    wb_adr_i      => wb_adr_i,
    wb_dat_i      => wb_dat_i,
    wb_we_i       => wb_we_i,
    wb_stb_i      => wb_stb_i,
    wb_ack_o      => wb_ack_o,
    wb_dat_o      => wb_dat_o,
    host_dout     => host_dout,
    host_din      => host_din,
    dio_oe        => dio_oe,
    dio_wr        => dio_wr
  );

end arch;

