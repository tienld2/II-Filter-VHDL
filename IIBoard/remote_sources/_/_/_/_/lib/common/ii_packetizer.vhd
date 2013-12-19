-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design name: ii_packetizer
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short Packetizer
--*
--* Description:
--*
--*   This component packetizes data into ii format data packets.
--*   Format of the packet is a four dword header, followed by a data payload.
--*   The header format is
--*     bits[31:24]  = peripheral device number
--*     bits[23:0]   = packet size including header in dwords
--*     dword = 32 bit word
--*   The component reads data from num_pkt_ch of data sources for a max
--*   of ch_pkt_size points and gives out a packet with a header.
--*   The data width is 128; input and output are identical in size. The data
--*   sources provide data with valid after each src_rden().
--*   Data destination must sink data continuously when dest_wren is true.
--*   The status of the source and destination devices is required by the
--*   src_data_cnt(), src_aempty(), src_empty(), and dest_rdy.
--*   No movement occurs if the destination does not have room.
--*
--*   @port srst            : input, synchronous active high reset
--*   @port sys_clk         : input, system clock
--*   @port ch_en           : input, channel enables
--*   @port ch_pkt_size     : input, the packet sizes for each channel
--*                                  in 32 bit words (must be > 1)
--*   @port pd_addr         : input, peripheral device numbers
--*   @port aux_hdr2        : input, auxiliary header value
--*   @port force_pkt_size  : input, force ch_pkt_size for each channel
--*   @port src_data_cnt    : input, source channel fifo word count
--*   @port src_aempty      : input, source channel fifo almost empty
--*   @port src_empty       : input, source channel fifo empty
--*   @port src_rden        :output, source channel fifo read enables
--*   @port src_data_vld    : input, source channel data is valid
--*   @port data_in         : input, source channel data in array
--*   @port dest_rdy        : input, destination fifo ready
--*   @port dest_wren       :output, destination fifo write enable
--*   @port data_out        :output, packetized data out
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 03/10/10
--*
--******************************************************************************
--/

library work;
use work.x6_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_packetizer is
  port (
    -- Reset and clock
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;

    -- Configuration
    ch_en                : in  std_logic_vector(num_pkt_ch-1 downto 0);
    ch_pkt_size          : in  width_24_ch_array;
    pd_addr              : in  width_8_ch_array;
    aux_hdr2             : in  std_logic_vector(31 downto 0);
    force_pkt_size       : in  std_logic_vector(num_pkt_ch-1 downto 0);
    pkt_timer            : in  std_logic_vector(21 downto 0);

    -- Source channels interface
    src_data_cnt         : in  width_22_ch_array;
    src_aempty           : in  std_logic_vector(num_pkt_ch-1 downto 0);
    src_empty            : in  std_logic_vector(num_pkt_ch-1 downto 0);
    src_rden             : out std_logic_vector(num_pkt_ch-1 downto 0);
    src_data_vld         : in  std_logic_vector(num_pkt_ch-1 downto 0);
    data_in              : in  width_128_ch_array;

    -- Destination channel interface
    dest_rdy             : in  std_logic;
    dest_wren            : out std_logic;
    data_out             : out std_logic_vector(127 downto 0)
  );
end ii_packetizer;

architecture arch of ii_packetizer is

  signal ch_update_sreg       : std_logic_vector(4 downto 0);
  signal ch_update_1s         : std_logic;
  signal ch_update_3s         : std_logic;
  signal ch_sel               : integer range 0 to num_pkt_ch-1;
  signal sel_ch_data_cnt      : std_logic_vector(21 downto 0);
  signal sel_ch_aempty        : std_logic;
  signal sel_ch_empty         : std_logic;
  signal sel_ch_max_pkt_size  : std_logic_vector(23 downto 0);
  signal sel_frc_ch_size      : std_logic;
  signal sel_ch_max_dqwrds    : unsigned(21 downto 0);
  signal sel_ch_pyld_dqwrds   : unsigned(21 downto 0);
  signal sel_ch_pkt_size      : std_logic_vector(23 downto 0);
  signal rem_pkt_dqwrds       : unsigned(21 downto 0);
  signal drip_dly_cnt         : unsigned(2 downto 0);
  signal sel_ch_rden          : std_logic;
  type   pkt_state_type is (idle, wr_hdr, mv_pyld, wait_last_src_vld);
  signal pkt_state            : pkt_state_type;
  signal sel_ch_pd_addr       : std_logic_vector(7 downto 0);
  signal header_dwrd1         : std_logic_vector(31 downto 0);
  signal header_dwrd2         : std_logic_vector(31 downto 0);
  signal header_qwrd1         : std_logic_vector(63 downto 0);
  constant header_qwrd2       : std_logic_vector(63 downto 0) := (others=> '0');
  signal dest_rdy_d           : std_logic;
  signal data_in_d            : width_128_ch_array;
  signal src_data_vld_d       : std_logic_vector(num_pkt_ch-1 downto 0);
  signal rem_data_vld_cnt     : unsigned(21 downto 0);
  signal timer_cnt            : unsigned(21 downto 0);
  signal timeout              : std_logic;
  signal ch_timeout_seen      : std_logic_vector(num_pkt_ch-1 downto 0);
  signal ch_timeout           : std_logic_vector(num_pkt_ch-1 downto 0);
  signal sel_ch_timeout       : std_logic;
  signal sel_pkt_size_met     : std_logic;
  signal ch_pkt_size_met      : std_logic_vector(num_pkt_ch-1 downto 0);
  signal src_data_cnt_d       : width_22_ch_array;
  signal ch_max_dqwrds        : width_22_ch_array;

