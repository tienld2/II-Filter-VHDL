-- Copyright 2010 by innovative integration inc., all rights reserved.
--
--************************************************************************
--* Design name: ii_regs_core
--*
--* @li target device: xc6vlx240t
--* @li tool versions:  ise 11.4
--*
--*     @short Slave Wishbone interface core
--*
--* Description:
--*
--*   Wishbone slave interface core from PCIe interface to application logic
--*
--*   @generic addr_bits     : bits to decode from address in this slave
--*   @generic id            : unique slave id
--*   @generic id_width      : MSBs of address used to select a slave
--*
--*     @author innovative integration
--*     @version 1.0
--*     @date created 02/23/2010
--*
--***********************************************************************-
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_regs_core is
  generic (
    addr_bits            : integer;
    offset               : std_logic_vector(15 downto 0)
  );
  port (
    -- Wishbone Slave Interface
    wb_rst_i             : in  std_logic;
    wb_clk_i             : in  std_logic;
    wb_adr_i             : in  std_logic_vector(15 downto 0);
    wb_dat_i             : in  std_logic_vector(31 downto 0);
    wb_we_i              : in  std_logic;
    wb_stb_i             : in  std_logic;
    wb_ack_o             : out std_logic;
    wb_dat_o             : out std_logic_vector(31 downto 0);
    -- Core to Slave Register Interface signals
    wr_stb               : out std_logic_vector(2**addr_bits-1 downto 0);
    rd_stb               : out std_logic_vector(2**addr_bits-1 downto 0);
    wb_reg_init_core     : in  std_logic_vector((2**addr_bits*32)-1 downto 0);
    wb_reg_i_core        : in  std_logic_vector((2**addr_bits*32)-1 downto 0);
    wb_reg_o_core        : out std_logic_vector((2**addr_bits*32)-1 downto 0)
  );
end ii_regs_core;

architecture arch of ii_regs_core is

  constant addr_range         : integer := 2**addr_bits;

  subtype wb_reg_width is std_logic_vector(31 downto 0);
  type wb_reg_t is array (addr_range-1 downto 0) of wb_reg_width;

  signal wb_reg_i             : wb_reg_t;
  signal wb_reg_o             : wb_reg_t;
  signal wb_reg_init          : wb_reg_t;

  signal wb_rst_i_d           : std_logic;
  signal wb_adr_i_d           : std_logic_vector(15 downto 0);
  signal wb_dat_i_d           : std_logic_vector(31 downto 0);
  signal wb_we_i_d            : std_logic;
  signal wb_stb_i_d           : std_logic;
  signal slave_hit            : std_logic;
  signal app_addr             : std_logic_vector(addr_bits-1 downto 0);
  signal app_wr               : std_logic;
  signal app_rd               : std_logic;
  signal app_wr_d             : std_logic;
  signal app_rd_d             : std_logic;
  signal app_wr_re            : std_logic;
  signal app_rd_re            : std_logic;
  signal app_data_read        : std_logic_vector(31 downto 0);
  signal rd_dly_sreg          : std_logic_vector(5 downto 0);
  signal app_wr_en            : std_logic_vector(addr_range-1 downto 0);
  signal app_wr_en_d          : std_logic_vector(addr_range-1 downto 0);

  attribute max_fanout        : string;
  attribute max_fanout of app_addr : signal is "20";

