-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_packetizer_regs
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short Slave Wishbone bridge
--*
--* Description:
--*
--*   Wishbone slave bridge from PCIe interface to ii_packetizer
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
--*     @date created 03/25/2010
--*
--******************************************************************************
--/

library work;
use work.x6_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_packetizer_regs is
  generic (
    addr_bits            : integer := 2;
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
    ch_en                : out std_logic_vector(num_pkt_ch-1 downto 0);
    ch_pkt_size          : out width_24_ch_array;
    pd_addr              : out width_8_ch_array;
    aux_hdr2             : out std_logic_vector(31 downto 0);
    force_pkt_size       : out std_logic_vector(num_pkt_ch-1 downto 0);
    pkt_timer            : out std_logic_vector(21 downto 0)
  );
end ii_packetizer_regs;

architecture arch of ii_packetizer_regs is

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

  ch_en(0)                     <= '1';    -- always enable the alerts channel
  wb_reg_i(0)                  <= wb_reg_o(0);

  aux_hdr2                     <= wb_reg_o(1);
  wb_reg_i(1)                  <= wb_reg_o(1);

  ch_pkt_size(0)               <= wb_reg_o(2)(23 downto 0);
  wb_reg_init(2)(23 downto 0)  <= x"000028";  -- default alert packet size
  pd_addr(0)                   <= wb_reg_o(2)(31 downto 24);
  wb_reg_init(2)(31 downto 24) <= x"ff";      -- default alert packet id
  wb_reg_i(2)                  <= wb_reg_o(2);

  gen_ch_gt1: if (num_pkt_ch > 1) generate
  begin
    ch_en(num_pkt_ch-1 downto 1) <= wb_reg_o(0)(num_pkt_ch-2 downto 0);
    ch_gt1_loop: for i in 1 to (num_pkt_ch-1) generate
    begin
      ch_pkt_size(i)           <= wb_reg_o(2+i)(23 downto 0);
      pd_addr(i)               <= wb_reg_o(2+i)(31 downto 24);
      wb_reg_i(2+i)            <= wb_reg_o(2+i);
    end generate;
  end generate;

  force_pkt_size(0)            <= '1';    -- always force alert packet size
  force_pkt_size(num_pkt_ch-1 downto 1) <= wb_reg_o(34)(num_pkt_ch-2 downto 0);
  wb_reg_i(34)                 <= wb_reg_o(34);

  pkt_timer                    <= wb_reg_o(35)(21 downto 0); -- 16.7ms max
  wb_reg_init(35)              <= X"0003D090";               -- default 1ms
  wb_reg_i(35)                 <= wb_reg_o(35);

end arch;

