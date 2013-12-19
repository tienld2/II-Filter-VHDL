-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_lm96163_intf
--*
--* @li Target Device: generic
--* @li Tool versions: any
--*
--*     @short LM96163 interface
--*
--* Description:
--*
--*   This component initializes the critical temperature setpoint and polls
--*   the LM96163 temperature read register. It also provides an interface to
--*   the LM96163 registers.
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date Created 04/01/10
--*
--******************************************************************************
--/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_lm96163_intf is
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
end ii_lm96163_intf;

architecture arch of ii_lm96163_intf is

  component ii_lm96163_intf_phy
    generic (
      address              : std_logic_vector(6 downto 0) := "1001100"
    );
    port (
      -- system interface
      rst                  : in    std_logic;
      clk                  : in    std_logic;

      -- user interface
      command_wren         : in    std_logic;
      command              : in    std_logic_vector(7 downto 0);
      data_wren            : in    std_logic;
      wdata                : in    std_logic_vector(7 downto 0);
      data_rden            : in    std_logic;
      rdata                : out   std_logic_vector(7 downto 0);
      rdata_vld            : out   std_logic;
      busy                 : out   std_logic;
      fault                : out   std_logic;

      -- LM96163 interface
      smb_clk              : out   std_logic;
      smb_data             : inout std_logic
    );
  end component;

  constant LM_POR_STS_REG     : std_logic_vector(7 downto 0) := x"33";
  constant LM_ALRT_STS_REG    : std_logic_vector(7 downto 0) := x"02";
  constant LM_CFG_REG         : std_logic_vector(7 downto 0) := x"03";
  constant LM_CFG_VAL         : std_logic_vector(7 downto 0) := x"82";
  constant LM_RDTFCM_REG      : std_logic_vector(7 downto 0) := x"BF";
  constant LM_RDTFCM_VAL      : std_logic_vector(7 downto 0) := x"06";
  constant LM_RCS_REG         : std_logic_vector(7 downto 0) := x"19";
  constant LM_RT_REG          : std_logic_vector(7 downto 0) := x"01";

  signal LM_RCS_VAL           : std_logic_vector(7 downto 0) := x"55";

  signal cmd_wren_latched     : std_logic;

  type   temp_sm_t is (idle, rd_por_sts, rd_alrt_sts, wr_cfg, wr_rdtfcm,
                       wr_rcs, chk_cmd_wren, rd_rt, stop);
  signal temp_sm              : temp_sm_t;
  signal temp_sm_d            : temp_sm_t;
  signal reg_wr               : std_logic;
  signal reg_rd               : std_logic;
  type   phy_intf_sm_t is (idle, read_command, wait_done);
  signal phy_intf_sm          : phy_intf_sm_t;
  signal phy_rdy              : std_logic;
  signal phy_rdy_d            : std_logic;
  signal phy_rdy_re           : std_logic;
  signal command_wren         : std_logic;
  signal command              : std_logic_vector(7 downto 0);
  signal data_wren            : std_logic;
  signal wdata                : std_logic_vector(7 downto 0);
  signal data_rden            : std_logic;
  signal rdata                : std_logic_vector(7 downto 0);
  signal rdata_vld            : std_logic;
  signal busy                 : std_logic;
  signal busy_d               : std_logic;
  signal busy_fe              : std_logic;
  signal fault                : std_logic;

begin

  -- Set the critical temperature value based on crit_temp_sel
  LM_RCS_VAL <= x"55" when (crit_temp_sel = '0') else x"64";

  -- latch cmd_wren till serviced
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1' or (temp_sm = chk_cmd_wren and phy_rdy_re = '1') or
          temp_sm = stop) then
        cmd_wren_latched <= '0';
      elsif (cmd_wren = '1') then
        cmd_wren_latched <= '1';
      end if;
      if (rst = '1' or temp_sm = stop) then
        cmd_rdy <= '0';
      else
        cmd_rdy <= not cmd_wren_latched;
      end if;
    end if;
  end process;

  -- Deassert cmd_rdata_vld when a new read command is detected
  -- and set it when the read is done
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1' or (cmd_wren = '1' and cmd_rd_wrn = '1')) then
        cmd_rdata_vld <= '0';
      elsif (temp_sm_d = chk_cmd_wren and phy_rdy_re = '1' and fault = '0' and
             rdata_vld = '1' and cmd_rd_wrn = '1') then
        cmd_rdata_vld <= '1';
        cmd_rdata     <= rdata;
      end if;
    end if;
  end process;

