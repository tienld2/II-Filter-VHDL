-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design name: ii_vita_mover
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short VITA-49 Packet Mover
--*
--* Description:
--*
--*   This component routes VITA-49 format data packets, from one of num_src_ch
--*   source FIFOs into as many destination FIFOs as specified in the packet
--*   header.
--*
--*   @port srst            : input, synchronous active high reset
--*   @port sys_clk         : input, system clock
--*   @port en_strb         : input, enable data mover strobe
--*   @port src_ch_sel      : input, source channel select
--*   @port src_ch_hdr      : input, source channel header
--*   @port mvr_busy        :output, mover is busy
--*   @port dst_wip         :output, destination write in progress
--*   @port src_rd_done     :output, source channel read is done
--*   @port src_aempty      : input, source channel fifo almost empty
--*   @port src_empty       : input, source channel fifo empty
--*   @port src_rden        :output, source channel fifo read enables
--*   @port src_vld         : input, source channel data is valid
--*   @port src_data        : input, source channel data
--*   @port dst_rdy         : input, destination fifo ready
--*   @port dst_wren        :output, destination fifo write
--*   @port dst_data        :output, destination fifo data
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 07/13/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_vita_mover is
  generic (
    num_src_ch           : integer := 4;
    log2_num_src_ch      : integer := 2;
    num_dst_ch           : integer := 3
  );
  port (
    -- Reset and clock
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;

    -- Control and Status
    en_strb              : in  std_logic;
    src_ch_sel           : in  std_logic_vector(log2_num_src_ch-1 downto 0);
    src_ch_hdr           : in  std_logic_vector(127 downto 0);
    mvr_busy             : out std_logic;
    dst_wip              : out std_logic_vector(num_dst_ch-1 downto 0);
    src_rd_done          : out std_logic_vector(num_src_ch-1 downto 0);

    -- Source channels interface
    src_aempty           : in  std_logic_vector(num_src_ch-1 downto 0);
    src_empty            : in  std_logic_vector(num_src_ch-1 downto 0);
    src_rden             : out std_logic_vector(num_src_ch-1 downto 0);
    src_vld              : in  std_logic_vector(num_src_ch-1 downto 0);
    src_data             : in  std_logic_vector(128*num_src_ch-1 downto 0);

    -- Destination FIFOs interface
    dst_rdy              : in  std_logic_vector(num_dst_ch-1 downto 0);
    dst_wren             : out std_logic;
    dst_data             : out std_logic_vector(127 downto 0)
  );
end ii_vita_mover;

architecture arch of ii_vita_mover is

  function REDUCTION_AND(A: in std_logic_vector) return std_logic is
    variable tmp : std_logic := '1';
  begin
    for i in A'range loop
      tmp := tmp and A(i);
    end loop;
    return tmp;
  end function REDUCTION_AND;

  signal pkt_dqwrds           : unsigned(13 downto 0);
  signal pkt_dst              : std_logic_vector(15 downto 0);
  constant all_ones           : std_logic_vector(15 downto num_dst_ch) := (others => '1');
  signal all_dst_rdy          : std_logic;
  signal src_ch               : integer range 0 to (2**log2_num_src_ch)-1;
  signal sel_ch_aempty        : std_logic;
  signal sel_ch_empty         : std_logic;
  signal rem_pkt_dqwrds       : unsigned(13 downto 0);
  signal drip_dly_cnt         : unsigned(2 downto 0);
  signal sel_ch_rden          : std_logic;
  type   mvr_state_type is (idle, wr_hdr, mv_pyld, wait_last_src_vld);
  signal mvr_state            : mvr_state_type;
  signal rem_data_vld_cnt     : unsigned(13 downto 0);
  constant data_width         : integer := 128;
  subtype width_slv is std_logic_vector(data_width-1 downto 0);
  type   data_array is array (num_src_ch-1 downto 0) of width_slv;
  signal src_data_arr         : data_array;

