-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_packetizer_top
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short Top module for ii_packetizer with ii_packetizer_regs
--*
--* Description:
--*
--*   This component is the top level of the packetizer.
--*   It instantiates the packetizer component and a register file.
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
--*   @port src_data_cnt       : input, source channel fifo word count
--*   @port src_aempty         : input, source channel fifo almost empty
--*   @port src_empty          : input, source channel fifo empty
--*   @port src_rden           :output, source channel fifo read enables
--*   @port src_data_vld       : input, source channel data is valid
--*   @port data_in            : input, source channel data in array
--*   @port dest_rdy           : input, destination fifo ready
--*   @port dest_wren          :output, destination fifo write enable
--*   @port data_out           :output, packetized data out
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 03/25/2010
--*
--******************************************************************************
--/

library work;
use work.x6_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_packetizer_top is
  generic (
    addr_bits            : integer := 6;
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

    -- Reset and clock
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;
  
    -- Exported settings
    ch_pkt_size          : out width_24_ch_array;
    force_pkt_size       : out std_logic_vector(num_pkt_ch-1 downto 0);

    -- Source channels interface
    src_data_cnt         : in  width_22_ch_array;
    src_aempty           : in  std_logic_vector(num_pkt_ch-1 downto 0);
    src_empty            : in  std_logic_vector(num_pkt_ch-1 downto 0);
    src_rden             : out std_logic_vector(num_pkt_ch-1 downto 0);
    src_data_vld         : in  std_logic_vector(num_pkt_ch-1 downto 0);
    data_in              : in  width_128_ch_array;

    -- Destination channel interface
    dest_rdy             : in  std_logic;
    dest_wren            : out std_logic;
    data_out             : out std_logic_vector(127 downto 0)
  );
end ii_packetizer_top;

architecture arch of ii_packetizer_top is

  component ii_packetizer
    port (
      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- Configuration
      ch_en                : in  std_logic_vector(num_pkt_ch-1 downto 0);
      ch_pkt_size          : in  width_24_ch_array;
      pd_addr              : in  width_8_ch_array;
      aux_hdr2             : in  std_logic_vector(31 downto 0);
      force_pkt_size       : in  std_logic_vector(num_pkt_ch-1 downto 0);
      pkt_timer            : in  std_logic_vector(21 downto 0);

      -- Source channels interface
      src_data_cnt         : in  width_22_ch_array;
      src_aempty           : in  std_logic_vector(num_pkt_ch-1 downto 0);
      src_empty            : in  std_logic_vector(num_pkt_ch-1 downto 0);
      src_rden             : out std_logic_vector(num_pkt_ch-1 downto 0);
      src_data_vld         : in  std_logic_vector(num_pkt_ch-1 downto 0);
      data_in              : in  width_128_ch_array;

      -- Destination channel interface
      dest_rdy             : in  std_logic;
      dest_wren            : out std_logic;
      data_out             : out std_logic_vector(127 downto 0)
    );
  end component;

  component ii_packetizer_regs
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

      -- user registers
      ch_en                : out std_logic_vector(num_pkt_ch-1 downto 0);
      ch_pkt_size          : out width_24_ch_array;
      pd_addr              : out width_8_ch_array;
      aux_hdr2             : out std_logic_vector(31 downto 0);
      force_pkt_size       : out std_logic_vector(num_pkt_ch-1 downto 0);
      pkt_timer            : out std_logic_vector(21 downto 0)
    );
  end component;

  signal ch_en                : std_logic_vector(num_pkt_ch-1 downto 0);
  signal ch_pkt_size_int      : width_24_ch_array;
  signal pd_addr              : width_8_ch_array;
  signal aux_hdr2             : std_logic_vector(31 downto 0);
  signal force_pkt_size_int   : std_logic_vector(num_pkt_ch-1 downto 0);
  signal pkt_timer            : std_logic_vector(21 downto 0);

begin

  inst_packetizer : ii_packetizer
    port map (
      -- Reset and clock
      srst                 => srst,
      sys_clk              => sys_clk,

      -- Configuration
      ch_en                => ch_en,
      ch_pkt_size          => ch_pkt_size_int,
      pd_addr              => pd_addr,
      aux_hdr2             => aux_hdr2,
      force_pkt_size       => force_pkt_size_int,
      pkt_timer            => pkt_timer,

      -- Source channels interface
      src_data_cnt         => src_data_cnt,
      src_aempty           => src_aempty,
      src_empty            => src_empty,
      src_rden             => src_rden,
      src_data_vld         => src_data_vld,
      data_in              => data_in,

      -- Destination channel interface
      dest_rdy             => dest_rdy,
      dest_wren            => dest_wren,
      data_out             => data_out
    );

  inst_packetizer_regs : ii_packetizer_regs
    generic map (
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

      -- user registers
      ch_en                => ch_en,  
      ch_pkt_size          => ch_pkt_size_int,   
      pd_addr              => pd_addr, 
      aux_hdr2             => aux_hdr2,
      force_pkt_size       => force_pkt_size_int,
      pkt_timer            => pkt_timer
    );

  ch_pkt_size    <= ch_pkt_size_int;
  force_pkt_size <= force_pkt_size_int;

end arch;

