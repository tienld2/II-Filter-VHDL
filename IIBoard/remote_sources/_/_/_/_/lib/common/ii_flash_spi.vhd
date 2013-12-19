-- Copyright 2010 by Innovative Integration inc., All Rights Reserved.
--************************************************************************
--* Design name: ii_flash_spi
--*
--* @li Target device: any
--* @li Tool versions: ISE 13.3
--*
--*     @short SPI Interface for SST serial flash memory
--*
--* Description:
--*
--*   This component is the SPI interface to the SST25VF032B flash memory.
--*   It receives data, address and opcode from the software, and initiates
--*   a serial transaction to the flash.
--*   The opcode is decoded and the number of cycles for opcode, address,
--*   data and dummy cycles and whether the transaction is a read or a write
--*   are determined based on it.
--*   The serial clock is 1.95MHz based on a system clock of 250MHz. This
--*   clock could be as fast as 80MHz for all commands (except read, which is
--*   25MHz max), but in order to support all instructions up to a 400MHz
--*   system clock, it was intentionally limited. The serial clock is stopped
--*   between transactions to avoid analog noise interference.
--*   Note that the high speed read is not faster than the normal read command.
--*   All flash operations are fully supported.
--*
--*   @port srst             : input , synchronous reset
--*   @port sys_clk          : input , system clock
--*   @port spi_access_strb  : input , strobe initiating any SPI transfer
--*   @port spi_wdata        : input , data to be written to flash
--*   @port spi_addr         : input , address to be written to flash
--*   @port spi_opcode       : input , opcode to be sent with transfer
--*   @port spi_rdy          : output, SPI interface is ready
--*   @port spi_rdata_valid  : output, read data is valid
--*   @port spi_rdata        : output, read data from flash
--*   @port spi_so           : output, SPI SO pin from flash
--*   @port fl_spi_sclk      : output, serial clock to flash
--*   @port fl_spi_csb       : output, chip select to flash
--*   @port fl_spi_si        : output, serial data in to flash
--*   @port fl_spi_so        : input , serial data out from flash
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 07/13/2010
--*     @date modified 11/19/2010
--*
--************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_flash_spi is
  Port (
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;

    -- User interface
    spi_access_strb      : in  std_logic;
    spi_wdata            : in  std_logic_vector(31 downto 0);
    spi_addr             : in  std_logic_vector(23 downto 0);
    spi_opcode           : in  std_logic_vector(7 downto 0);
    spi_rdy              : out std_logic;
    spi_rdata_valid      : out std_logic;
    spi_rdata            : out std_logic_vector(31 downto 0);
    spi_so               : out std_logic;

    -- Flash SPI interface
    fl_spi_sclk          : out std_logic;
    fl_spi_csb           : out std_logic;
    fl_spi_si            : out std_logic;
    fl_spi_so            : in  std_logic
  );
end ii_flash_spi;

architecture arch of ii_flash_spi is

  signal div_cnt              : unsigned(6 downto 0);
  signal sclk_fe              : std_logic;
  signal sclk_re              : std_logic;
  signal sclk                 : std_logic;
  type   spi_sm_type is (idle, wr_opcode, wr_addr, wr_dummy, wr_data, rd_data);
  signal spi_state            : spi_sm_type;
  signal csb                  : std_logic;
  signal spi_req              : std_logic;
  signal spi_access_strb_d    : std_logic;
  signal bit_cnt              : unsigned(4 downto 0);
  signal data_bits            : unsigned(4 downto 0);
  signal spi_do_sreg          : std_logic_vector(63 downto 0);
  signal sdo                  : std_logic;
  signal spi_di_sreg          : std_logic_vector(31 downto 0);
  signal ld_strb              : std_logic_vector(2 downto 0);
  signal aai_en               : std_logic;
  signal spi_so_xdom          : std_logic;

  -- Load instructions
  constant LD_DUMMY           : std_logic_vector(2 downto 0) := "001";
  constant LD_OPCODE          : std_logic_vector(2 downto 0) := "010";
  constant LD_ADDR            : std_logic_vector(2 downto 0) := "011";
  constant LD_DATA            : std_logic_vector(2 downto 0) := "100";

  -- Opcode table
  constant OP_READ            : std_logic_vector(7 downto 0) := X"03";
  constant OP_HSREAD          : std_logic_vector(7 downto 0) := X"0B";
  constant OP_4K_ERASE        : std_logic_vector(7 downto 0) := X"20";
  constant OP_32K_ERASE       : std_logic_vector(7 downto 0) := X"52";
  constant OP_64K_ERASE       : std_logic_vector(7 downto 0) := X"D8";
  constant OP_CHIP_ERASE      : std_logic_vector(7 downto 0) := X"60";
  constant OP_CHIP_ERASE2     : std_logic_vector(7 downto 0) := X"C7";
  constant OP_BYTE_PROG       : std_logic_vector(7 downto 0) := X"02";
  constant OP_AAI_PROG        : std_logic_vector(7 downto 0) := X"AD";
  constant OP_RDSR            : std_logic_vector(7 downto 0) := X"05";
  constant OP_EWSR            : std_logic_vector(7 downto 0) := X"50";
  constant OP_WRSR            : std_logic_vector(7 downto 0) := X"01";
  constant OP_WREN            : std_logic_vector(7 downto 0) := X"06";
  constant OP_WRDI            : std_logic_vector(7 downto 0) := X"04";
  constant OP_RDID            : std_logic_vector(7 downto 0) := X"90";
  constant OP_RDID2           : std_logic_vector(7 downto 0) := X"AB";
  constant OP_JEDEC_ID        : std_logic_vector(7 downto 0) := X"9F";
  constant OP_EBSY            : std_logic_vector(7 downto 0) := X"70";
  constant OP_DBSY            : std_logic_vector(7 downto 0) := X"80";

  signal   op_decode          : std_logic_vector(4 downto 0);
  alias    op_adcy            : std_logic is op_decode(4); --address cycles
  alias    op_dmcy            : std_logic is op_decode(3); --dummy cycles
  alias    op_dacy            : std_logic_vector(1 downto 0) is op_decode(2 downto 1); --data cycles, ie. 0, 1 or 4 bytes.
  alias    op_rd_wrn          : std_logic is op_decode(0); --read(1) or write(0)

