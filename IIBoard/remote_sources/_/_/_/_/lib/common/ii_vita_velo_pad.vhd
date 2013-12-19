-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design name: ii_vita_velo_pad
--*
--* @li Target Device: any
--* @li Tool versions: ISE 13.1
--*
--*     @short Velocia Packet Padder
--*
--* Description:
--*
--*   This component aligns VITA-49 format data packets into a Velocia packet,
--*   making sure an integer number of VITA packets fit in the requested
--*   Velocia packet size. If this is not possible, an extra VITA packet will
--*   be generated as a filler to complete the requested size.
--*   The component reads data from one data source.
--*   The data width is 128; input and output are identical in size. The data
--*   sources provide data with valid after each src_rden().
--*   The input data is briefly stored in a 512 deep dual-quad-word FIFO
--*   waiting to be drained by packetizer.
--*
--*   @port srst            : input, synchronous active high reset
--*   @port sys_clk         : input, system clock
--*   @port ch_pkt_size     : input, requested Velocia packet size
--*   @port force_pkt_size  : input, force Velocia size
--*   @port bypass          : input, bypass padding
--*   @port src_wrd_cnt     : input, source fifo word count
--*   @port src_aempty      : input, source channel fifo almost empty
--*   @port src_empty       : input, source channel fifo empty
--*   @port src_rden        :output, source channel fifo read enables
--*   @port src_vld         : input, source channel data is valid
--*   @port src_data        : input, source channel data
--*   @port dst_wrd_cnt     :output, Velocia packet size to packetizer
--*   @port dst_aempty      :output, destination fifo almost empty
--*   @port dst_empty       :output, destination fifo empty
--*   @port dst_rden        : input, destination fifo read enable
--*   @port dst_vld         :output, destination fifo data out valid
--*   @port dst_dout        :output, destination fifo data out
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 05/05/11
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_vita_velo_pad is
  port (
    -- Reset and clock
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;
    ch_pkt_size          : in  std_logic_vector(23 downto 0);
    force_pkt_size       : in  std_logic;
    bypass               : in  std_logic;

    -- Source channel interface
    src_wrd_cnt          : in  std_logic_vector(21 downto 0);
    src_aempty           : in  std_logic;
    src_empty            : in  std_logic;
    src_rden             : out std_logic;
    src_vld              : in  std_logic;
    src_data             : in  std_logic_vector(127 downto 0);

    -- Destination channel interface
    dst_wrd_cnt          : out std_logic_vector(21 downto 0);
    dst_aempty           : out std_logic;
    dst_empty            : out std_logic;
    dst_rden             : in  std_logic;
    dst_vld              : out std_logic;
    dst_dout             : out std_logic_vector(127 downto 0)
  );
end ii_vita_velo_pad;

