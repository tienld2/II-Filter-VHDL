-- Copyright 2010 by innovative integration inc., all rights reserved.
--************************************************************************
--* Design name: ii_regs_master
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.1
--*
--*     @short Master Wishbone Bridge
--*
--* Description:
--*
--*   This component is a bridge between the PCIE register control
--*   interface and the application logic connected to Wishbone system bus.
--*
--*   @port rst              : input, Active high reset on pcie_clk domain
--*   @port pcie_clk         : input, PCIe clock
--*   @port ctrl_addr        : input, PCIe control address
--*   @port ctrl_din         : input, PCIe control data in
--*   @port ctrl_rd          : input, PCIe control read strobe
--*   @port ctrl_wr          : input, PCIe control write strobe
--*   @port ctrl_vld         :output, PCIe control data out valid
--*   @port ctrl_dout        :output, PCIe control data out
--*   @port wb_rst_i         : input, Active high reset on system clock domain
--*   @port wb_clk_i         : input, System clock
--*   @port wb_adr_o         :output, WB address out (to slaves)
--*   @port wb_dat_o         :output, WB data out (to slaves)
--*   @port wb_we_o          :output, WB write enable (to slaves)
--*   @port wb_stb_o         :output, WB strobe (to slaves)
--*   @port wb_cyc_o         :output, WB cycle=strobe (to slaves)
--*   @port wb_ack_i         : input, WB acknowledge in (from slaves)
--*   @port wb_dat_i         : input, WB data in (from slaves)
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
library unimacro;
use unimacro.vcomponents.all;

entity ii_regs_master is
  port (
    rst                  : in  std_logic;
    pcie_clk             : in  std_logic;

    ctrl_addr            : in  std_logic_vector(31 downto 0);
    ctrl_din             : in  std_logic_vector(31 downto 0);
    ctrl_rd              : in  std_logic;
    ctrl_wr              : in  std_logic;
    ctrl_vld             : out std_logic;
    ctrl_dout            : out std_logic_vector(31 downto 0);

    -- Master Wishbone interface signals
    wb_rst_i             : in  std_logic;
    wb_clk_i             : in  std_logic;
    wb_adr_o             : out std_logic_vector(15 downto 0);
    wb_dat_o             : out std_logic_vector(31 downto 0);
    wb_we_o              : out std_logic;
    wb_stb_o             : out std_logic;
    wb_cyc_o             : out std_logic;
    wb_ack_i             : in  std_logic;
    wb_dat_i             : in  std_logic_vector(31 downto 0)
  );
end ii_regs_master;

architecture arch of ii_regs_master is

  signal busy               : std_logic;
  signal busy_d             : std_logic;
  signal ps_fifo_rd         : std_logic;

  signal app_addr           : std_logic_vector(15 downto 0);
  signal app_data           : std_logic_vector(31 downto 0);
  signal app_wr             : std_logic;
  signal app_rd             : std_logic;
  signal app_rd_active      : std_logic;
  signal ctrl_vld_1b        : std_logic;

  signal ps_fifo_wr         : std_logic;
  signal ps_fifo_din        : std_logic_vector(49 downto 0);
  signal ps_fifo_dout       : std_logic_vector(49 downto 0);
  signal ps_valid           : std_logic;
  signal ps_empty           : std_logic;
  signal ps_full            : std_logic;
  signal sp_fifo_wr         : std_logic;
  signal sp_fifo_din        : std_logic_vector(47 downto 0);
  signal sp_fifo_dout       : std_logic_vector(47 downto 0);
  signal sp_empty           : std_logic;
  signal sp_fifo_rd         : std_logic;
  signal wb_ack_i_d         : std_logic;
  signal wb_ack_i_dd        : std_logic;
  signal wb_dat_i_d         : std_logic_vector(31 downto 0);
  signal wb_ack_re          : std_logic;
  signal almostempty        : std_logic;
  signal almostfull         : std_logic;
  signal rdcount            : std_logic_vector(8 downto 0);
  signal wrcount            : std_logic_vector(8 downto 0);
  signal wb_abort_cnt       : unsigned(5 downto 0) := (others => '0');
  signal wb_abort           : std_logic;

  attribute max_fanout              : string;
  attribute max_fanout of app_addr  : signal is "20";
  attribute max_fanout of app_wr    : signal is "40";
  attribute max_fanout of app_rd    : signal is "40";

  attribute keep                    : string;
  attribute keep of wb_adr_o        : signal is "TRUE";
  attribute keep of wb_dat_o        : signal is "TRUE";

