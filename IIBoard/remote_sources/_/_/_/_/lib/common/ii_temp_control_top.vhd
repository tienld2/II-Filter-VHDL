-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_temp_control_top
--*
--* @li Target Device: generic
--* @li Tool versions: any
--*
--*     @short top module for the temperature monitor interface
--*
--* Description:
--*
--*   This component is the top level of the interface to the temperature
--*   monitor. It instantiates the LM96163 interface component, temperature
--*   alert generator, and a register file.
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
--*   @port srst             : input, synchronous active high reset
--*   @port clk              : input, system clock
--*   @port crit_temp_sel    : input, critical temperature selector (0=low, 1=high)
--*   @port temp_warning     :output, temperature above warning threshold
--*   @port fan_en           :output, fan enable
--*   @port smb_clk          :output, LM96163 interface SMB clock
--*   @port smb_data         : inout, LM96163 interface SMB data
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 03/23/2010
--*
--******************************************************************************
--/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_temp_control_top is
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

    -- system interface
    srst                 : in  std_logic;
    clk                  : in  std_logic;

    -- temp_control signals
    crit_temp_sel        : in  std_logic;
    temp_warning         : out std_logic;
    fan_en               : out std_logic;

    -- LM96163 interface
    smb_clk              : out std_logic;
    smb_data             : inout std_logic
  );
end ii_temp_control_top;

architecture arch of ii_temp_control_top is

  component ii_lm96163_intf
    port (
      -- system interface
      rst                  : in    std_logic;
      clk                  : in    std_logic;

      -- user interface
      crit_temp_sel        : in    std_logic;
      temp_mon_en          : in    std_logic;
      comm_fault           : out   std_logic;
      sensor_in_por        : out   std_logic;
      sensor_fault         : out   std_logic;
      temp_valid           : out   std_logic;
      temperature          : out   std_logic_vector(7 downto 0);

      -- WB interface
      cmd_rdy              : out   std_logic;
      cmd_wren             : in    std_logic;
      cmd_rd_wrn           : in    std_logic;
      cmd_addr             : in    std_logic_vector(7 downto 0);
      cmd_wdata            : in    std_logic_vector(7 downto 0);
      cmd_rdata_vld        : out   std_logic;
      cmd_rdata            : out   std_logic_vector(7 downto 0);

      -- LM96163 interface
      smb_clk              : out   std_logic;
      smb_data             : inout std_logic
    );
  end component;

  component ii_temp_control_regs
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
      temp_mon_en          : out std_logic;
      comm_fault           : in  std_logic;
      sensor_in_por        : in  std_logic;
      sensor_fault         : in  std_logic;
      temperature          : in  std_logic_vector(7 downto 0);
      fan_thresh           : out std_logic_vector(7 downto 0);
      warning_thresh       : out std_logic_vector(7 downto 0);
      cmd_wren             : out std_logic;
      cmd_addr             : out std_logic_vector(7 downto 0);
      cmd_wdata            : out std_logic_vector(7 downto 0);
      cmd_rd_wrn           : out std_logic;
      cmd_rdy              : in  std_logic;
      cmd_rdata_vld        : in  std_logic;
      cmd_rdata            : in  std_logic_vector(7 downto 0)
    );
  end component;

  component ii_temp_control
    port (
      srst                 : in  std_logic;
      clk                  : in  std_logic;
      temp_valid           : in  std_logic;
      temperature          : in  std_logic_vector(7 downto 0);
      warning_thresh       : in  std_logic_vector(7 downto 0);
      warning              : out std_logic;
      fan_thresh           : in  std_logic_vector(7 downto 0);
      fan_en               : out std_logic
    );
  end component;

  signal crit_temp_sel_d      : std_logic;
  signal temp_mon_en          : std_logic;
  signal comm_fault           : std_logic;
  signal sensor_in_por        : std_logic;
  signal sensor_fault         : std_logic;
  signal temp_valid           : std_logic;
  signal temperature          : std_logic_vector(7 downto 0);
  signal cmd_rdy              : std_logic;
  signal cmd_wren             : std_logic;
  signal cmd_rd_wrn           : std_logic;
  signal cmd_addr             : std_logic_vector(7 downto 0);
  signal cmd_wdata            : std_logic_vector(7 downto 0);
  signal cmd_rdata_vld        : std_logic;
  signal cmd_rdata            : std_logic_vector(7 downto 0);
  signal fan_thresh           : std_logic_vector(7 downto 0);
  signal warning_thresh       : std_logic_vector(7 downto 0);

begin

  -- Register to ease timing closure
  process (clk)
  begin
    if (rising_edge(clk)) then
      crit_temp_sel_d <= crit_temp_sel;
    end if;
  end process;

  inst_lm96163_intf : ii_lm96163_intf
  port map (
    -- system interface
    rst                  => srst,
    clk                  => clk,

    -- user interface
    crit_temp_sel        => crit_temp_sel_d,
    temp_mon_en          => temp_mon_en,
    comm_fault           => comm_fault,
    sensor_in_por        => sensor_in_por,
    sensor_fault         => sensor_fault,
    temp_valid           => temp_valid,
    temperature          => temperature,

    -- WB interface
    cmd_rdy              => cmd_rdy,
    cmd_wren             => cmd_wren,
    cmd_rd_wrn           => cmd_rd_wrn,
    cmd_addr             => cmd_addr,
    cmd_wdata            => cmd_wdata,
    cmd_rdata_vld        => cmd_rdata_vld,
    cmd_rdata            => cmd_rdata,

    -- LM96163 interface
    smb_clk              => smb_clk,
    smb_data             => smb_data
  );

  inst_temp_control_regs : ii_temp_control_regs
  generic map (
    addr_bits            => addr_bits,
    offset               => offset
  )
  port map (
    -- Wishbone interface signals
    wb_rst_i             => wb_rst_i,
    wb_clk_i             => wb_clk_i,
    wb_adr_i             => wb_adr_i,
    wb_dat_i             => wb_dat_i,
    wb_we_i              => wb_we_i,
    wb_stb_i             => wb_stb_i,
    wb_ack_o             => wb_ack_o,
    wb_dat_o             => wb_dat_o,

    -- User registers
    temp_mon_en          => temp_mon_en,
    comm_fault           => comm_fault,
    sensor_in_por        => sensor_in_por,
    sensor_fault         => sensor_fault,
    temperature          => temperature,
    fan_thresh           => fan_thresh,
    warning_thresh       => warning_thresh,
    cmd_wren             => cmd_wren,
    cmd_addr             => cmd_addr,
    cmd_wdata            => cmd_wdata,
    cmd_rd_wrn           => cmd_rd_wrn,
    cmd_rdy              => cmd_rdy,
    cmd_rdata_vld        => cmd_rdata_vld,
    cmd_rdata            => cmd_rdata
  );

  inst_temp_control : ii_temp_control
  port map (
    srst                 => srst,
    clk                  => clk,
    temp_valid           => temp_valid,
    temperature          => temperature,
    warning_thresh       => warning_thresh,
    warning              => temp_warning,
    fan_thresh           => fan_thresh,
    fan_en               => fan_en
  );

end arch;

