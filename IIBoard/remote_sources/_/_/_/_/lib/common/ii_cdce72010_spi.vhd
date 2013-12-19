-- Copyright 2009 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_cdce72010_spi
--*
--* @li Target Device: generic
--* @li Tool versions: any
--*
--*     @short Texas Instruments CDCE72010 PLL SPI control port
--*
--* Description:
--*
--*   This component is an SPI port interface to the TI CDCE72010.
--*   The CDCD72010 device is configured and monitored over this SPI port.
--*   The maximum clock rate to the serial port is 20 MHz. For reads, a
--*   28-bit word instruction word is sent with a 4-bit address and a 32-bit
--*   word is returned.
--*   For writes, a 32-bit word is transmitted consisting of a 4-bit address
--*   followed by 28-bits of data.
--*
--*   @port srst               : input, synchronous active high reset
--*   @port clk                : input, system clock
--*   @port spi_wr_strb        : input, trigger an SPI transaction
--*   @port spi_wdata          : input, PLL SPI write data
--*   @port spi_addr           : input, PLL register address
--*   @port spi_rdy            :output, PLL SPI port is ready
--*   @port spi_rdata_valid    :output, SPI read data is valid
--*   @port spi_rdata          :output, last SPI read data
--*   @port spi_sclk           :output, SPI clock
--*   @port spi_le             :output, SPI load enable, active low
--*   @port spi_mosi           :output, SPI master out slave in
--*   @port spi_miso           : input, SPI master in slave out
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 1/2/09
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_cdce72010_spi is
  port (
    srst                 : in  std_logic;
    clk                  : in  std_logic;

    -- User interface
    spi_wr_strb          : in  std_logic;
    spi_wdata            : in  std_logic_vector(27 downto 0);
    spi_addr             : in  std_logic_vector(3 downto 0);
    spi_rdy              : out std_logic;
    spi_rdata_valid      : out std_logic;
    spi_rdata            : out std_logic_vector(31 downto 0);

    -- PLL spi interface
    spi_sclk             : out std_logic;
    spi_le               : out std_logic;
    spi_mosi             : out std_logic;
    spi_miso             : in  std_logic
  );
end ii_cdce72010_spi;


architecture arch of ii_cdce72010_spi is

  signal div_cnt      : unsigned(3 downto 0);
  signal enab         : std_logic;
  signal ser_clk      : std_logic;
  signal spi_req      : std_logic;
  signal rd_cycle     : std_logic;
  type spi_state_t is (idle, tx_state, turn, rx_state, last_bit, complete);
  signal spi_state    : spi_state_t;
  signal bit_cnt      : unsigned(4 downto 0);
  signal le           : std_logic;
  signal sreg         : std_logic_vector(31 downto 0);

begin

  -- clock divider
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        div_cnt <= (others => '0');
      else
        div_cnt <= div_cnt + 1;
      end if;
    end if;
  end process;

  -- enable on each clock cycle
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (div_cnt = "1111") then
        enab <= '1';
      else
        enab <= '0';
      end if;
      if (div_cnt = "1111") then
        ser_clk <= '0';
      elsif (div_cnt = "1000") then
        ser_clk <= '1';
      end if;
    end if;
  end process;

  -- extend spi_wr_strb into a wider pulse that can be seen by
  -- the state machine
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        spi_req <= '0';
      elsif (spi_wr_strb = '1') then
        spi_req <= '1';
      elsif (enab = '1') then
        spi_req <= '0';
      end if;
    end if;
  end process;

  -- detect read cycle, address X"E" is read command
  process (clk)
  begin
    if ( rising_edge(clk) ) then
      if (spi_wr_strb = '1') then
        if (spi_addr = X"E") then
          rd_cycle <= '1';
        else
          rd_cycle <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Main FSM
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        spi_state       <= idle;
        bit_cnt         <= (others => '0');
        spi_rdata_valid <= '0';
      elsif (enab = '1') then
        bit_cnt         <= (others => '0');
        case spi_state is
          ----------------------------------------------------------------------
          when idle =>
            if (spi_req = '1') then
              spi_state <= tx_state;
              if (rd_cycle = '1') then
                spi_rdata_valid <= '0';
              end if;
            else
              spi_state <= idle;
            end if;
          ----------------------------------------------------------------------
          when tx_state =>
            if (bit_cnt = 31) then
              spi_state <= turn;
            else
              spi_state <= tx_state;
            end if;
            bit_cnt <= bit_cnt + 1;
          ----------------------------------------------------------------------
          when turn =>
            if (rd_cycle = '1') then
              spi_state <= rx_state;
            else
              spi_state <= complete;
            end if;
          ----------------------------------------------------------------------
          when rx_state =>
            if (bit_cnt = 31) then
              spi_state <= last_bit;
            else
              spi_state <= rx_state;
            end if;
            bit_cnt <= bit_cnt + 1;
          ----------------------------------------------------------------------
          when last_bit =>
            spi_state <= complete;
          ----------------------------------------------------------------------
          when complete =>
            spi_state <= idle;
            spi_rdata <= sreg;
            if (rd_cycle = '1') then
              spi_rdata_valid <= '1';
            end if;
          ----------------------------------------------------------------------
          when others =>
            spi_state <= idle;
        end case;
      end if;
    end if;
  end process;

  -- signal spi_rdy when the transfer is completed
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        spi_rdy <= '1';
      else
        if (spi_state = complete and enab = '1') then
          spi_rdy <= '1';
        elsif (spi_req = '1') then
          spi_rdy <= '0';
        end if;
      end if;
    end if;
  end process;

  -- make an envelope for the bit stream
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        le     <= '1';
        spi_le <= '1';
      else
        -- le changes 4 clocks ahead of the rising edge on ser_clk
        if (div_cnt = "0100") then
          if (spi_state = tx_state or spi_state = rx_state) then
            le <= '0';
          else
            le <= '1';
          end if;
        end if;
        spi_le <= le;
      end if;
    end if;
  end process;

  -- SPI clock enabled when transfer is in progress
  process (clk)
  begin
    if (rising_edge(clk)) then
      spi_sclk <= ser_clk and not le;
    end if;
  end process;

  -- data shift register
  -- data <= data(27..0) & address(3..0);
  -- shift register
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (spi_wr_strb = '1') then
        sreg(31 downto 0) <= spi_wdata & spi_addr;
      elsif (enab = '1' and le = '0') then
        sreg(31 downto 0) <= spi_miso & sreg(31 downto 1);
      end if;
    end if;
  end process;

  spi_mosi <= sreg(0);

end arch;
