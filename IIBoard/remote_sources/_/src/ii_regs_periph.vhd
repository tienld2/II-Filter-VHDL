-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_regs_periph
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.3
--*
--*     @short Slave Wishbone bridge
--*
--* Description:
--*
--*   Wishbone slave bridge from PCIe interface to application logic
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
--*     @date Created 11/23/2010
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_regs_periph is
  generic (
    addr_bits            : integer := 4;
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
    revision             : in  std_logic_vector(15 downto 0);
    cfg                  : in  std_logic_vector(3 downto 0);
    hw_rev               : in  std_logic_vector(2 downto 0);
    hw_type              : in  std_logic_vector(3 downto 0);
    fpga_type            : in  std_logic_vector(1 downto 0);
    app_rst              : out std_logic;
    led                  : out std_logic_vector(1 downto 0);
    ds_data_oe           : out std_logic;
    ds_data_o            : out std_logic;
    ds_data_i            : in  std_logic;
    sub_rev              : in  std_logic_vector(7 downto 0);
    h_pps                : in  std_logic;
    sio_xo_sdo           : out std_logic;
    sio_xo_scl           : out std_logic;
    sio_xo_sdi           : in  std_logic;
    sio_xo_intr          : in  std_logic;
    lpddr2_dpd_req       : out std_logic_vector(3 downto 0);
    lpddr2_phy_init_done : in  std_logic_vector(3 downto 0);
    playback_en          : out std_logic_vector(1 downto 0);
    mem_test_en          : out std_logic_vector(3 downto 0);
    mem_test_error       : in  std_logic_vector(3 downto 0);
    def_pid_addr0        : out std_logic_vector(31 downto 24);
    def_pid_addr1        : out std_logic_vector(31 downto 24);
    bypass_vita_pad      : out std_logic
  );
end ii_regs_periph;

architecture arch of ii_regs_periph is

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

  wb_reg_i(0)(15 downto 0)   <= revision;        -- x6 logic revision
  wb_reg_i(0)(19 downto 16)  <= cfg;             -- x6 hardware variant
  wb_reg_i(0)(22 downto 20)  <= hw_rev;          -- x6 hardware revision
  wb_reg_i(0)(27 downto 24)  <= hw_type;         -- x6 module type
  wb_reg_i(0)(29 downto 28)  <= fpga_type;       -- x6 fpga device type

  app_rst                    <= wb_reg_o(1)(0);
  wb_reg_init(1)(0)          <= '1';             -- default app_rst value
  led                        <= wb_reg_o(1)(2 downto 1);
  wb_reg_init(1)(2 downto 1) <= "11";            -- default LED values
  wb_reg_i(1)(2 downto 0)    <= wb_reg_o(1)(2 downto 0);

  ds_data_oe                 <= wb_reg_o(2)(0); -- 1wire security ROM output enable
  wb_reg_i(2)(0)             <= wb_reg_o(2)(0);
  ds_data_o                  <= wb_reg_o(2)(1); -- 1wire security ROM output
  wb_reg_i(2)(1)             <= wb_reg_o(2)(1);
  wb_reg_i(2)(2)             <= ds_data_i;       -- 1wire security ROM input

  wb_reg_i(3)(31 downto 24)  <= sub_rev;

  bypass_vita_pad            <= wb_reg_o(4)(0);
  wb_reg_i(4)(0)             <= wb_reg_o(4)(0);

  wb_reg_i(5)(0)             <= h_pps;

  sio_xo_sdo                 <= wb_reg_o(6)(0);  -- MGT XO I2C data out
  sio_xo_scl                 <= wb_reg_o(6)(1);  -- MGT XO I2C clock
  wb_reg_i(6)(1 downto 0)    <= wb_reg_o(6)(1 downto 0);
  wb_reg_i(6)(2)             <= sio_xo_sdi;      -- MGT XO I2C data in
  wb_reg_i(6)(3)             <= wb_reg_o(6)(1);  -- MGT XO I2C clock (readback)
  wb_reg_i(6)(4)             <= sio_xo_intr;     -- MGT XO interrupt

  lpddr2_dpd_req             <= wb_reg_o(7)(3 downto 0);
  wb_reg_i(7)(3 downto 0)    <= wb_reg_o(7)(3 downto 0);
  wb_reg_i(7)(7 downto 4)    <= lpddr2_phy_init_done;
  playback_en                <= wb_reg_o(7)(9 downto 8);
  mem_test_en                <= wb_reg_o(7)(15 downto 12);
  wb_reg_i(7)(15 downto 8)   <= wb_reg_o(7)(15 downto 8);
  wb_reg_i(7)(19 downto 16)  <= mem_test_error;
  wb_reg_i(7)(31 downto 20)  <= wb_reg_o(7)(31 downto 20);

  def_pid_addr0              <= wb_reg_o(8)(31 downto 24);  -- Deframer PID0
  wb_reg_i(8)(31 downto 24)  <= wb_reg_o(8)(31 downto 24);

  def_pid_addr1              <= wb_reg_o(9)(31 downto 24);  -- Deframer PID1
  wb_reg_i(9)(31 downto 24)  <= wb_reg_o(9)(31 downto 24);

end arch;