begin

  -- Decode received opcode into number of address, dummy and data cycles.
  -- ie. one cycle is 8 serial clock periods
  -- Also extract command type, ie. read (0) or write (1) from opcode.
  -- op_decode is then used thru aliases: op_adcy, op_dmcy, op_dacy & op_rd_wrn
  -- op_dacy may be 00, 01, 10 or 11, indicating 0, 1, 2 or 4 data cycles resp.
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (spi_access_strb = '1') then
        case spi_opcode is
          when OP_READ                      => op_decode <= "10111";
          when OP_HSREAD                    => op_decode <= "11111";
          when OP_4K_ERASE                  => op_decode <= "10000";
          when OP_32K_ERASE                 => op_decode <= "10000";
          when OP_64K_ERASE                 => op_decode <= "10000";
          when OP_CHIP_ERASE|OP_CHIP_ERASE2 => op_decode <= "00000";
          when OP_BYTE_PROG                 => op_decode <= "10010";
          when OP_AAI_PROG                  => op_decode <= "10100";
          when OP_RDSR                      => op_decode <= "00011";
          when OP_EWSR                      => op_decode <= "00000";
          when OP_WRSR                      => op_decode <= "00010";
          when OP_WREN                      => op_decode <= "00000";
          when OP_WRDI                      => op_decode <= "00000";
          when OP_RDID|OP_RDID2             => op_decode <= "10111";
          when OP_JEDEC_ID                  => op_decode <= "00111";
          when OP_EBSY                      => op_decode <= "00000";
          when OP_DBSY                      => op_decode <= "00000";
          when others                       => op_decode <= "00000";
        end case;
      end if;
    end if;
  end process;

