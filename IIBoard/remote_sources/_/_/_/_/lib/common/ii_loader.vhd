-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.

--************************************************************************
--* Design Name:    ii_loader
--*
--*
--*     @author Innovative Integration
--*     @version 1.1
--*     @date Created 05/18/10
--*
--*
--************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ii_loader is
  port (
    srst                 : in    std_logic;
    sys_clk              : in    std_logic;

    -- FPA interface pins (Flash Programming & Authentication)
    loader_clk           : out   std_logic;
    loader_cs            : out   std_logic;
    loader_dio           : out   std_logic;

    -- Loader data bus
    loader_bus           : inout std_logic_vector(15 downto 0);

    -- S/W accessible registers
    addr                 : in    std_logic_vector(26 downto 0);
    addr_wr              : in    std_logic;
    data_o               : in    std_logic_vector(31 downto 0);
    data_i               : out   std_logic_vector(31 downto 0);
    data_wr              : in    std_logic;
    cmd                  : in    std_logic_vector(6 downto 0);
    cmd_wr               : in    std_logic;
    status               : out   std_logic_vector(15 downto 0)
  );
end ii_loader;

architecture arch of ii_loader is

  type   state_t is (idle, read_cmd, write_cmd, finish);
  signal state                : state_t;
  type   state_s is (det_a, det_b, det_c, sel_img);
  signal seq_det              : state_s;
  signal clk_cnt              : std_logic_vector(15 downto 0);
  signal sht_cnt              : unsigned(3 downto 0) := (others => '0');
  signal busy_cnt             : unsigned(6 downto 0) := (others => '0');
  signal clk_en               : std_logic;
  signal ld_clk               : std_logic;
  signal cs                   : std_logic;
  signal cmd_wr_d             : std_logic;
  signal cmd_rd_d             : std_logic;
  signal bus_l                : std_logic_vector(31 downto 0);
  signal cmd_reg              : std_logic_vector(3 downto 0);
  signal loader_bus_o         : std_logic_vector(15 downto 0);
  signal loader_bus_i         : std_logic_vector(15 downto 0);
  signal stat_l               : std_logic_vector(15 downto 0);
  signal read_vld             : std_logic;
  signal cmd_busy             : std_logic;
  signal ld_dio               : std_logic_vector(3 downto 0);
  signal rstrt_en             : std_logic;

  -- Serial commands
  constant LOAD_ADDR          : std_logic_vector(3 downto 0) := X"0";
  constant LOAD_DATA          : std_logic_vector(3 downto 0) := X"1";
  constant FLASH_READ         : std_logic_vector(3 downto 0) := X"2";
  constant FLASH_WRITE        : std_logic_vector(3 downto 0) := X"3";
  constant INC_ADDR           : std_logic_vector(3 downto 0) := X"5";
  constant RESTART            : std_logic_vector(3 downto 0) := X"7";
  constant FLASH_STATUS       : std_logic_vector(3 downto 0) := X"C";
  constant POWER_STATUS       : std_logic_vector(3 downto 0) := X"8";

  -- status register bit definitions
  constant ST_BUSY            : integer := 0;
  constant ST_RD_VLD          : integer := 1;
  constant ST_FL_RDY          : integer := 2;
  constant ST_OVRTEMP         : integer := 3;
  constant ST_UNUSED4         : integer := 4;
  constant ST_UNUSED5         : integer := 5;
  constant ST_UNUSED6         : integer := 6;
  constant ST_IMG_JMPR        : integer := 7;
  constant ST_FL_LO           : integer := 8;
  constant ST_FL_HI           : integer := 11;
  constant ST_VER_LO          : integer := 12;
  constant ST_VER_HI          : integer := 15;

