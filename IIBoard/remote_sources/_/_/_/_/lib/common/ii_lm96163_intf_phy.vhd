-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_lm96163_intf_phy
--*
--* @li Target Device: generic
--* @li Tool versions: any
--*
--*     @short LM96163 interface physical layer
--*
--* Description:
--*
--*   This component toggles the LM96163 interface signals based on user commands.
--*
--*   Note: all the parameters are calculated and set for 333MHz input clock.
--*         Adjustment of these parameters is necessary if the clock frequency
--*         is increased.
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date Created 03/05/10
--*
--******************************************************************************
--/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ii_lm96163_intf_phy is
  generic (
    address         : std_logic_vector(6 downto 0) := "1001100"
  );
  port (
    -- system interface
    rst             : in    std_logic;
    clk             : in    std_logic;

    -- user interface
    command_wren    : in    std_logic;
    command         : in    std_logic_vector(7 downto 0);
    data_wren       : in    std_logic;
    wdata           : in    std_logic_vector(7 downto 0);
    data_rden       : in    std_logic;
    rdata           : out   std_logic_vector(7 downto 0);
    rdata_vld       : out   std_logic;
    busy            : out   std_logic;
    fault           : out   std_logic;

    -- LM96163 interface
    smb_clk         : out   std_logic;
    smb_data        : inout std_logic
  );
end ii_lm96163_intf_phy;


architecture arch of ii_lm96163_intf_phy is

  signal smb_data_o           : std_logic;
  signal smb_data_i           : std_logic;
  signal smb_data_i_d         : std_logic;
  constant clk_div_cnt_th     : unsigned(6 downto 0) := "1010010";
  signal clk_div_cnt          : unsigned(6 downto 0) := (others => '0');
  signal clk_strb             : std_logic;
  signal strb_cnt             : integer range 0 to 39;
  signal rst_strb_cnt         : std_logic;
  signal set_smb_clk          : std_logic;
  signal set_smb_data         : std_logic;
  type   state_type is (idle, start, send_address, wait_ack, send_command,
                        send_wdata, shift_rdata, send_nack, stop);
  signal state                : state_type;
  signal nxt_state            : state_type;
  signal data_sreg            : std_logic_vector(23 downto 0);
  signal cmd_wr_ip            : std_logic;
  signal data_wr_ip           : std_logic;
  signal data_rd_ip           : std_logic;
  signal oe_n                 : std_logic;
  signal shift_cnt            : integer range 0 to 8;
  signal acked                : std_logic;

