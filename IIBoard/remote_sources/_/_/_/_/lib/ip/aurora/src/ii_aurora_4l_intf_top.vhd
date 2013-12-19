-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_aurora_4l_intf_top
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.1
--*
--*     @short 4 Lane Aurora Interface Top
--*
--* Description:
--*
--*   This component is a simple interface to a 4 lane Aurora core.
--*   The four GTX lanes are bonded internally in the core generated using
--*   Xilinx core generator.
--*   The user connects to this component through two FIFOs (Write and read),
--*   in addition to a slave wishbone used to control and monitor the status
--*   of the interface.
--*
--*   @port srst              : input, synchronous active high reset
--*   @port sys_clk           : input, system clock
--*   @port run_o             :output, enable the user interface and data flow
--*   @port src_rdy           :output, Source is ready for data
--*   @port src_valid         : input, Source data valid
--*   @port src_din           : input, Source data input (little endian)
--*   @port dest_rdy          : input, Destination FIFO room available
--*   @port dest_valid        :output, Destination FIFO data input valid
--*   @port dest_dout         :output, Destination FIFO data input
--*   @port wb_rst_i          : input, WB synchronous active high reset
--*   @port wb_clk_i          : input, WB clock
--*   @port wb_adr_i          : input, WB address in
--*   @port wb_dat_i          : input, WB data in
--*   @port wb_we_i           : input, WB write enable
--*   @port wb_stb_i          : input, WB strobe from master
--*   @port wb_ack_o          :output, WB acknowledge out
--*   @port wb_dat_o          :output, WB data out
--*   @port gtx_refclk_p      : input, GTX reference clock differential pair (side-P)
--*   @port gtx_refclk_n      : input, GTX reference clock differential pair (side-N)
--*   @port gtx_rxp           : input, GTX receive ports differential pair (side-P)
--*   @port gtx_rxn           : input, GTX receive ports differential pair (side-N)
--*   @port gtx_txp           :output, GTX transmit ports differential pair (side-P)
--*   @port gtx_txn           :output, GTX transmit ports differential pair (side-N)
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

library unisim;
use unisim.vcomponents.all;

entity ii_aurora_4l_intf_top is
  generic (
    USE_CHIPSCOPE        : integer := 0;
    SIM_GTXRESET_SPEEDUP : integer := 0;  -- Set to 1 to speed up sim reset
    addr_bits            : integer := 5;
    offset               : std_logic_vector(15 downto 0)
  );
  port (
    -- System reset and clocks
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;
    run_o                : out std_logic;

    -- Data source i/f
    src_rdy              : out std_logic;
    src_valid            : in  std_logic;
    src_din              : in  std_logic_vector(127 downto 0);

    -- Destination FIFO i/f
    dest_rdy             : in  std_logic;
    dest_valid           : out std_logic;
    dest_dout            : out std_logic_vector(127 downto 0);

    -- slave wishbone interface
    wb_rst_i             : in  std_logic;
    wb_clk_i             : in  std_logic;
    wb_adr_i             : in  std_logic_vector(15 downto 0);
    wb_dat_i             : in  std_logic_vector(31 downto 0);
    wb_we_i              : in  std_logic;
    wb_stb_i             : in  std_logic;
    wb_ack_o             : out std_logic;
    wb_dat_o             : out std_logic_vector(31 downto 0);

    -- GTX Serial I/O ports
    gtx_refclk_p         : in  std_logic;
    gtx_refclk_n         : in  std_logic;
    gtx_rxp              : in  std_logic_vector(3 downto 0);
    gtx_rxn              : in  std_logic_vector(3 downto 0);
    gtx_txp              : out std_logic_vector(3 downto 0);
    gtx_txn              : out std_logic_vector(3 downto 0)
  );
end ii_aurora_4l_intf_top;