begin

  -- Generate divided clock
  process(sys_clk)
  begin
    if rising_edge(sys_clk) then
      if (srst = '1') then
        clk_cnt <= (0 => '1', others => '0');
        clk_en  <= '0';
      else
        clk_en  <= clk_cnt(clk_cnt'high);
        clk_cnt <= clk_cnt(clk_cnt'high-1 downto 0) & clk_cnt(clk_cnt'high);
      end if;
    end if;
  end process;

  loader_cs <= cs;

  -- Generate loader_clk with cs as enable
  process(sys_clk)
  begin
    if rising_edge(sys_clk) then
      if (srst = '1') then
        ld_clk <= '0';
      elsif (state /= idle and state /= finish) then
        if (clk_en = '1') then
          ld_clk <= not ld_clk;
        end if;
      else
        ld_clk <= '0';
      end if;
    end if;
  end process;

  loader_clk <= ld_clk;
  loader_dio <= ld_dio(ld_dio'high);

  -- Latch the value of command on cmd strobe
  -- Decode one-hot command (priority encoded) to cmd_reg
  -- There's two types of commands:
  -- commands that send data to the CPLD      -> writes (cmd_wr_d)
  -- commands that expect data back from CPLD -> reads  (cmd_rd_d)
  process(sys_clk)
  begin
    if rising_edge(sys_clk) then
      if (cmd_wr = '1') then
        bus_l <= (others => '0');
        if (cmd(0) = '1') then
          cmd_reg  <= FLASH_WRITE;
          cmd_wr_d <= '1';
        elsif (cmd(1) = '1') then
          cmd_reg  <= FLASH_READ;
          cmd_wr_d <= '1';
        elsif (cmd(3) = '1') then
          cmd_reg  <= INC_ADDR;
          cmd_wr_d <= '1';
        elsif (cmd(4) = '1') then
          cmd_reg  <= FLASH_STATUS;
          cmd_rd_d <= '1';
        elsif (cmd(5) = '1' and rstrt_en = '1') then
          cmd_reg  <= RESTART;
          cmd_wr_d <= '1';
        elsif (cmd(6) = '1') then
          cmd_reg  <= POWER_STATUS;
          cmd_rd_d <= '1';
        end if;
      elsif (data_wr = '1') then
        bus_l    <= data_o;
        cmd_reg  <= LOAD_DATA;
        cmd_wr_d <= '1';
      elsif (addr_wr = '1') then
        bus_l    <= "00000" & addr;
        cmd_reg  <= LOAD_ADDR;
        cmd_wr_d <= '1';
      elsif (clk_en = '1') then
        cmd_wr_d <= '0';
        cmd_rd_d <= '0';
      end if;
    end if;
  end process;

  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        cmd_busy <= '0';
      else
        cmd_busy <= cs;
      end if;
    end if;
  end process;

  -- Map stat_l from CPLD into status register, inserting locally generated
  -- cmd_busy and read_vld
  status(ST_BUSY    ) <= cmd_busy;
  status(ST_RD_VLD  ) <= read_vld;
  status(ST_FL_RDY  ) <= stat_l(2);
  status(ST_OVRTEMP ) <= stat_l(3);
  status(ST_UNUSED4 ) <= stat_l(4);
  status(ST_UNUSED5 ) <= stat_l(5);
  status(ST_UNUSED6 ) <= stat_l(6);
  status(ST_IMG_JMPR) <= stat_l(7);
  status(ST_FL_HI downto ST_FL_LO)   <= stat_l(11 downto 8);
  status(ST_VER_HI downto ST_VER_LO) <= stat_l(15 downto 12);

  -- FSM to send/receive address, data, commands from/to CPLD
  process(sys_clk)
  begin
    if rising_edge(sys_clk) then
      if (srst = '1') then
        state   <= idle;
        stat_l  <= (others => '0');
        ld_dio  <= (others => '0');
        cs      <= '0';
        sht_cnt <= (others => '0');
      elsif clk_en = '1' then
        sht_cnt <= sht_cnt + 1;
        case (state) is
          when idle =>
            cs <= '0';
            sht_cnt <= (others => '0');
            if (cmd_wr_d = '1') then
              cs <= '1';
              state  <= write_cmd;
              ld_dio <= cmd_reg;
            elsif (cmd_rd_d = '1') then
              cs <= '1';
              state  <= read_cmd;
              ld_dio <= cmd_reg;
            end if;

          when write_cmd =>
            if (sht_cnt = 1) then
              loader_bus_o <= bus_l(15 downto 0);
            elsif (sht_cnt = 3) then
              loader_bus_o <= bus_l(31 downto 16);
            elsif (sht_cnt = 7) then
              read_vld <= '0';
              state <= finish;
            end if;
            if (sht_cnt(0) = '1') then  -- if cnt is odd, shift out
              ld_dio <= ld_dio(ld_dio'high-1 downto 0) & '0';
            end if;

          when read_cmd =>
            if (sht_cnt = 3) then
              data_i(15 downto 0)  <= loader_bus_i;
            elsif (sht_cnt = 5) then
              data_i(31 downto 16) <= loader_bus_i;
            elsif (sht_cnt = 7) then
              stat_l   <= loader_bus_i(15 downto 0);
              read_vld <= loader_bus_i(1);
              state    <= finish;
            end if;
            if (sht_cnt(0) = '1') then  -- if cnt is odd, shift out
              ld_dio <= ld_dio(ld_dio'high-1 downto 0) & '0';
            end if;

          when finish =>
            cs <= '0';
            state <= idle;

          when others =>
            state <= idle;
        end case;
      end if;
    end if;
  end process;

  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      loader_bus_i <= loader_bus;
    end if;
  end process;

  loader_bus <= loader_bus_o when (state = write_cmd) else
                (others => 'Z');

  -- Sequence detector to detect the occurrence of consecutive
  -- load address commands of x"AAAAAAAA", x"BBBBBBBB" and
  -- x"CCCCCCCC" followed by a an image select address after which
  -- rstrt_en is asserted.
  -- If a restart command is received while rstrt_en is asserted,
  -- it will be executed, triggering an FPGA reconfiguration.
  -- If rstrt_en is not asserted, the restart command will be ignored.
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (addr_wr = '1' or data_wr = '1' or cmd_wr = '1') then
        case (seq_det) is
          when det_a =>
            rstrt_en <= '0';
            if (addr_wr = '1' and addr = "010" & x"AAAAAA") then
              seq_det <= det_b;
            else
              seq_det <= det_a;
            end if;

          when det_b =>
            rstrt_en <= '0';
            if (addr_wr = '1' and addr = "011" & x"BBBBBB") then
              seq_det <= det_c;
            else
              seq_det <= det_a;
            end if;

          when det_c =>
            rstrt_en <= '0';
            if (addr_wr = '1' and addr = "100" & x"CCCCCC") then
              seq_det <= sel_img;
            else
              seq_det <= det_a;
            end if;

          when sel_img =>
            if (addr_wr = '1') then
              rstrt_en <= '1';
            else
              rstrt_en <= '0';
            end if;
            seq_det  <= det_a;

          when others =>
            rstrt_en <='0';
            seq_det  <= det_a;
        end case;
      end if;
    end if;
  end process;

end arch;