begin

  -- Form incoming data array
  process (wb_reg_o, wb_reg_init_core, wb_reg_i_core)
  begin
    for i in 1 to addr_range loop
      wb_reg_i(i-1)    <= wb_reg_i_core((i*32)-1 downto (i-1)*32);
      wb_reg_init(i-1) <= wb_reg_init_core((i*32)-1 downto (i-1)*32);
      wb_reg_o_core((i*32)-1 downto (i-1)*32) <= wb_reg_o(i-1);
    end loop;
  end process;

  -- Register to ease timing closure
  process (wb_clk_i)
  begin
    if (rising_edge(wb_clk_i)) then
      wb_rst_i_d <= wb_rst_i;
      wb_adr_i_d <= wb_adr_i;
      wb_dat_i_d <= wb_dat_i;
      wb_we_i_d  <= wb_we_i;
      wb_stb_i_d <= wb_stb_i;
    end if;
  end process;

  app_addr <= wb_adr_i_d(addr_bits-1 downto 0);

  -- When strobe asserts and address matches offset, this slave was hit
  slave_hit <= '1' when (wb_stb_i_d = '1' and
                         (offset(offset'high downto addr_bits) =
                         wb_adr_i_d(wb_adr_i_d'high downto addr_bits))) else
               '0';

  -- Decode the access and detect a rising edge on it
  app_wr <= slave_hit and wb_we_i_d;
  app_rd <= slave_hit and not wb_we_i_d;

  process (wb_clk_i)
  begin
    if (rising_edge(wb_clk_i)) then
      if (wb_rst_i_d = '1') then
        app_wr_d  <= '0';
        app_rd_d  <= '0';
        app_wr_re <= '0';
        app_rd_re <= '0';
      else
        app_wr_d  <= app_wr;
        app_rd_d  <= app_rd;
        app_wr_re <= app_wr and not app_wr_d;
        app_rd_re <= app_rd and not app_rd_d;
      end if;
    end if;
  end process;

  process (wb_clk_i)
  begin
    if (rising_edge(wb_clk_i)) then
      if (wb_rst_i_d = '1') then
        wb_dat_o <= (others => 'Z');
        wb_ack_o <= '0';
      else
        app_data_read <= wb_reg_i(to_integer(unsigned(app_addr)));
        wb_ack_o      <= app_wr_re or (not rd_dly_sreg(rd_dly_sreg'high-1) and
                         rd_dly_sreg(rd_dly_sreg'high));
        if (rd_dly_sreg(rd_dly_sreg'high-2) = '0' and
            rd_dly_sreg(rd_dly_sreg'high) = '1') then
          wb_dat_o <= app_data_read;     -- returning data read
        else
          wb_dat_o <= (others => 'Z');
        end if;
      end if;
    end if;
  end process;

  -- ************************************************************************
  -- Handle read-access controls
  process (wb_clk_i)
  begin
    if (rising_edge(wb_clk_i)) then
      if (app_rd_re = '1') then
        rd_dly_sreg <= (others => '1');
      else
        rd_dly_sreg <= rd_dly_sreg(rd_dly_sreg'high-1 downto 0) & '0';
      end if;
    end if;
  end process;

  -- ************************************************************************
  --* read & write strobe decodes
  stb_gen: for i in addr_range-1 downto 0 generate
    --* read strobe decodes
    rd_stb_gen:process(wb_clk_i)
    begin
      if (rising_edge(wb_clk_i)) then
        if (app_rd_re = '1' and to_integer(unsigned(app_addr)) = i) then
          rd_stb(i) <= '1';
        else
          rd_stb(i) <= '0';
        end if;
      end if;
    end process rd_stb_gen;

    --* Outgoing data and write strobe
    wb_reg_output: process(wb_clk_i)
    begin
      if (rising_edge(wb_clk_i)) then
        if (app_wr_re = '1' and to_integer(unsigned(app_addr)) = i) then
          app_wr_en(i) <= '1';
        else
          app_wr_en(i) <= '0';
        end if;
        app_wr_en_d(i) <= app_wr_en(i);
        wr_stb(i)      <= app_wr_en_d(i);
        if (wb_rst_i_d = '1') then
          wb_reg_o(i) <= wb_reg_init(i);
        elsif (app_wr_en(i) = '1') then
          wb_reg_o(i) <= wb_dat_i_d;
        end if;
      end if;
    end process;
  end generate;

end arch;