--------------------------------------------------------------------------------
-- Command generator logic
--------------------------------------------------------------------------------
  -- main state machine
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        temp_sm       <= idle;
        temp_sm_d     <= idle;
        reg_wr        <= '0';
        reg_rd        <= '0';
        temp_valid    <= '0';
        sensor_in_por <= '0';
        sensor_fault  <= '0';
      else
        temp_sm_d  <= temp_sm;
        reg_wr     <= '0';
        reg_rd     <= '0';
        temp_valid <= '0';
        case temp_sm is
          ----------------------------------------------------------------------
          when idle =>
            if (temp_mon_en = '1') then
              temp_sm <= rd_por_sts;
            elsif (cmd_wren_latched = '1') then
              temp_sm <= chk_cmd_wren;
            end if;
          ----------------------------------------------------------------------
          -- Power On Reset Status register
          when rd_por_sts =>
            if (temp_sm_d /= rd_por_sts) then
              reg_rd  <= '1';
              command <= LM_POR_STS_REG;
            elsif (phy_rdy_re = '1') then
              if (rdata_vld = '1' and fault = '0') then
                if (rdata(7)= '1') then  -- power on reset cycle in progress
                  temp_sm       <= idle;
                  sensor_in_por <= '1';
                else
                  temp_sm       <= rd_alrt_sts;
                  sensor_in_por <= '0';
                end if;
              else
                temp_sm <= stop;
              end if;
            end if;
          ----------------------------------------------------------------------
          -- Alert Status register (check RDFA)
          when rd_alrt_sts =>
            if (temp_sm_d /= rd_alrt_sts) then
              reg_rd  <= '1';
              command <= LM_ALRT_STS_REG;
            elsif (phy_rdy_re = '1') then
              if (rdata_vld = '1' and fault = '0' and rdata(2)= '0') then
                temp_sm      <= wr_cfg;
                sensor_fault <= '0';
              else
                temp_sm      <= stop;
                sensor_fault <= '1';
              end if;
            end if;
          ----------------------------------------------------------------------
          -- Write configuration register (Set TCRITOV & ALTMSK)
          when wr_cfg =>
            if (temp_sm_d /= wr_cfg) then
              reg_wr  <= '1';
              command <= LM_CFG_REG;
              wdata   <= LM_CFG_VAL;
            elsif (phy_rdy_re = '1') then
              if (fault = '0') then
                temp_sm <= wr_rdtfcm;
              else
                temp_sm <= stop;
              end if;
            end if;
          ----------------------------------------------------------------------
          -- Write remote diode temperature filter and comparator mode register
          -- (Set RDTF to "11")
          when wr_rdtfcm =>
            if (temp_sm_d /= wr_rdtfcm) then
              reg_wr  <= '1';
              command <= LM_RDTFCM_REG;
              wdata   <= LM_RDTFCM_VAL;
            elsif (phy_rdy_re = '1') then
              if (fault = '0') then
                temp_sm <= wr_rcs;
              else
                temp_sm <= stop;
              end if;
            end if;
          ----------------------------------------------------------------------
          -- Write remote diode t_crit setpoint register
          when wr_rcs =>
            if (temp_sm_d /= wr_rcs) then
              reg_wr  <= '1';
              command <= LM_RCS_REG;
              wdata   <= LM_RCS_VAL;
            elsif (phy_rdy_re = '1') then
              if (fault = '0') then
                temp_sm <= chk_cmd_wren;
              else
                temp_sm <= stop;
              end if;
            end if;
          ----------------------------------------------------------------------
          -- Check for cmd_wren_latched
          when chk_cmd_wren =>
            if (cmd_wren_latched = '0') then
              temp_sm <= rd_rt;
            elsif (temp_sm_d /= chk_cmd_wren) then
              reg_wr  <= not cmd_rd_wrn;
              reg_rd  <= cmd_rd_wrn;
              command <= cmd_addr;
              wdata   <= cmd_wdata;
            elsif (phy_rdy_re = '1') then
              if (fault = '0') then
                if (temp_mon_en = '0') then
                  temp_sm <= idle;
                else
                  temp_sm <= rd_rt;
                end if;
              else
                temp_sm <= stop;
              end if;
            end if;
          ----------------------------------------------------------------------
          -- Signed remote diode temperature
          when rd_rt =>
            if (temp_sm_d /= rd_rt) then
              reg_rd  <= '1';
              command <= LM_RT_REG;
            elsif (phy_rdy_re = '1') then
              if (rdata_vld = '1' and fault = '0') then
                if (temp_mon_en = '0') then
                  temp_sm <= idle;
                else
                  temp_sm <= chk_cmd_wren;
                end if;
                temp_valid  <= '1';
                temperature <= rdata;
              else
                temp_sm <= stop;
              end if;
            end if;
          ----------------------------------------------------------------------
          when stop =>
            if (temp_mon_en = '0') then
              temp_sm <= idle;
            else
              temp_sm <= stop;
            end if;
          ----------------------------------------------------------------------
          when others =>
            temp_sm <= idle;
        end case;
      end if;
    end if;
  end process;

