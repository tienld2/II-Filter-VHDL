-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_aurora_regs
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short Slave Wishbone bridge
--*
--* Description:
--*
--*   Wishbone slave bridge from PCIe interface to ii_aurora_4l_intf
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
--*     @date Created 06/09/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_aurora_regs is
  generic (
    addr_bits            : integer := 5;
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
    tx_test_gen_en       : out std_logic;
    rx_test_chk_en       : out std_logic;
    test_errors          : in  std_logic_vector(15 downto 0);
    gtxreset_n           : out std_logic;
    power_down           : out std_logic;
    run                  : out std_logic;
    loopback             : out std_logic_vector(2 downto 0);
    error_clr            : out std_logic;
    tx_channel_en        : out std_logic;
    rx_channel_en        : out std_logic;
    hard_error           : in  std_logic;
    soft_error           : in  std_logic;
    frame_error          : in  std_logic;
    lane_up              : in  std_logic_vector(3 downto 0);
    channel_up           : in  std_logic;
    pll_locked           : in  std_logic;
    usr_cmd_wr_strb      : out std_logic;
    usr_cmd_wr_data      : out std_logic_vector(23 downto 0);
    usr_cmd_wr_addr      : out std_logic_vector(5 downto 0);
    usr_cmd_wr_rdn       : out std_logic;
    cmd_ch_rdy           : in  std_logic;
    usr_cmd_rd_data      : in  std_logic_vector(23 downto 0);
    usr_cmd_rd_addr      : in  std_logic_vector(5 downto 0);
    usr_cmd_rd_vld       : in  std_logic
  );
end ii_aurora_regs;

architecture arch of ii_aurora_regs is

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

  -- Test mode control/status register
  tx_test_gen_en             <= wb_reg_o(0)(0);-- enable test generator
  rx_test_chk_en             <= wb_reg_o(0)(1);-- enable test checker
  wb_reg_i(0)(1 downto 0)    <= wb_reg_o(0)(1 downto 0);   -- readback
  wb_reg_i(0)(31 downto 16)  <= test_errors;   -- test error count

  -- General control/status register
  gtxreset_n                 <= wb_reg_o(1)(0);-- GTX active low reset
  wb_reg_init(1)(0)          <= '0';
  power_down                 <= wb_reg_o(1)(1);-- power down
  wb_reg_init(1)(1)          <= '1';
  run                        <= wb_reg_o(1)(2);-- enable data flow
  wb_reg_init(1)(2)          <= '0';
  loopback                   <= wb_reg_o(1)(5 downto 3); -- loopback mode
  error_clr                  <= wb_reg_o(1)(6);-- clear errors
  tx_channel_en              <= wb_reg_o(1)(7);-- enable TX channel
  rx_channel_en              <= wb_reg_o(1)(8);-- enable RX channel
  wb_reg_i(1)(8 downto 0)    <= wb_reg_o(1)(8 downto 0);   -- readback
  wb_reg_i(1)(23)            <= hard_error;    -- hard error
  wb_reg_i(1)(24)            <= soft_error;    -- soft error
  wb_reg_i(1)(25)            <= frame_error;   -- frame error
  wb_reg_i(1)(29 downto 26)  <= lane_up;       -- lanes up
  wb_reg_i(1)(30)            <= channel_up;    -- bonded channel up
  wb_reg_i(1)(31)            <= pll_locked;    -- PLL lock detected

  -- Command sub-channel write register
  usr_cmd_wr_strb            <= wr_stb(2);     -- write command strobe
  usr_cmd_wr_data            <= wb_reg_o(2)(23 downto 0); -- write command data
  usr_cmd_wr_addr            <= wb_reg_o(2)(29 downto 24);-- command destination address
  usr_cmd_wr_rdn             <= wb_reg_o(2)(30);          -- (1=write, 0=read) command
  wb_reg_i(2)(30 downto 0)   <= wb_reg_o(2)(30 downto 0); -- readback
  wb_reg_i(2)(31)            <= cmd_ch_rdy;    -- command channel ready

  -- Command sub-channel read register
  wb_reg_i(3)(23 downto 0)   <= usr_cmd_rd_data;-- read data
  wb_reg_i(3)(29 downto 24)  <= usr_cmd_rd_addr;-- read address
  wb_reg_i(3)(30)            <= wb_reg_o(3)(30);-- readback
  wb_reg_i(3)(31)            <= usr_cmd_rd_vld; -- read data valid

end arch;

