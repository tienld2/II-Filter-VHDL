-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_aurora_cmd
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.1
--*
--*     @short Aurora Command Sub-channel Interface
--*
--* Description:
--*
--*   This component interfaces user registers to Aurora's command sub-channel
--*
--*   @port srst              : input, synchronous active high reset
--*   @port sys_clk           : input, system clock
--*   @port usr_cmd_wr_strb   : input, write command strobe
--*   @port usr_cmd_wr_data   : input, write command data
--*   @port usr_cmd_wr_addr   : input, command destination address
--*   @port usr_cmd_wr_rdn    : input, (1=write, 0=read) command
--*   @port cmd_ch_rdy        :output, command channel ready
--*   @port usr_cmd_rd_data   :output, read data
--*   @port usr_cmd_rd_addr   :output, read address
--*   @port usr_cmd_rd_vld    :output, read data valid
--*   @port channel_up        : input, Aurora channel initialization is complete
--*   @port cmd_tx_req        :output, request to send a command
--*   @port cmd_tx_data       :output, transmit command
--*   @port cmd_tx_ack        : input, transmit command has been sent
--*   @port cmd_rx_valid      : input, received command is valid
--*   @port cmd_rx_data       : input, received command
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date Created 06/09/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;

entity ii_aurora_cmd is
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
end ii_aurora_cmd;


architecture arch of ii_aurora_cmd is

  signal cmd_wr_ip            : std_logic;
  signal curr_rd_vld          : std_logic;
  signal nxt_rd_vld           : std_logic;

begin

  cmd_tx_data <= (usr_cmd_wr_rdn & '0' & usr_cmd_wr_addr & usr_cmd_wr_data);

  -- Set this flag whenever writing a command is in progress
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or channel_up /= '1' or cmd_tx_ack = '1') then
        cmd_wr_ip <= '0';
      elsif (usr_cmd_wr_strb = '1') then
        cmd_wr_ip <= '1';
      end if;
    end if;
  end process;

  cmd_tx_req <= cmd_wr_ip;

  -- Set the command channel ready signal whenever out of reset or at the
  -- end of a transaction. Deassert with a write command
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or channel_up /= '1' or usr_cmd_wr_strb = '1') then
        cmd_ch_rdy <= '0';
      elsif (cmd_wr_ip = '0') then
        cmd_ch_rdy <= '1';
      end if;
    end if;
  end process;

  usr_cmd_rd_data <= cmd_rx_data(23 downto 0);
  usr_cmd_rd_addr <= cmd_rx_data(29 downto 24);

  -- Deassert whenever in reset or a new read command is started.
  -- Set when valid data is received from the aurora interface
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or channel_up /= '1' or
          (usr_cmd_wr_strb = '1' and usr_cmd_wr_rdn = '0')) then
        curr_rd_vld <= '0';
        nxt_rd_vld  <= '0';
      elsif (cmd_rx_valid = '1') then
        curr_rd_vld <= '0';
        nxt_rd_vld  <= '1';
      else
        curr_rd_vld <= nxt_rd_vld;
      end if;
    end if;
  end process;

  usr_cmd_rd_vld <= curr_rd_vld;

end arch;