architecture arch of ii_aurora_4l_intf_top is

  component ii_aurora_4l_intf
    generic (
      USE_CHIPSCOPE        : integer := 0;
      SIM_GTXRESET_SPEEDUP : integer := 0  -- Set to 1 to speed up sim reset
    );
    port (
      -- System reset and clocks
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- Transmit FIFO interface
      tx_fifo_wr           : in  std_logic;
      tx_fifo_din          : in  std_logic_vector(127 downto 0);
      tx_fifo_rdy          : out std_logic;

      -- Receive FIFO interface
      rx_fifo_rd           : in  std_logic;
      rx_fifo_dout         : out std_logic_vector(127 downto 0);
      rx_fifo_valid        : out std_logic;
      rx_fifo_empty        : out std_logic;
      rx_fifo_aempty       : out std_logic;

      -- Command sub-channel interface
      cmd_tx_req           : in  std_logic;
      cmd_tx_data          : in  std_logic_vector(31 downto 0);
      cmd_tx_ack           : out std_logic;
      cmd_rx_valid         : out std_logic;
      cmd_rx_data          : out std_logic_vector(31 downto 0);

      -- User Control
      run                  : in  std_logic;
      gtxreset_n           : in  std_logic;
      power_down           : in  std_logic;
      loopback             : in  std_logic_vector(2 downto 0);
      error_clr            : in  std_logic;

      -- Status
      pll_locked           : out std_logic;
      lane_up              : out std_logic_vector(3 downto 0);
      channel_up           : out std_logic;
      hard_error           : out std_logic;
      soft_error           : out std_logic;
      frame_error          : out std_logic;

      -- GTX Serial I/O ports
      gtx_refclk_p         : in  std_logic;
      gtx_refclk_n         : in  std_logic;
      gtx_rxp              : in  std_logic_vector(3 downto 0);
      gtx_rxn              : in  std_logic_vector(3 downto 0);
      gtx_txp              : out std_logic_vector(3 downto 0);
      gtx_txn              : out std_logic_vector(3 downto 0)
    );
  end component;

  component ii_aurora_tx_intf
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
  end component;

  component ii_aurora_rx_intf
    generic (
      WIDTH                : integer := 128
    );
    port (
      srst                 : in  std_logic;
      clk                  : in  std_logic;

      channel_en           : in  std_logic;
      test_chk_en          : in  std_logic;
      test_errors          : out std_logic_vector(15 downto 0);

      src_empty            : in  std_logic;
      src_aempty           : in  std_logic;
      src_rden             : out std_logic;
      src_din              : in  std_logic_vector(WIDTH-1 downto 0);
      src_valid            : in  std_logic;

      dest_dout            : out std_logic_vector(WIDTH-1 downto 0);
      dest_valid           : out std_logic;
      dest_rdy             : in  std_logic
    );
  end component;

  component ii_aurora_regs
    generic (
      addr_bits            : integer := 5;
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- slave wishbone interface
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
  end component;

  component ii_aurora_cmd
    port (
      -- System reset and clocks
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- User interface
      usr_cmd_wr_strb      : in  std_logic;
      usr_cmd_wr_data      : in  std_logic_vector(23 downto 0);
      usr_cmd_wr_addr      : in  std_logic_vector(5 downto 0);
      usr_cmd_wr_rdn       : in  std_logic;
      cmd_ch_rdy           : out std_logic;
      usr_cmd_rd_data      : out std_logic_vector(23 downto 0);
      usr_cmd_rd_addr      : out std_logic_vector(5 downto 0);
      usr_cmd_rd_vld       : out std_logic;

      -- Aurora core status
      channel_up           : in  std_logic;

      -- Aurora Command sub-channel interface
      cmd_tx_req           : out std_logic;
      cmd_tx_data          : out std_logic_vector(31 downto 0);
      cmd_tx_ack           : in  std_logic;
      cmd_rx_valid         : in  std_logic;
      cmd_rx_data          : in  std_logic_vector(31 downto 0)
    );
  end component;

  -- Transmit FIFO interfaces
  signal tx_fifo_wr           : std_logic;
  signal tx_fifo_din          : std_logic_vector(127 downto 0);
  signal tx_fifo_rdy          : std_logic;

  -- Receive FIFO interfaces
  signal rx_fifo_rd           : std_logic;
  signal rx_fifo_dout         : std_logic_vector(127 downto 0);
  signal rx_fifo_valid        : std_logic;
  signal rx_fifo_empty        : std_logic;
  signal rx_fifo_aempty       : std_logic;

  -- Command sub-channel interface
  signal cmd_tx_req           : std_logic;
  signal cmd_tx_data          : std_logic_vector(31 downto 0);
  signal cmd_tx_ack           : std_logic;
  signal cmd_rx_valid         : std_logic;
  signal cmd_rx_data          : std_logic_vector(31 downto 0);
  signal usr_cmd_wr_strb      : std_logic;
  signal usr_cmd_wr_data      : std_logic_vector(23 downto 0);
  signal usr_cmd_wr_addr      : std_logic_vector(5 downto 0);
  signal usr_cmd_wr_rdn       : std_logic;
  signal cmd_ch_rdy           : std_logic;
  signal usr_cmd_rd_data      : std_logic_vector(23 downto 0);
  signal usr_cmd_rd_addr      : std_logic_vector(5 downto 0);
  signal usr_cmd_rd_vld       : std_logic;

  -- User Control
  signal run                  : std_logic;
  signal gtxreset_n           : std_logic;
  signal power_down           : std_logic;
  signal loopback             : std_logic_vector(2 downto 0);
  signal error_clr            : std_logic;
  signal tx_channel_en        : std_logic;
  signal rx_channel_en        : std_logic;
  signal tx_test_gen_en       : std_logic;
  signal rx_test_chk_en       : std_logic;

  -- Status
  signal pll_locked           : std_logic;
  signal lane_up              : std_logic_vector(3 downto 0);
  signal channel_up           : std_logic;
  signal hard_error           : std_logic;
  signal soft_error           : std_logic;
  signal frame_error          : std_logic;
  signal test_errors          : std_logic_vector(15 downto 0);

  -- Misc
  signal srst_d               : std_logic;
  signal pipe_rst_1b          : std_logic;
  signal pipe_rst             : std_logic;

begin

  ------------------------------------------------------------------------------
  -- Aurora interface
  ------------------------------------------------------------------------------
  aurora : ii_aurora_4l_intf
    generic map (
      USE_CHIPSCOPE        => USE_CHIPSCOPE,
      SIM_GTXRESET_SPEEDUP => SIM_GTXRESET_SPEEDUP
    )
    port map (
      -- System reset and clocks
      srst                 => srst_d,
      sys_clk              => sys_clk,

      -- Transmit FIFO interface
      tx_fifo_wr           => tx_fifo_wr,
      tx_fifo_din          => tx_fifo_din,
      tx_fifo_rdy          => tx_fifo_rdy,

      -- Receive FIFO interface
      rx_fifo_rd           => rx_fifo_rd,
      rx_fifo_dout         => rx_fifo_dout,
      rx_fifo_valid        => rx_fifo_valid,
      rx_fifo_empty        => rx_fifo_empty,
      rx_fifo_aempty       => rx_fifo_aempty,

      -- Command sub-channel interface
      cmd_tx_req           => cmd_tx_req,
      cmd_tx_data          => cmd_tx_data,
      cmd_tx_ack           => cmd_tx_ack,
      cmd_rx_valid         => cmd_rx_valid,
      cmd_rx_data          => cmd_rx_data,

      -- User Control
      run                  => run,
      gtxreset_n           => gtxreset_n,
      power_down           => power_down,
      loopback             => loopback,
      error_clr            => error_clr,

      -- Status
      pll_locked           => pll_locked,
      lane_up              => lane_up,
      channel_up           => channel_up,
      hard_error           => hard_error,
      soft_error           => soft_error,
      frame_error          => frame_error,

      -- V5 GTP_DUAL ports
      gtx_refclk_p         => gtx_refclk_p,
      gtx_refclk_n         => gtx_refclk_n,
      gtx_rxp              => gtx_rxp,
      gtx_rxn              => gtx_rxn,
      gtx_txp              => gtx_txp,
      gtx_txn              => gtx_txn
    );

  cmd : ii_aurora_cmd
    port map (
      -- System reset and clocks
      srst                 => srst_d,
      sys_clk              => sys_clk,

      -- User interface
      usr_cmd_wr_strb      => usr_cmd_wr_strb,
      usr_cmd_wr_data      => usr_cmd_wr_data,
      usr_cmd_wr_addr      => usr_cmd_wr_addr,
      usr_cmd_wr_rdn       => usr_cmd_wr_rdn,
      cmd_ch_rdy           => cmd_ch_rdy,
      usr_cmd_rd_data      => usr_cmd_rd_data,
      usr_cmd_rd_addr      => usr_cmd_rd_addr,
      usr_cmd_rd_vld       => usr_cmd_rd_vld,

      -- Aurora core status
      channel_up           => channel_up,

      -- Aurora Command sub-channel interface
      cmd_tx_req           => cmd_tx_req,
      cmd_tx_data          => cmd_tx_data,
      cmd_tx_ack           => cmd_tx_ack,
      cmd_rx_valid         => cmd_rx_valid,
      cmd_rx_data          => cmd_rx_data
    );

  ------------------------------------------------------------------------------
  -- Tx datapath
  ------------------------------------------------------------------------------
  tx : ii_aurora_tx_intf
    generic map (
      WIDTH                => 128
    )
    port map (
      srst                 => pipe_rst,
      clk                  => sys_clk,

      channel_en           => tx_channel_en,
      test_gen_en          => tx_test_gen_en,

      src_rdy              => src_rdy,
      src_valid            => src_valid,
      src_din              => src_din,

      dest_rdy             => tx_fifo_rdy,
      dest_valid           => tx_fifo_wr,
      dest_dout            => tx_fifo_din
    );
  ------------------------------------------------------------------------------
  -- Rx datapath
  ------------------------------------------------------------------------------
  rx : ii_aurora_rx_intf
    generic map (
      WIDTH                => 128
    )
    port map (
      srst                 => pipe_rst,
      clk                  => sys_clk,

      channel_en           => rx_channel_en,
      test_chk_en          => rx_test_chk_en,
      test_errors          => test_errors,

      src_empty            => rx_fifo_empty,
      src_aempty           => rx_fifo_aempty,
      src_rden             => rx_fifo_rd,
      src_din              => rx_fifo_dout,
      src_valid            => rx_fifo_valid,

      dest_dout            => dest_dout,
      dest_valid           => dest_valid,
      dest_rdy             => dest_rdy
    );

  ------------------------------------------------------------------------------
  -- Wishbone slave: Register file
  ------------------------------------------------------------------------------
  regs : ii_aurora_regs
    generic map (
      addr_bits            => addr_bits,
      offset               => offset
    )
    port map (
      -- slave wishbone interface
      wb_rst_i             => wb_rst_i,
      wb_clk_i             => wb_clk_i,
      wb_adr_i             => wb_adr_i,
      wb_dat_i             => wb_dat_i,
      wb_we_i              => wb_we_i,
      wb_stb_i             => wb_stb_i,
      wb_ack_o             => wb_ack_o,
      wb_dat_o             => wb_dat_o,

      -- User registers
      tx_test_gen_en       => tx_test_gen_en,
      rx_test_chk_en       => rx_test_chk_en,
      test_errors          => test_errors,
      gtxreset_n           => gtxreset_n,
      power_down           => power_down,
      run                  => run,
      loopback             => loopback,
      error_clr            => error_clr,
      tx_channel_en        => tx_channel_en,
      rx_channel_en        => rx_channel_en,
      hard_error           => hard_error,
      soft_error           => soft_error,
      frame_error          => frame_error,
      lane_up              => lane_up,
      channel_up           => channel_up,
      pll_locked           => pll_locked,
      usr_cmd_wr_strb      => usr_cmd_wr_strb,
      usr_cmd_wr_data      => usr_cmd_wr_data,
      usr_cmd_wr_addr      => usr_cmd_wr_addr,
      usr_cmd_wr_rdn       => usr_cmd_wr_rdn,
      cmd_ch_rdy           => cmd_ch_rdy,
      usr_cmd_rd_data      => usr_cmd_rd_data,
      usr_cmd_rd_addr      => usr_cmd_rd_addr,
      usr_cmd_rd_vld       => usr_cmd_rd_vld
    );

  -- Register run and pass it to the output
  -- also generate a reset to the RX/TX interfaces when run is not set
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      run_o    <= run;
      srst_d      <= srst;
      pipe_rst_1b <= srst_d or not run;
      pipe_rst    <= pipe_rst_1b;
    end if;
  end process;

end arch;
