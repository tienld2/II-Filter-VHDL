-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_deframer
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short Packet Deframer
--*
--* Description:
--*
--*   This component deframes incoming packets and routes them to peripheral
--*   devices according to each packet's header. The data source provides data
--*   after src_rden is true with src_data_vld. The source provides fifo status
--*   signals for pacing. Each destination peripheral must provide a ready for
--*   data flow control. The number of peripheral devices and the peripheral
--*   device number is taken from x6_pkg package.
--*
--*   @port srst            : input, synchronous active high reset
--*   @port sys_clk         : input, system clock
--*   @port pd_addr         : input, peripheral device numbers for decoding
--*   @port new_packet      :output, a new packet is being parsed
--*   @port bad_pdn         :output, a bad packet is detected
--*   @port end_of_packet   :output, last word in a packet is being read
--*   @port src_aempty      : input, source fifo is almost empty
--*   @port src_empty       : input, source fifo is empty
--*   @port src_rden        :output, source read enable
--*   @port src_data_vld    : input, source data is valid
--*   @port data_in         : input, data bus in (128 bits)
--*   @port dest_rdy        : input, destination fifo ready (num_pd_df-1 .. 0)
--*   @port dest_wren       :output, destination write enables (num_pd_df-1 .. 0)
--*   @port data_out        :output, data bus out (128 bits)
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 5/01/07
--*
--******************************************************************************
--/

library work;
use work.x6_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_deframer is
  port (
    -- Reset and clock
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;

    -- Configuration
    pd_addr              : in  width_8_pd_df_array;

    -- Status
    new_packet           : out std_logic;
    bad_pdn              : out std_logic;
    end_of_packet        : out std_logic;

    -- Source channel interface
    src_aempty           : in  std_logic;
    src_empty            : in  std_logic;
    src_rden             : out std_logic;
    src_data_vld         : in  std_logic;
    data_in              : in  std_logic_vector(127 downto 0);

    -- Destination channels interface
    dest_rdy             : in  std_logic_vector(num_pd_df-1 downto 0);
    dest_wren            : out std_logic_vector(num_pd_df-1 downto 0);
    data_out             : out std_logic_vector(127 downto 0)
  );
end ii_deframer;

architecture arch of ii_deframer is

  signal data_in_d            : std_logic_vector(127 downto 0);
  signal bad_pdn_int          : std_logic;
  type   defr_state_type is (idle, rd_hdr1, rd_pdn, dec_hdr1,
                             wait1, mv_pyld, last_dqwrd, dly_done);
  signal defr_state           : defr_state_type;
  signal latency_cnt          : std_logic_vector(3 downto 0);
  signal pdn                  : std_logic_vector(7 downto 0);
  signal periph_dev           : integer range 0 to num_pd_df-1;
  signal rem_pkt_dqwrds       : unsigned(21 downto 0);
  signal drip_dly_cnt         : unsigned(2 downto 0);
  signal sel_dest_rdy         : std_logic;

begin

  -- register the source data to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      data_in_d <= data_in;
    end if;
  end process;

  data_out <= data_in_d;

  -- Main state machine
  process (sys_clk )
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        src_rden       <= '0';
        new_packet     <= '0';
        pdn            <= (others => '0');
        periph_dev     <= 0;
        bad_pdn_int    <= '0';
        end_of_packet  <= '0';
        rem_pkt_dqwrds <= (others => '0');
        drip_dly_cnt   <= (others => '0');
        defr_state     <= idle;
      else
        src_rden      <= '0';
        new_packet    <= '0';
        end_of_packet <= '0';
        case defr_state is
          ----------------------------------------------------------------------
          when idle =>
            if (src_empty = '0') then       -- a point is available
              src_rden   <= '1';
              defr_state <= rd_hdr1;
            else
              defr_state <= idle;
            end if;
          ----------------------------------------------------------------------
          when rd_hdr1 =>
            new_packet <= '1';
            defr_state <= rd_pdn;
          ----------------------------------------------------------------------
          when rd_pdn =>
            if (src_data_vld = '1') then
              pdn        <= data_in(31 downto 24);-- latch the pdn from header 1
              defr_state <= dec_hdr1;
            else
              defr_state <= rd_pdn;
            end if;
          ----------------------------------------------------------------------
          when dec_hdr1 =>
            periph_dev  <= 0;                -- default value
            bad_pdn_int <= '1';              -- default value
            for i in 0 to (num_pd_df-1) loop -- lookup pdn in address table
              if (pdn = pd_addr(i)) then
                periph_dev  <= i;
                bad_pdn_int <= '0';
              end if;
            end loop;
            -- divide size by 4 and substract header double quad word
            -- to find the payload size
            rem_pkt_dqwrds <= unsigned(data_in_d(23 downto 2)) - 1;
            defr_state     <= wait1;
          ----------------------------------------------------------------------
          when wait1 =>                      -- to wait for src_empty to settle
            if (latency_cnt(3) = '1') then
              defr_state <= mv_pyld;
            else
              defr_state <= wait1;
            end if;
          ----------------------------------------------------------------------
          when mv_pyld =>                    -- Bleed and drip the source fifo
            if (sel_dest_rdy = '1' and src_empty = '0' and
                (src_aempty = '0' or drip_dly_cnt = "000")) then
              src_rden       <= '1';
              rem_pkt_dqwrds <= rem_pkt_dqwrds - 1;
              drip_dly_cnt   <= "100";
              if (rem_pkt_dqwrds = 1) then
                defr_state <= last_dqwrd;
              else
                defr_state <= mv_pyld;
              end if;
            else
              if (drip_dly_cnt /= "000") then
                drip_dly_cnt <= drip_dly_cnt - 1;
              end if;
            end if;
          ----------------------------------------------------------------------
          when last_dqwrd =>
            end_of_packet <= '1';
            defr_state    <= dly_done;
          ----------------------------------------------------------------------
          when dly_done =>                   -- to wait for src_empty to settle
            if (latency_cnt(3) = '1') then
              defr_state <= idle;
            else
              defr_state <= dly_done;
            end if;
          ----------------------------------------------------------------------
          when others =>
            defr_state <= idle;
          ----------------------------------------------------------------------
        end case;
      end if;
    end if;
  end process;

  -- Delay counter
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (defr_state = wait1 or defr_state = dly_done) then
        latency_cnt <= (latency_cnt(2 downto 0) & '1');
      else
        latency_cnt <= "0000";
      end if;
    end if;
  end process;

  bad_pdn <= bad_pdn_int;

  -- Select the output destination ready signal
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      sel_dest_rdy <= dest_rdy(periph_dev);
    end if;
  end process;

  gen_decodes: for i in 0 to (num_pd_df-1) generate
    -- Peripheral device decodes
    process (sys_clk)
    begin
      if (rising_edge(sys_clk)) then
        if ((defr_state = mv_pyld or defr_state = dly_done or
             defr_state = last_dqwrd) and bad_pdn_int = '0' and
             (i = periph_dev)) then
          dest_wren(i) <= src_data_vld;
        else
          dest_wren(i) <= '0';
        end if;
      end if;
    end process;
  end generate;

end arch;