architecture arch of ii_vita_velo_pad is

  component ii_vita_mover
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
  end component;

  component sfifo_512x128_bram
    port (
      clk                  : in  std_logic;
      srst                 : in  std_logic;
      din                  : in  std_logic_vector(127 downto 0);
      wr_en                : in  std_logic;
      rd_en                : in  std_logic;
      dout                 : out std_logic_vector(127 downto 0);
      full                 : out std_logic;
      empty                : out std_logic;
      valid                : out std_logic;
      data_count           : out std_logic_vector(8 downto 0);
      prog_full            : out std_logic;
      prog_empty           : out std_logic
    );
  end component;

  signal fifo_rst             : std_logic;
  signal velo_size            : unsigned(21 downto 0);
  signal bypass_d             : std_logic;
  signal src_wrd_cnt_d        : unsigned(21 downto 0);
  signal src_aempty_d         : std_logic_vector(0 downto 0);
  signal src_empty_d          : std_logic_vector(0 downto 0);
  signal src_vld_d            : std_logic_vector(0 downto 0);
  signal src_data_d           : std_logic_vector(127 downto 0);
  type   state_type is (idle, wait_hdr, wait_comp, set_velo_size, set_vita_size,
                        wait_vita_done, wait_pad_done, nxt_hdr, wait_dst_empty);
  signal state                : state_type;
  signal nxt_state            : state_type;
  signal src_hdr_rden         : std_logic;
  signal mvr_en_strb          : std_logic;
  signal pad_en_strb          : std_logic;
  signal pad_pkt_size         : std_logic_vector(15 downto 0);
  signal src_hdr_pulled       : std_logic;
  signal dst_wrd_cnt_u        : unsigned(21 downto 0);
  signal vita_hdr             : std_logic_vector(127 downto 0);
  signal vita_size            : unsigned(21 downto 0);
  signal vita_size_min        : unsigned(21 downto 0);
  signal src_wrd_cnt_l        : unsigned(21 downto 0);
  signal velo_size_left       : unsigned(21 downto 0);
  signal src_wrd_cnt_gte_velo : boolean;
  signal src_wrd_cnt_lte_vita : boolean;
  signal velo_lft_eq_vita     : boolean;
  signal velo_lft_gte_vita_mn : boolean;
  signal src_rd_done          : std_logic_vector(0 downto 0);
  signal src_mvr_rden         : std_logic_vector(0 downto 0);
  signal mvr_dst_wren         : std_logic;
  signal mvr_dst_data         : std_logic_vector(127 downto 0);
  signal dst_wren             : std_logic;
  signal dst_data             : std_logic_vector(127 downto 0);
  signal dst_empty_c          : std_logic;
  signal dst_aempty_c         : std_logic;
  signal dst_dout_c           : std_logic_vector(127 downto 0);
  signal dst_vld_c            : std_logic;
  signal dst_afull            : std_logic;
  signal dst_rdy              : std_logic_vector(15 downto 0);

  -- Padder
  type   pad_state_t is (idle, hdr1, hdr2, pyld, trailer);
  signal pad_state            : pad_state_t;
  signal pad_done             : std_logic;
  signal pad_dst_wren         : std_logic;
  signal pad_dst_data         : std_logic_vector(127 downto 0);
  signal pad_pkt_size_dcnt    : unsigned(15 downto 0);
  signal pkt_hdr_0            : std_logic_vector(31 downto 0);
  signal pkt_hdr_1            : std_logic_vector(31 downto 0);
  signal pkt_hdr_2            : std_logic_vector(31 downto 0);
  signal pkt_hdr_3            : std_logic_vector(31 downto 0);
  signal pkt_hdr_4            : std_logic_vector(31 downto 0);
  signal pkt_hdr_5            : std_logic_vector(31 downto 0);
  signal pkt_hdr_6            : std_logic_vector(31 downto 0);
  signal pkt_trailer          : std_logic_vector(31 downto 0);

  -- Constants in filler VITA packet
  constant pkt_pyld           : std_logic_vector(31 downto 0):= (others => '0');
  constant tsi                : std_logic_vector(1 downto 0) := (others => '0');
  constant tsf                : std_logic_vector(1 downto 0) := (others => '0');
  constant ts_int_secs        : std_logic_vector(31 downto 0):= (others => '0');
  constant ts_frc_secs        : std_logic_vector(63 downto 0):= (others => '0');
  constant sof                : std_logic := '1';
  constant eof                : std_logic := '1';
  constant pad_bytes          : std_logic_vector(3 downto 0) := (others => '0');
  constant pad_pkt_cnt        : std_logic_vector(3 downto 0) := (others => '0');
  constant stream_id          : std_logic_vector(31 downto 0):= (others => '1');