begin

  -- Decode the packet header
  pkt_dqwrds <= unsigned(src_ch_hdr(15 downto 2));-- total number of 128bit
                                                  -- words in the packet
  pkt_dst    <= src_ch_hdr(63 downto 48);         -- destination(s) selector
                                                  -- each bit references 1 of
                                                  -- up to 16 destinations

  -- Set all_dst_rdy when all the selected destination fifos are ready.
  -- if the header references a non-existing destination, then just bleed
  -- that packet.
  all_dst_rdy <= REDUCTION_AND(not pkt_dst or (all_ones & dst_rdy));

  -- convert the std_logic_vector to integer
  src_ch <= to_integer(unsigned(src_ch_sel));

  -- Mux to select the status of one of the source channels
  -- specified by src_ch
  sel_ch_aempty <= src_aempty(src_ch);
  sel_ch_empty  <= src_empty(src_ch);

  -- Mover state machine
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        rem_pkt_dqwrds <= (others => '0');
        drip_dly_cnt   <= (others => '0');
        sel_ch_rden    <= '0';
        mvr_state      <= idle;
        mvr_busy       <= '0';
        dst_wip        <= (others => '0');
        src_rd_done    <= (others => '0');
      else
        mvr_busy       <= '1';
        sel_ch_rden    <= '0';
        src_rd_done    <= (others => '0');
        case mvr_state is
          ----------------------------------------------------------------------
          when idle =>
            if (en_strb = '1') then
              mvr_state <= wr_hdr;
              dst_wip   <= pkt_dst(num_dst_ch-1 downto 0);
            else
              mvr_state <= idle;
              mvr_busy  <= '0';
              dst_wip   <= (others => '0');
            end if;
          ----------------------------------------------------------------------
          when wr_hdr =>
            if (all_dst_rdy = '1') then
              rem_pkt_dqwrds <= pkt_dqwrds - 1;
              mvr_state      <= mv_pyld;
            end if;
          ----------------------------------------------------------------------
          when mv_pyld =>              -- Bleed and drip the source fifo
            if (all_dst_rdy = '1' and sel_ch_empty = '0' and
                (sel_ch_aempty = '0' or drip_dly_cnt = "000")) then
              sel_ch_rden    <= '1';
              rem_pkt_dqwrds <= rem_pkt_dqwrds - 1;
              drip_dly_cnt   <= "111";
              if (rem_pkt_dqwrds = 1) then
                mvr_state <= wait_last_src_vld;
              end if;
            else
              if (drip_dly_cnt /= "000") then
                drip_dly_cnt <= drip_dly_cnt - 1;
              end if;
            end if;
          ----------------------------------------------------------------------
          when wait_last_src_vld =>    -- wait for the last src_vld
            if (rem_data_vld_cnt = to_unsigned(0,rem_data_vld_cnt'length)) then
              mvr_state           <= idle;
              src_rd_done(src_ch) <= '1';
            end if;
          ----------------------------------------------------------------------
          when others =>
            mvr_state <= idle;
          ----------------------------------------------------------------------
        end case;
      end if;
    end if;
  end process;

  -- Demux sel_ch_rden to src_rden according to src_ch
  process (src_ch, sel_ch_rden)
  begin
    src_rden         <= (others => '0');
    src_rden(src_ch) <= sel_ch_rden;
  end process;

  -- Take src_data flat-vector into array form
  process (src_data)
  begin
    for i in 1 to num_src_ch loop
      src_data_arr(i-1) <= src_data((i*data_width)-1 downto (i-1)*data_width);
    end loop;
  end process;

  -- Mux between the header data and source channel fifo data
  -- to the output destination fifo(s).
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        dst_wren <= '0';
      elsif (mvr_state = wr_hdr and all_dst_rdy = '1') then
        dst_wren         <= '1';
        dst_data         <= src_ch_hdr;
        rem_data_vld_cnt <= pkt_dqwrds - 1;
      elsif (mvr_state = mv_pyld or mvr_state = wait_last_src_vld) then
        dst_wren <= src_vld(src_ch);
        if (src_vld(src_ch) = '1') then
          dst_data         <= src_data_arr(src_ch);
          rem_data_vld_cnt <= rem_data_vld_cnt - 1;
        end if;
      end if;
    end if;
  end process;

end arch;