begin

  process (pcie_clk)
  begin
    if rising_edge(pcie_clk) then
      ps_fifo_wr      <= ctrl_wr or ctrl_rd;
      ps_fifo_din(49) <= ctrl_wr;
      ps_fifo_din(48) <= ctrl_rd;
      -- don't need 2 lsbs
      ps_fifo_din(47 downto 32) <= ctrl_addr(17 downto 2);
      ps_fifo_din(31 downto 0)  <= ctrl_din;
    end if;
  end process;

  process (wb_clk_i)
  begin
    if (rising_edge(wb_clk_i)) then
      ps_valid  <= ps_fifo_rd;
    end if;
  end process;

  -- FIFO PCIE to sysclk
  fifo_ps : FIFO_DUALCLOCK_MACRO
  generic map (
    DEVICE                  => "VIRTEX6",
    ALMOST_FULL_OFFSET      => x"0080",
    ALMOST_EMPTY_OFFSET     => x"0080",
    DATA_WIDTH              => 50,
    FIFO_SIZE               => "36Kb",
    FIRST_WORD_FALL_THROUGH => FALSE,
    SIM_MODE                => "SAFE")
  port map (
    ALMOSTEMPTY             => almostempty,
    ALMOSTFULL              => almostfull,
    DO                      => ps_fifo_dout,
    EMPTY                   => ps_empty,
    FULL                    => ps_full,
    RDCOUNT                 => rdcount,
    RDERR                   => open,
    WRCOUNT                 => wrcount,
    WRERR                   => open,
    DI                      => ps_fifo_din,
    RDCLK                   => wb_clk_i,
    RDEN                    => ps_fifo_rd,
    RST                     => rst,
    WRCLK                   => pcie_clk,
    WREN                    => ps_fifo_wr
  );

  process (wb_clk_i)
  begin
    if rising_edge(wb_clk_i) then
      app_wr   <= ps_fifo_dout(49) and ps_valid;
      app_rd   <= ps_fifo_dout(48) and ps_valid;
      app_addr <= ps_fifo_dout(47 downto 32);
      app_data <= ps_fifo_dout(31 downto 0);
    end if;
  end process;

  -- Don't bleed pcie-to-sysclk fifo if we're in a middle of a transaction
  process (wb_clk_i)
  begin
    if rising_edge(wb_clk_i) then
      if (wb_rst_i = '1' or wb_ack_i_d = '1' or wb_abort = '1') then
        busy <= '0';
      elsif (ps_empty = '0') then
        busy <= '1';
      end if;
      busy_d <= busy;
    end if;
  end process;

  -- Read fifo when detecting a rising edge on busy
  ps_fifo_rd <= busy and not busy_d;

  -- Writes out using wishbone master
  process (wb_clk_i)
  begin
    if rising_edge(wb_clk_i) then
      wb_adr_o <= app_addr;
      -- Reset or response from slave or timeout abort
      if (wb_rst_i = '1' or wb_ack_i = '1' or wb_abort = '1') then
        wb_stb_o <= '0';
        wb_cyc_o <= '0';
        wb_we_o  <= '0';
      else
        if (app_wr = '1') then
          wb_stb_o <= '1';
          wb_cyc_o <= '1';
          wb_we_o  <= '1';
          wb_dat_o <= app_data;
        elsif (app_rd = '1') then
          wb_stb_o <= '1';
          wb_cyc_o <= '1';
          wb_we_o  <= '0';
          wb_dat_o <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  process (wb_clk_i)
  begin
    if rising_edge(wb_clk_i) then
      -- Reset or response from slave or timeout abort
      if (wb_rst_i = '1' or wb_ack_i_d = '1' or wb_abort = '1') then
        app_rd_active <= '0';
      elsif (app_rd = '1') then
        app_rd_active <= '1';     -- latch response from slave(s)
      end if;
    end if;
  end process;

  -- Abort Wishbone transaction if slave doesn't respond within 64 cycles
  process (wb_clk_i)
  begin
    if rising_edge(wb_clk_i) then
      if (busy = '0') then
        wb_abort_cnt <= (others => '1');
      else
        wb_abort_cnt <= wb_abort_cnt - 1;
      end if;
      if (wb_abort_cnt = 1) then
        wb_abort <= '1';
      else
        wb_abort <= '0';
      end if;
    end if;
  end process;

  -- synthesis translate_off
  process (wb_clk_i)
  begin
    if rising_edge(wb_clk_i) then
      if (ps_fifo_wr = '1') then
        assert ps_full = '0'
        report "ps fifo overflowed!" severity failure;
      end if;
    end if;
  end process;
  -- synthesis translate_on