--------------------------------------------------------------------------------
-- PHY interface logic
--------------------------------------------------------------------------------
  -- PHY interface state machine
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        phy_intf_sm  <= idle;
        phy_rdy      <= '1';
        command_wren <= '0';
        data_wren    <= '0';
        data_rden    <= '0';
      else
        command_wren <= '0';
        data_wren    <= '0';
        data_rden    <= '0';
        case phy_intf_sm is
          ----------------------------------------------------------------------
          when idle =>
            if (reg_wr = '1') then
              phy_intf_sm <= wait_done;
              phy_rdy     <= '0';
              data_wren   <= '1';
            elsif (reg_rd = '1') then
              phy_intf_sm  <= read_command;
              phy_rdy      <= '0';
              command_wren <= '1';
            else
              phy_intf_sm <= idle;
              phy_rdy     <= '1';
            end if;
          ----------------------------------------------------------------------
          when read_command =>
            if (busy_fe = '1') then
              phy_intf_sm <= wait_done;
              data_rden   <= '1';
            else
              phy_intf_sm <= read_command;
            end if;
          ----------------------------------------------------------------------
          when wait_done =>
            if (busy_fe = '1') then
              phy_intf_sm <= idle;
              phy_rdy     <= '1';
            else
              phy_intf_sm <= wait_done;
            end if;
          ----------------------------------------------------------------------
          when others =>
            phy_intf_sm <= idle;
        end case;
      end if;
    end if;
  end process;

  phy_inst : ii_lm96163_intf_phy
  generic map (
    address         => "1001100"
  )
  port map (
    -- system interface
    rst             => rst,
    clk             => clk,

    -- user interface
    command_wren    => command_wren,
    command         => command,
    data_wren       => data_wren,
    wdata           => wdata,
    data_rden       => data_rden,
    rdata           => rdata,
    rdata_vld       => rdata_vld,
    busy            => busy,
    fault           => fault,

    -- LM96163 interface
    smb_clk         => smb_clk,
    smb_data        => smb_data
  );

  comm_fault <= fault;

  -- delay busy to find a falling edge on it
  process (clk)
  begin
    if (rising_edge(clk)) then
      phy_rdy_d <= phy_rdy;
      busy_d    <= busy;
    end if;
  end process;

  phy_rdy_re <= phy_rdy and not phy_rdy_d;
  busy_fe    <= busy_d and not busy;

end arch;
