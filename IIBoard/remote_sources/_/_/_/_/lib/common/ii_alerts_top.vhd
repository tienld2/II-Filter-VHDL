-- Copyright 2009 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_alerts_top
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short Top module for ii_alerts with ii_alert_regs
--*
--* Description:
--*
--*   Top module for ii_alerts with ii_alert_regs
--*
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
--*   @port ref_clk            : input, reference clock used for timebase
--*   @port alert_data         : input, alert data
--*   @port alert              : input, alert data trigger inputs
--*   @port trigger            : input, trigger
--*   @port timestamp_rollover :output, indicates that the 32-bit timestamp
--*                                     counter had rolled from X"FFFFFFFF" to 0
--*   @port alert_fifo_wrd_cnt :output, alert FIFO word count
--*   @port alert_fifo_aempty  :output, alert FIFO almost empty
--*   @port alert_fifo_empty   :output, alert FIFO empty
--*   @port alert_fifo_rd      : input, alert FIFO read enable
--*   @port alert_dout_vld     :output, alert FIFO data output is valid
--*   @port alert_dout         :output, alert FIFO data output
--*
--*     @author innovative integration
--*     @version 1.0
--*     @date created 03/24/2010
--*
--******************************************************************************
--/

library work;
use work.x6_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_alerts_top is
  generic (
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

    -- Reset and clock
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;

    -- alerts interface
    ref_clk              : in  std_logic;
    alert_data           : in  width_32_alrt_array;
    alert                : in  std_logic_vector(num_alerts-1 downto 0);
    trigger              : in  std_logic;
    alert_sw_data        : out std_logic_vector(31 downto 0);
    alert_sw_stb         : out std_logic;
    timestamp_rollover   : out std_logic;
    alert_fifo_wrd_cnt   : out std_logic_vector(8 downto 0);
    alert_fifo_aempty    : out std_logic;
    alert_fifo_empty     : out std_logic;
    alert_fifo_rd        : in  std_logic;
    alert_dout_vld       : out std_logic;
    alert_dout           : out std_logic_vector(127 downto 0)
  );
end ii_alerts_top;

architecture arch of ii_alerts_top is

  component ii_alerts_regs
    generic (
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
      alert_enable         : out std_logic_vector(num_alerts-1 downto 0);
      timestamp_run        : out std_logic;
      alert_fifo_rst       : out std_logic;
      sw_data              : out std_logic_vector(31 downto 0);
      sw_stb               : out std_logic
    );
  end component;

  component ii_alerts
    port (
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;
      ref_clk              : in  std_logic;
      alert_data           : in  width_32_alrt_array;
      alert                : in  std_logic_vector(num_alerts-1 downto 0);
      alert_enable         : in  std_logic_vector(num_alerts-1 downto 0);
      trigger              : in  std_logic;
      timestamp_run        : in  std_logic;
      timestamp_rollover   : out std_logic;
      alert_fifo_rst       : in  std_logic;
      alert_fifo_wrd_cnt   : out std_logic_vector(8 downto 0);
      alert_fifo_aempty    : out std_logic;
      alert_fifo_empty     : out std_logic;
      alert_fifo_rd        : in  std_logic;
      alert_dout_vld       : out std_logic;
      alert_dout           : out std_logic_vector(127 downto 0)
    );
  end component;

  signal alert_enable         : std_logic_vector(num_alerts-1 downto 0);
  signal timestamp_run        : std_logic;
  signal alert_fifo_rst       : std_logic;

  begin

  inst_alerts_regs : ii_alerts_regs
    generic map (
      offset               => offset
    )
    port map (
      wb_rst_i             => wb_rst_i,
      wb_clk_i             => wb_clk_i,
      wb_adr_i             => wb_adr_i,
      wb_dat_i             => wb_dat_i,
      wb_we_i              => wb_we_i,
      wb_stb_i             => wb_stb_i,
      wb_ack_o             => wb_ack_o,
      wb_dat_o             => wb_dat_o,
      alert_enable         => alert_enable,
      timestamp_run        => timestamp_run,
      alert_fifo_rst       => alert_fifo_rst,
      sw_data              => alert_sw_data,
      sw_stb               => alert_sw_stb
    );

  inst_alerts : ii_alerts
    port map (
      srst                 => srst,
      sys_clk              => sys_clk,
      ref_clk              => ref_clk,
      alert_data           => alert_data,
      alert                => alert,
      alert_enable         => alert_enable,
      trigger              => trigger,
      timestamp_run        => timestamp_run,
      timestamp_rollover   => timestamp_rollover,
      alert_fifo_rst       => alert_fifo_rst,
      alert_fifo_wrd_cnt   => alert_fifo_wrd_cnt,
      alert_fifo_aempty    => alert_fifo_aempty,
      alert_fifo_empty     => alert_fifo_empty,
      alert_fifo_rd        => alert_fifo_rd,
      alert_dout_vld       => alert_dout_vld,
      alert_dout           => alert_dout
    );

end arch;