------------------------------------------------------------------------------
-- Returning datapath from system clock (wb_clk_i) to pcie clock domain
------------------------------------------------------------------------------

  -- Detect posedge, to ignore potential wider ack pulses
  wb_ack_re <= not wb_ack_i_dd and wb_ack_i_d;

  -- If reading, latch response from slave with a fifo write.
  -- If read is aborted, respond with read error word; ignore if writing.
  process (wb_clk_i)
  begin
    if rising_edge(wb_clk_i) then
      wb_ack_i_d  <= wb_ack_i;
      wb_ack_i_dd <= wb_ack_i_d;
      wb_dat_i_d <= wb_dat_i;
      sp_fifo_wr <= app_rd_active and (wb_ack_re or wb_abort);
      if (wb_abort = '0') then
        sp_fifo_din <= x"0000" & wb_dat_i_d;    -- returning read data
      else
        sp_fifo_din <= x"000000BADA55";         -- returning read error
      end if;
    end if;
  end process;

  -- Read when not empty
  process (pcie_clk)
  begin
    if rising_edge(pcie_clk) then
      if (rst = '1') then
        sp_fifo_rd <= '0';
      elsif (sp_fifo_rd = '1') then
        sp_fifo_rd <= '0';
      elsif (sp_empty = '0') then
        sp_fifo_rd <= '1';
      end if;
    end if;
  end process;

  process (pcie_clk)
  begin
    if (rising_edge(pcie_clk)) then
      ctrl_vld_1b <= sp_fifo_rd;
    end if;
  end process;

  -- FIFO sysclk to PCIE
  fifo_sp : FIFO_DUALCLOCK_MACRO
  generic map (
    DEVICE                  => "VIRTEX6",
    ALMOST_FULL_OFFSET      => x"0080",
    ALMOST_EMPTY_OFFSET     => x"0080",
    DATA_WIDTH              => 48,
    FIFO_SIZE               => "36Kb",
    FIRST_WORD_FALL_THROUGH => FALSE,
    SIM_MODE                => "SAFE")
  port map (
    ALMOSTEMPTY             => almostempty,
    ALMOSTFULL              => almostfull,
    DO                      => sp_fifo_dout,
    EMPTY                   => sp_empty,
    FULL                    => open,
    RDCOUNT                 => rdcount,
    RDERR                   => open,
    WRCOUNT                 => wrcount,
    WRERR                   => open,
    DI                      => sp_fifo_din,
    RDCLK                   => pcie_clk,
    RDEN                    => sp_fifo_rd,
    RST                     => rst,
    WRCLK                   => wb_clk_i,
    WREN                    => sp_fifo_wr
  );

  -- Output stage; registered to ease timing
  process (pcie_clk)
  begin
    if rising_edge(pcie_clk) then
      ctrl_vld  <= ctrl_vld_1b;
      ctrl_dout <= sp_fifo_dout(31 downto 0);
    end if;
  end process;

end arch;