-----------------------------------------------------------------------------
-- SPI interface logic
-----------------------------------------------------------------------------
  -- Clock divider
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        div_cnt <= (others => '0');
      else
        div_cnt <= div_cnt + 1;
      end if;
    end if;
  end process;

  -- Enable on each clock cycle
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      sclk_fe <= '0';
      sclk_re <= '0';             -- to sample reads on negedge of clock
      if (div_cnt = "1111111") then
        sclk    <= '0';
        sclk_fe <= '1';
      elsif (div_cnt = "0111111") then
        sclk    <= '1';
        sclk_re <= '1';
      end if;
    end if;
  end process;

  -- Keep track of bits in each field of serial transfer
  -- ie. opcode is 8 bits, address is 24 bits,
  -- data varies between 8, 16 or 32 bits.
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or spi_state = idle or ld_strb /= "000") then
        bit_cnt <= (others => '0');
      elsif (sclk_fe = '1') then
        bit_cnt <= bit_cnt + 1;
      end if;
    end if;
  end process;

  -- Extend spi_wr_strb into a wider pulse that can be seen by
  -- the state machine
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        spi_req <= '0';
      elsif (spi_access_strb = '1') then
        spi_req <= '1';
      elsif (sclk_fe = '1') then
        spi_req <= '0';
      end if;
    end if;
  end process;

  -- SPI interface is ready to accept another command
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        spi_rdy <= '0';
      elsif (spi_req = '1') then
        spi_rdy <= '0';
      elsif (spi_state = idle) then
        spi_rdy <= '1';
      end if;
    end if;
  end process;

  -- Assert read data valid when rd_data state finishes.
  -- Deassert when a new read command is received, after opcode is decoded.
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      spi_access_strb_d <= spi_access_strb;
      if ((srst = '1') or (spi_access_strb_d = '1' and op_rd_wrn = '1')) then
        spi_rdata_valid <= '0';
      elsif (sclk_fe = '1' and spi_state = rd_data and bit_cnt = data_bits) then
        spi_rdata_valid <= '1';
      end if;
    end if;
  end process;

  -- SPI state machine
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        spi_rdata       <= (others => '0');
        spi_state       <= idle;
        ld_strb         <= (others => '0');
        aai_en          <= '0';
      elsif (sclk_fe = '1') then
        ld_strb         <= (others => '0');
        case spi_state is

          when idle =>
            if (spi_req = '1') then
              spi_state <= wr_opcode;
              ld_strb   <= LD_OPCODE;
            else
              spi_state <= idle;
            end if;

          when wr_opcode =>
            if (bit_cnt = 7) then
              if (op_adcy = '1' and aai_en = '0') then
                spi_state <= wr_addr;
                ld_strb   <= LD_ADDR;
              elsif (op_dacy = "00") then
                spi_state <= idle;
              elsif (op_rd_wrn = '0') then
                ld_strb   <= LD_DATA;
                spi_state <= wr_data;
              else
                ld_strb   <= LD_DATA;
                spi_state <= rd_data;
              end if;
              if (spi_opcode = OP_WRDI) then
                aai_en <= '0';
              end if;
            else
              spi_state <= wr_opcode;
            end if;

          when wr_addr =>
            if (bit_cnt = 23) then
              if (op_dmcy = '1') then
                ld_strb   <= LD_DUMMY;
                spi_state <= wr_dummy;
              elsif (op_dacy = "00") then
                spi_state <= idle;
              elsif (op_rd_wrn = '0') then
                ld_strb   <= LD_DATA;
                spi_state <= wr_data;
              else
                ld_strb   <= LD_DATA;
                spi_state <= rd_data;
              end if;
              if (spi_opcode = OP_AAI_PROG) then
                aai_en <= '1';
              end if;
            else
              spi_state <= wr_addr;
            end if;

          when wr_dummy =>
            if (bit_cnt = 7) then
              spi_state <= rd_data;
              ld_strb   <= LD_DATA;
            else
              spi_state <= wr_dummy;
            end if;

          when wr_data =>
            if (bit_cnt = data_bits) then
              spi_state <= idle;
            else
              spi_state <= wr_data;
            end if;

          when rd_data =>
            if (bit_cnt = data_bits) then
              spi_state <= idle;
              spi_rdata <= spi_di_sreg;
            else
              spi_state <= rd_data;
            end if;

        end case;
      else
        ld_strb <= (others => '0');
      end if;
    end if;
  end process;

  -- Load serial register with data that will be shifted out
  process (sys_clk)
    variable data_hi : integer;
    variable sreg_hi : integer;
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        spi_do_sreg <= (others => '0');
        data_bits   <= (others => '0');
      elsif (ld_strb = LD_OPCODE) then

        sreg_hi := spi_do_sreg'high;
        spi_do_sreg(sreg_hi downto sreg_hi-7) <= spi_opcode;

        data_hi := sreg_hi-32;  -- default to 3 byte address and no dummy cycles
        if (op_adcy = '1' and aai_en = '0') then  -- is there address cycles?
          if (op_dmcy = '1') then
            data_hi := sreg_hi-40;
          end if;
          spi_do_sreg(sreg_hi-8 downto sreg_hi-31) <= spi_addr;
        else
          data_hi := sreg_hi-8;
        end if;
        if (op_rd_wrn = '0') then   -- if write, load spi_do
          case op_dacy is
            when "01"   =>
              spi_do_sreg(data_hi downto data_hi-7)  <= spi_wdata(7 downto 0);
            when "10"   =>
              spi_do_sreg(data_hi downto data_hi-15) <= spi_wdata(15 downto 0);
            when "11"   =>
              spi_do_sreg(data_hi downto data_hi-23) <= spi_wdata;
            when others => null;
          end case;
        end if;
      elsif ld_strb = LD_DATA then
        case op_dacy is
          when "01"   =>
            data_bits <= to_unsigned(8,data_bits'length)-1;
          when "10"   =>
            data_bits <= to_unsigned(16,data_bits'length)-1;
          when "11"   =>
            data_bits <= to_unsigned(32,data_bits'length)-1;
          when others => null;
        end case;
      elsif (sclk_fe = '1') then                       -- Shift out
        spi_do_sreg <= spi_do_sreg(spi_do_sreg'high-1 downto 0) & '0';
      end if;
    end if;
  end process;

  sdo <= spi_do_sreg(spi_do_sreg'high);

  -- Shift data in
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or spi_access_strb = '1') then
        spi_di_sreg <= (others => '0');
      elsif (spi_state = rd_data and sclk_re = '1') then
        spi_di_sreg <= spi_di_sreg(30 downto 0) & spi_so_xdom;
      end if;
      spi_so_xdom <= fl_spi_so;
      spi_so      <= spi_so_xdom;
    end if;
  end process;

  -- Chip Enable
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (sclk_fe = '1' and spi_req = '1') then
        csb <= '0';
      elsif (srst = '1' or (sclk_re = '1' and spi_state = idle)) then
        csb <= '1';
      end if;
    end if;
  end process;

  -- Interface with the selected Flash
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or spi_state = idle) then
        fl_spi_si   <= '0';
        fl_spi_sclk <= '0';
      else
        fl_spi_si   <= sdo;
        fl_spi_sclk <= sclk;
      end if;
      fl_spi_csb <= csb;
    end if;
  end process;

end arch;