begin

  -- bidirectional data to LM96163
  IOBUF_inst : IOBUF
  generic map (
    DRIVE            => 12,
    IBUF_DELAY_VALUE => "0",
    IFD_DELAY_VALUE  => "AUTO",
    IOSTANDARD       => "DEFAULT",
    SLEW             => "SLOW"
  )
  port map (
    O                => smb_data_i,
    IO               => smb_data,
    I                => smb_data_o,
    T                => oe_n
  );

  pullup_inst : PULLUP port map (O => smb_data);

  -- register the incoming data
  process (clk)
  begin
    if (rising_edge(clk)) then
      smb_data_i_d <= smb_data_i;
    end if;
  end process;

  -- generate clock strobes every ~250ns (min)
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state = idle or clk_strb = '1') then
        clk_div_cnt <= (others => '0');
      else
        clk_div_cnt <= clk_div_cnt + 1;
      end if;
      if (clk_div_cnt = clk_div_cnt_th) then
        clk_strb <= '1';
      else
        clk_strb <= '0';
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state = idle) then
        strb_cnt <= 4;
      elsif (rst_strb_cnt = '1') then
        strb_cnt <= 0;
      elsif (clk_strb = '1') then
        strb_cnt <= strb_cnt + 1;
      end if;
    end if;
  end process;

  rst_strb_cnt <= '1' when (clk_strb = '1' and strb_cnt = 39) else
                  '0';

  set_smb_clk  <= '1' when (clk_strb = '1' and strb_cnt = 19) else
                  '0';

  set_smb_data <= '1' when (clk_strb = '1' and strb_cnt = 17) else
                  '0';

  -- Generate smb_clk
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state = idle or set_smb_clk = '1') then
        smb_clk <= '1';
      elsif (rst_strb_cnt = '1') then
        smb_clk <= '0';
      end if;
    end if;
  end process;

  -- main state machine
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        state      <= idle;
        nxt_state  <= idle;
        rdata_vld  <= '0';
        busy       <= '0';
        fault      <= '0';
        smb_data_o <= '1';
        oe_n       <= '1';
        acked      <= '0';
      else
        busy       <= '1';
        case state is
          ----------------------------------------------------------------------
          when idle =>
            if (command_wren = '1' or data_wren = '1' or data_rden = '1') then
              state <= start;
              fault <= '0';
              acked <= '0';
              if (command_wren = '1') then
                data_sreg <= (address & '0' & command & x"00");
                cmd_wr_ip <= '1';
                nxt_state <= send_command;
              elsif (data_wren = '1') then
                data_sreg  <= (address & '0' & command & wdata);
                data_wr_ip <= '1';
                nxt_state  <= send_command;
              else -- means data_rden = '1'
                rdata_vld  <= '0';
                data_sreg  <= (address & '1' & x"0000");
                data_rd_ip <= '1';
                nxt_state  <= shift_rdata;
              end if;
            else
              busy       <= '0';
              cmd_wr_ip  <= '0';
              data_wr_ip <= '0';
              data_rd_ip <= '0';
              oe_n       <= '1';
            end if;
          ----------------------------------------------------------------------
          when start =>
            if (strb_cnt = 23) then
              smb_data_o <= '0';
              oe_n       <= '0';
            elsif (rst_strb_cnt = '1') then
              state     <= send_address;
              shift_cnt <= 0;
            end if;
          ----------------------------------------------------------------------
          when send_address =>
            if (set_smb_data = '1') then
              data_sreg  <= data_sreg(22 downto 0) & '0';
              smb_data_o <= data_sreg(23);
              oe_n       <= '0';
              shift_cnt  <= shift_cnt + 1;
            elsif (rst_strb_cnt = '1') then
              if (shift_cnt = 8) then
                state     <= wait_ack;
                oe_n      <= '1';
                shift_cnt <= 0;
              end if;
            end if;
          ----------------------------------------------------------------------
          when wait_ack =>
            if (set_smb_clk = '1') then
              acked <= not smb_data_i_d;
            elsif (rst_strb_cnt = '1') then
              if (acked = '1') then
                state <= nxt_state;
              else
                state <= stop;
                fault <= '1';
              end if;
            end if;
          ----------------------------------------------------------------------
          when send_command =>
            if (set_smb_data = '1') then
              data_sreg  <= data_sreg(22 downto 0) & '0';
              smb_data_o <= data_sreg(23);
              oe_n       <= '0';
              shift_cnt  <= shift_cnt + 1;
            elsif (rst_strb_cnt = '1') then
              if (shift_cnt = 8) then
                state     <= wait_ack;
                oe_n      <= '1';
                shift_cnt <= 0;
              end if;
            end if;
            if (cmd_wr_ip = '1') then
              nxt_state <= stop;
            elsif (data_wr_ip = '1') then
              nxt_state <= send_wdata;
            else -- means data_rd_ip = '1'
              nxt_state <= shift_rdata;
            end if;
          ----------------------------------------------------------------------
          when send_wdata =>
            if (set_smb_data = '1') then
              data_sreg  <= data_sreg(22 downto 0) & '0';
              smb_data_o <= data_sreg(23);
              oe_n       <= '0';
              shift_cnt  <= shift_cnt + 1;
            elsif (rst_strb_cnt = '1') then
              if (shift_cnt = 8) then
                state     <= wait_ack;
                oe_n      <= '1';
                shift_cnt <= 0;
              end if;
            end if;
            nxt_state <= stop;
          ----------------------------------------------------------------------
          when shift_rdata =>
            if (set_smb_clk = '1') then
              data_sreg <= data_sreg(22 downto 0) & smb_data_i_d;
              shift_cnt <= shift_cnt + 1;
            elsif (rst_strb_cnt = '1') then
              if (shift_cnt = 8) then
                state     <= send_nack;
                shift_cnt <= 0;
                rdata_vld <= '1';
                rdata     <= data_sreg(7 downto 0) ;
              end if;
            end if;
          ----------------------------------------------------------------------
          when send_nack =>
            if (set_smb_data = '1') then
              smb_data_o <= '1';
              oe_n       <= '0';
            elsif (rst_strb_cnt = '1') then
              state <= stop;
            end if;
          ----------------------------------------------------------------------
          when stop =>
            if (set_smb_data = '1') then
              smb_data_o <= '0';
              oe_n       <= '0';
            elsif (strb_cnt = 23) then
              smb_data_o <= '1';
              oe_n       <= '1';
              state      <= idle;
            end if;
          ----------------------------------------------------------------------
          when others =>
            state <= idle;
        end case;
      end if;
    end if;
  end process;

end arch;