begin

  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      fifo_rst        <= srst;
      velo_size       <= resize(unsigned(ch_pkt_size(23 downto 2)) - 1, 22);
      bypass_d        <= bypass;
      src_wrd_cnt_d   <= unsigned(src_wrd_cnt);
      src_aempty_d(0) <= src_aempty;
      src_empty_d(0)  <= src_empty;
      src_rden        <= src_hdr_rden or src_mvr_rden(0) or
                         (bypass_d and dst_rden);
      src_vld_d(0)    <= src_vld;
      src_data_d      <= src_data;
    end if;
  end process;

  -- State machine
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        state          <= idle;
        nxt_state      <= idle;
        src_hdr_rden   <= '0';
        mvr_en_strb    <= '0';
        pad_en_strb    <= '0';
        src_hdr_pulled <= '0';
      else
        src_hdr_rden   <= '0';
        mvr_en_strb    <= '0';
        pad_en_strb    <= '0';
        case state is
          ----------------------------------------------------------------------
          when idle =>
            state         <= idle;
            src_wrd_cnt_l <= (others => '0');
            dst_wrd_cnt_u <= (others => '0');
            if (bypass_d = '1') then
              dst_wrd_cnt_u <= src_wrd_cnt_d;
            elsif (src_empty_d(0) = '0') then
              if (src_hdr_pulled = '1') then
                state          <= wait_comp;
                nxt_state      <= set_velo_size;
                src_wrd_cnt_l  <= src_wrd_cnt_d;
              else
                state          <= wait_hdr;
                nxt_state      <= set_velo_size;
                src_hdr_rden   <= '1';
                src_hdr_pulled <= '1';
              end if;
            end if;
          ----------------------------------------------------------------------
          when wait_hdr =>
            src_wrd_cnt_l <= src_wrd_cnt_d;
            if (src_vld_d(0) = '1') then
              state <= wait_comp;
            end if;
            if (src_vld = '1') then
              vita_hdr <= src_data;
            end if;
          ----------------------------------------------------------------------
          when wait_comp =>
            state <= nxt_state;
          ----------------------------------------------------------------------
          when set_velo_size =>  -- Decide what size the velocia packet will be
            state         <= wait_comp;
            src_wrd_cnt_l <= src_wrd_cnt_d;
            -- if enough source data for a full size packet, do it
            if (src_wrd_cnt_gte_velo) then
              dst_wrd_cnt_u  <= velo_size;
              velo_size_left <= velo_size;
              nxt_state      <= set_vita_size;
            -- not enough source data, but forced packet size not set
            elsif (force_pkt_size = '0') then
              nxt_state      <= set_vita_size;
              if (src_wrd_cnt_lte_vita) then
                dst_wrd_cnt_u  <= vita_size;
                velo_size_left <= vita_size;
              else
                dst_wrd_cnt_u  <= src_wrd_cnt_l;    -- latched count
                velo_size_left <= src_wrd_cnt_l;
              end if;
            else
              -- not enough source data for a forced packet size
              nxt_state <= set_velo_size;
            end if;
          ----------------------------------------------------------------------
          when set_vita_size =>
            -- Is vita packet size same as payload left? or
            -- Is vita packet size less than payload left
            -- and there will be room enough for minimum vita pad?
            if (velo_lft_eq_vita or velo_lft_gte_vita_mn) then
              mvr_en_strb    <= '1';
              src_hdr_pulled <= '0';
              velo_size_left <= velo_size_left - vita_size;
              state          <= wait_vita_done;
            else
              pad_en_strb    <= '1';
              pad_pkt_size   <= std_logic_vector(
                                resize(unsigned(velo_size_left), 16));
              state          <= wait_pad_done;
            end if;
          ----------------------------------------------------------------------
          when wait_vita_done =>
            if (src_rd_done(0) = '1') then
              if (velo_size_left = 0) then
                state <= wait_dst_empty;
              else
                state <= nxt_hdr;
              end if;
            end if;
          ----------------------------------------------------------------------
          when wait_pad_done =>
            if (pad_done = '1') then
              state <= wait_dst_empty;
            end if;
          ----------------------------------------------------------------------
          when nxt_hdr =>
            nxt_state        <= set_vita_size;
            if (src_hdr_pulled = '1') then
              state          <= wait_comp;
            elsif (src_empty_d(0) = '0') then
              state          <= wait_hdr;
              src_hdr_rden   <= '1';
              src_hdr_pulled <= '1';
            end if;
          ----------------------------------------------------------------------
          when wait_dst_empty =>
            if (dst_empty_c = '1') then
              state <= idle;
            end if;
          ----------------------------------------------------------------------
          when others =>
            state <= idle;
          ----------------------------------------------------------------------
        end case;
      end if;
    end if;
  end process;

  vita_size     <= resize(unsigned(vita_hdr(15 downto 2)), 22);
  vita_size_min <= resize(unsigned(vita_hdr(15 downto 2)) + 3, 22);
  dst_wrd_cnt   <= std_logic_vector(dst_wrd_cnt_u);

  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      src_wrd_cnt_gte_velo <= (src_wrd_cnt_l >= velo_size);
      src_wrd_cnt_lte_vita <= (src_wrd_cnt_l <= vita_size);
      velo_lft_eq_vita     <= (velo_size_left = vita_size);
      velo_lft_gte_vita_mn <= (velo_size_left >= vita_size_min);
    end if;
  end process;

  mvr_inst : ii_vita_mover
  generic map (
    num_src_ch           => 1,
    log2_num_src_ch      => 1,
    num_dst_ch           => 16
  )
  port map (
    -- Reset and clock
    srst                 => srst,
    sys_clk              => sys_clk,

    -- Control and Status
    en_strb              => mvr_en_strb,
    src_ch_sel           => (others => '0'),
    src_ch_hdr           => vita_hdr,
    mvr_busy             => open,
    dst_wip              => open,
    src_rd_done          => src_rd_done,

    -- Source channels interface
    src_aempty           => src_aempty_d,
    src_empty            => src_empty_d,
    src_rden             => src_mvr_rden,
    src_vld              => src_vld_d,
    src_data             => src_data_d,

    -- Destination FIFOs interface
    dst_rdy              => dst_rdy,
    dst_wren             => mvr_dst_wren,
    dst_data             => mvr_dst_data
  );

  ------------------------------------------------------------------------------
  -- Construct VITA-49 header info

  pkt_hdr_0 <= "0001" &                 -- Packet Type (0001=Data packet)
               '1' &                    -- Class field included
               '1' &                    -- Trailer field included
               "00" &                   -- Reserved
               tsi &                    -- TSI (Integer-secs Timestamp type)
               tsf &                    -- TSF (Fractional-secs Timestamp type)
               pad_pkt_cnt &            -- Packet counter
               pad_pkt_size(13 downto 0) & "00"; -- Packet size in DWs
  pkt_hdr_1 <= stream_id;               -- Stream Id (PDN)
  pkt_hdr_2 <= (others => '0');         -- Class OUI
  pkt_hdr_3 <= x"000" & "00" &          -- Class Info
               eof &                    -- End of frame (user defined)
               sof &                    -- Start of frame (user defined)
               x"0000";                 -- Class Packet
  pkt_hdr_4 <= ts_int_secs;             -- Timestamp Integer-seconds
  pkt_hdr_5 <= ts_frc_secs(63 downto 32); -- Timestamp Fractional-seconds Hi
  pkt_hdr_6 <= ts_frc_secs(31 downto 0);  -- Timestamp Fractional-seconds Lo
  pkt_trailer <= X"00f00" & pad_bytes & X"00";

  -- Pad state machine
  -- It generates a valid VITA packet as filler
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        pad_state    <= idle;
        pad_dst_wren <= '0';
        pad_done     <= '0';
      else
        pad_dst_wren <= '0';
        pad_done     <= '0';
        case (pad_state) is
          ----------------------------------------------------------------------
          when idle =>
            if (pad_en_strb = '1') then
              pad_state         <= hdr1;
              pad_pkt_size_dcnt <= unsigned(pad_pkt_size);
            end if;
          ----------------------------------------------------------------------
          when hdr1 =>
            pad_state         <= hdr2;
            pad_dst_wren      <= '1';
            pad_dst_data      <= pkt_hdr_3 & pkt_hdr_2 & pkt_hdr_1 & pkt_hdr_0;
            pad_pkt_size_dcnt <= pad_pkt_size_dcnt - 1;
          ----------------------------------------------------------------------
          when hdr2 =>
            if (pad_pkt_size_dcnt > 2) then
              pad_state <= pyld;
            else
              pad_state <= trailer;
            end if;
            pad_dst_wren      <= '1';
            pad_dst_data      <= pkt_pyld & pkt_hdr_6 & pkt_hdr_5 & pkt_hdr_4;
            pad_pkt_size_dcnt <= pad_pkt_size_dcnt - 1;
          ----------------------------------------------------------------------
          when pyld =>
            if (dst_afull = '0') then
              if (pad_pkt_size_dcnt = 2) then
                pad_state <= trailer;
              end if;
              pad_dst_wren      <= '1';
              pad_dst_data      <= pkt_pyld & pkt_pyld & pkt_pyld & pkt_pyld;
              pad_pkt_size_dcnt <= pad_pkt_size_dcnt - 1;
            else
              pad_dst_wren <= '0';
            end if;
          ----------------------------------------------------------------------
          when trailer =>
            pad_state    <= idle;
            pad_dst_wren <= '1';
            pad_dst_data <= pkt_trailer & pkt_pyld & pkt_pyld & pkt_pyld;
            pad_done     <= '1';
          ----------------------------------------------------------------------
          when others =>
            pad_state <= idle;
          ----------------------------------------------------------------------
        end case;
      end if;
    end if;
  end process;

  -- Mux data from mover or padder into destination FIFO
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      dst_wren <= mvr_dst_wren or pad_dst_wren;
      if (mvr_dst_wren = '1') then
        dst_data <= mvr_dst_data;
      else
        dst_data <= pad_dst_data;
      end if;
    end if;
  end process;

  dst_fifo : sfifo_512x128_bram
  port map (
    clk                  => sys_clk,
    srst                 => fifo_rst,
    din                  => dst_data,
    wr_en                => dst_wren,
    rd_en                => dst_rden,
    dout                 => dst_dout_c,
    full                 => open,
    empty                => dst_empty_c,
    valid                => dst_vld_c,
    data_count           => open,
    prog_full            => dst_afull,
    prog_empty           => dst_aempty_c
  );

  dst_rdy <= (others => not dst_afull);

  -- Bypass control signals if enabled.
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (bypass_d = '0') then
        dst_empty  <= dst_empty_c;
        dst_aempty <= dst_aempty_c;
        dst_dout   <= dst_dout_c;
        dst_vld    <= dst_vld_c;
      else
        dst_empty  <= src_empty_d(0);
        dst_aempty <= src_aempty_d(0);
        dst_dout   <= src_data_d;
        dst_vld    <= src_vld_d(0);
      end if;
    end if;
  end process;

end arch;