begin

  -- Free running 1ms timer
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      timeout <= '0';
      if (srst = '1') then
        timer_cnt <= unsigned(pkt_timer);
      elsif (timer_cnt = to_unsigned(0, timer_cnt'length)) then
        timer_cnt <= unsigned(pkt_timer);
        timeout   <= '1';
      else
        timer_cnt <= timer_cnt - 1;
      end if;
    end if;
  end process;

  gen_ch_timeout: for i in 0 to num_pkt_ch-1 generate
    -- Each channel has a ch_timeout_seen flag that indicates that a free
    -- running counter has elapsed for the channel with some data available.
    -- When the ch_timeout_seen flag is asserted and a new timeout strobes,
    -- the ch_timeout for the channel is set, indicating that at least one
    -- full timeout time has elapsed for that channel and it's ready to be
    -- packetized by the state machine.
    process (sys_clk)
    begin
      if (rising_edge(sys_clk)) then
        if (srst = '1') then
          ch_timeout_seen(i) <= '0';
          ch_timeout(i)      <= '0';
        elsif (timeout = '1') then
          ch_timeout_seen(i) <= not src_empty(i) and ch_en(i);
          ch_timeout(i)      <= ch_timeout_seen(i);
        elsif ((ch_sel = i and pkt_state = wr_hdr) or src_empty(i) = '1') then
          ch_timeout_seen(i) <= '0';
          ch_timeout(i)      <= '0';
        end if;
      end if;
    end process;

    -- Compare FIFO points with requested max packet size, per channel.
    process (sys_clk)
    begin
      if (rising_edge(sys_clk)) then
        src_data_cnt_d(i)    <= src_data_cnt(i);
        ch_max_dqwrds(i)     <= std_logic_vector(resize(unsigned(
                                ch_pkt_size(i)(23 downto 2)) - 1, 22));
        if (src_data_cnt_d(i) >= ch_max_dqwrds(i)) then
          ch_pkt_size_met(i) <= '1';
        else
          ch_pkt_size_met(i) <= '0';
        end if;
      end if;
    end process;
  end generate;

  -- Channel update pacing shift register
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or pkt_state /= idle) then
        ch_update_sreg <= "00010";
      else
        ch_update_sreg <= ch_update_sreg(0) & ch_update_sreg(4 downto 1);
      end if;
    end if;
  end process;

  ch_update_1s <= ch_update_sreg(4);
  ch_update_3s <= ch_update_sreg(2);

  -- Channel flag select counter
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (ch_update_1s = '1') then
        -- if we have examined the last channel then go back to channel 0
        if (ch_sel = num_pkt_ch-1) then
          ch_sel <= 0;
        else
          ch_sel <= ch_sel + 1;
        end if;
      end if;
    end if;
  end process;

  -- Mux to select the status and config parameter of
  -- one of the source channels specified by ch_sel
  -- also mask the status of the selected source channel if not enabled
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      sel_ch_data_cnt     <= src_data_cnt(ch_sel);
      sel_ch_aempty       <= src_aempty(ch_sel) or not ch_en(ch_sel);
      sel_ch_empty        <= src_empty(ch_sel) or not ch_en(ch_sel);
      sel_ch_max_pkt_size <= ch_pkt_size(ch_sel);
      sel_frc_ch_size     <= force_pkt_size(ch_sel);
      sel_ch_timeout      <= ch_timeout(ch_sel);
      sel_pkt_size_met    <= ch_pkt_size_met(ch_sel);
    end if;
  end process;

  -- Divide sel_ch_max_pkt_size by 4 to get the size in 128bit words
  -- then subtract the header double quad words to find the max payload
  -- size in 128bit words (i.e. number of required source fifo reads)
  sel_ch_max_dqwrds <= resize(unsigned(sel_ch_max_pkt_size(23 downto 2)) - 1,
                                       sel_ch_max_dqwrds'length);

  -- Packetizer state machine
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        rem_pkt_dqwrds <= (others => '0');
        drip_dly_cnt   <= (others => '0');
        sel_ch_rden    <= '0';
        pkt_state      <= idle;
      else
        sel_ch_rden <= '0';
        case pkt_state is
          ----------------------------------------------------------------------
          when idle =>
            if (sel_ch_aempty = '0' and dest_rdy_d = '1' and
                ch_update_3s = '1') then
              -- Latch the payload size depending on the number
              -- of available data points if channel has timed out.
              -- If channel met its requested packet size or it has
              -- a forced size flag set, set max packet size for payload.
              if (sel_pkt_size_met = '1') then
                sel_ch_pyld_dqwrds <= sel_ch_max_dqwrds;
                pkt_state          <= wr_hdr;
              elsif (sel_ch_timeout = '1' and sel_frc_ch_size = '0') then
                sel_ch_pyld_dqwrds <= unsigned(sel_ch_data_cnt);
                pkt_state          <= wr_hdr;
              else
                pkt_state          <= idle;
              end if;
            else
              pkt_state <= idle;
            end if;
          ----------------------------------------------------------------------
          when wr_hdr =>
            rem_pkt_dqwrds <= sel_ch_pyld_dqwrds;
            pkt_state      <= mv_pyld;
          ----------------------------------------------------------------------
          when mv_pyld =>              -- Bleed and drip the source fifo
            if (dest_rdy_d = '1' and sel_ch_empty = '0' and
                (sel_ch_aempty = '0' or drip_dly_cnt = "000")) then
              sel_ch_rden   <= '1';
              rem_pkt_dqwrds <= rem_pkt_dqwrds - 1;
              drip_dly_cnt   <= "110";
              if (rem_pkt_dqwrds = 1) then
                pkt_state <= wait_last_src_vld;
              end if;
            else
              if (drip_dly_cnt /= "000") then
                drip_dly_cnt <= drip_dly_cnt - 1;
              end if;
            end if;
          ----------------------------------------------------------------------
          when wait_last_src_vld =>    -- wait for the last src_data_vld
            if (rem_data_vld_cnt = to_unsigned(0,rem_data_vld_cnt'length)) then
              pkt_state <= idle;
            else
              pkt_state <= wait_last_src_vld;
            end if;
          ----------------------------------------------------------------------
          when others =>
            pkt_state <= idle;
          ----------------------------------------------------------------------
        end case;
      end if;
    end if;
  end process;

  -- Demux sel_ch_rden to src_rden according to ch_sel
  gen_src_rden: for i in 0 to num_pkt_ch-1 generate
    process (sys_clk)
    begin
      for i in 0 to num_pkt_ch-1 loop
        if (rising_edge(sys_clk)) then
          if (srst = '1') then
            src_rden(i) <= '0';
          elsif (ch_sel = i) then
            src_rden(i) <= sel_ch_rden;
          else
            src_rden(i) <= '0';
          end if;
        end if;
      end loop;
    end process;
  end generate;

  -- header generation
  sel_ch_pd_addr  <= pd_addr(ch_sel);
  sel_ch_pkt_size <= std_logic_vector((sel_ch_pyld_dqwrds+1) & "00");

  -- first 64 bit header word
  header_dwrd1 <= sel_ch_pd_addr & sel_ch_pkt_size;  -- (7:0) & (23:0)
  header_dwrd2 <= aux_hdr2;
  header_qwrd1 <= (header_dwrd2 & header_dwrd1);

  -- register the input to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      dest_rdy_d     <= dest_rdy;
      data_in_d      <= data_in;
      src_data_vld_d <= src_data_vld;
    end if;
  end process;

  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        dest_wren <= '0';
      elsif (pkt_state = wr_hdr) then
        dest_wren        <= '1';
        data_out         <= header_qwrd2 & header_qwrd1;
        rem_data_vld_cnt <= sel_ch_pyld_dqwrds;
      else
        dest_wren <= src_data_vld_d(ch_sel);
        if (src_data_vld_d(ch_sel) = '1') then
          data_out         <= data_in_d(ch_sel);
          rem_data_vld_cnt <= rem_data_vld_cnt - 1;
        end if;
      end if;
    end if;
  end process;

end arch;

