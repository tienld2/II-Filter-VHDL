-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_vita_framer
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.x
--*
--*     @short VITA-49 Framer
--*
--* Description:
--*
--*   This module generates a VITA-49 compliant packet.
--*   It stacks the source data to 128-bit wide and writes it to the source
--*   FIFO, then reads data back from the source FIFO once a frame worth of
--*   points are available and generates the VITA-49 packets that are written
--*   to a destination FIFO.
--*
--*
--*   @port srst              : input, Synchronous active high reset
--*   @port sys_clk           : input, System clock
--*   @port fs_clk            : input, Sample clock
--*   @port frame_size        : input, Frame size in 32-bit words
--*   @port stream_id         : input, Unique stream identification (ie. PDN)
--*   @port packet_type       : input, VITA-49 packet type (4 bits)
--*   @port ts_int_secs       : input, Timestamp integer-seconds
--*   @port ts_frc_secs       : input, Timestamp fractional-seconds
--*   @port tsi               : input, Timestamp integer-seconds type
--*   @port tsf               : input, Timestamp fractional-seconds type
--*   @port din_frame         : input, frame data enable (on fs_clk)
--*   @port din_vld           : input, input data is valid
--*   @port din               : input, input data
--*   @port src_fifo_afull    : input, source FIFO is almost full
--*   @port src_fifo_wren     :output, Write enable to source FIFO (stacked)
--*   @port src_fifo_din      :output, Write data to source FIFO (stacked)
--*   @port src_fifo_empty    : input, Source FIFO empty flag
--*   @port src_fifo_rden     :output, Read enable to source FIFO
--*   @port src_fifo_vld      : input, Data valid from source FIFO
--*   @port src_fifo_dout     : input, Data from source FIFO
--*   @port dst_fifo_empty    :output, Destination FIFO empty flag
--*   @port dst_fifo_aempty   :output, Destination FIFO almost empty flag
--*   @port dst_fifo_rden     : input, Destination FIFO read enable
--*   @port dst_fifo_vld      :output, Destination FIFO valid data output
--*   @port dst_fifo_dout     :output, Destination FIFO data output
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date Created 6/24/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ii_vita_framer is
  generic (
    ibw                  : integer := 8
  );
  port (
    -- Reset and clocks
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;
    fs_clk               : in  std_logic;

    -- Controls
    frame_size           : in  std_logic_vector(15 downto 0);
    stream_id            : in  std_logic_vector(31 downto 0);
    packet_type          : in  std_logic_vector(3 downto 0);

    -- VITA-49 Timestamp interface
    ts_int_secs          : in  std_logic_vector(31 downto 0);
    ts_frc_secs          : in  std_logic_vector(63 downto 0);
    tsi                  : in  std_logic_vector(1 downto 0);
    tsf                  : in  std_logic_vector(1 downto 0);

    -- Data source interface
    din_frame            : in  std_logic;
    din_vld              : in  std_logic;
    din                  : in  std_logic_vector(ibw-1 downto 0);

    -- Data source FIFO interface
    src_fifo_afull       : in  std_logic;
    src_fifo_wren        : out std_logic;
    src_fifo_din         : out std_logic_vector(127 downto 0);
    src_fifo_empty       : in  std_logic;
    src_fifo_rden        : out std_logic;
    src_fifo_vld         : in  std_logic;
    src_fifo_dout        : in  std_logic_vector(127 downto 0);

    -- VITA-49 FIFO interface
    dst_fifo_empty       : out std_logic;
    dst_fifo_aempty      : out std_logic;
    dst_fifo_rden        : in  std_logic;
    dst_fifo_vld         : out std_logic;
    dst_fifo_dout        : out std_logic_vector(127 downto 0)
  );
end ii_vita_framer;

architecture arch of ii_vita_framer is

  component ii_stacker_128
    generic (
      ibw                  : integer;
      obw                  : integer
    );
    port (
      srst                 : in  std_logic;
      clk                  : in  std_logic;
      frame                : in  std_logic;
      din_vld              : in  std_logic;
      din                  : in  std_logic_vector(ibw-1 downto 0);
      dout_vld             : out std_logic;
      dout                 : out std_logic_vector(obw-1 downto 0);
      pad_bytes            : out std_logic_vector(3 downto 0)
    );
  end component;

  component afifo_256x128
    port (
      rst                  : in  std_logic;
      wr_clk               : in  std_logic;
      rd_clk               : in  std_logic;
      din                  : in  std_logic_vector(127 downto 0);
      wr_en                : in  std_logic;
      rd_en                : in  std_logic;
      dout                 : out std_logic_vector(127 downto 0);
      full                 : out std_logic;
      empty                : out std_logic;
      valid                : out std_logic
    );
  end component;

  component sfifo_512x128_bltin
    port (
      valid                : out std_logic;
      rd_en                : in  std_logic := 'X';
      prog_full            : out std_logic;
      wr_en                : in  std_logic := 'X';
      full                 : out std_logic;
      empty                : out std_logic;
      clk                  : in  std_logic := 'X';
      rst                  : in  std_logic := 'X';
      prog_empty           : out std_logic;
      dout                 : out std_logic_vector(127 downto 0);
      din                  : in  std_logic_vector(127 downto 0)
    );
  end component;

  constant obw                : integer := 128;
  signal fs_rst_sreg          : std_logic_vector(7 downto 0);
  signal fs_rst               : std_logic;
  signal din_vld_mskd         : std_logic;
  signal src_fifo_wren_int    : std_logic;
  signal pad_bytes            : std_logic_vector(3 downto 0);
  signal frame_d              : std_logic;
  signal frame_re             : std_logic;
  signal frame_fe             : std_logic;
  signal pyld_size_dw         : unsigned(15 downto 0); -- payload size in 32-bit
  signal pyld_size_dqw        : unsigned(13 downto 0); -- payload size in 128-bit
  signal sof_l                : std_logic;
  signal eof                  : std_logic;
  signal ts_int_secs_l_1b     : std_logic_vector(31 downto 0);
  signal ts_frc_secs_l_1b     : std_logic_vector(63 downto 0);
  signal ts_int_secs_l        : std_logic_vector(31 downto 0);
  signal ts_frc_secs_l        : std_logic_vector(63 downto 0);
  signal pad_bytes_l          : std_logic_vector(3 downto 0);
  signal pkt_complete         : std_logic;
  signal pnt_cnt              : unsigned(13 downto 0);
  signal pnt_cnt_l            : unsigned(13 downto 0);
  signal hdr_wren             : std_logic;
  signal hdr_rden             : std_logic;
  signal hdr_empty            : std_logic;
  signal hdr_valid            : std_logic;
  signal hdr_din              : std_logic_vector(127 downto 0);
  signal hdr_dout             : std_logic_vector(127 downto 0);
  alias  hdr_pad_bytes        : std_logic_vector(3 downto 0) is hdr_dout(127 downto 124);
  alias  hdr_eof              : std_logic is hdr_dout(111);
  alias  hdr_sof              : std_logic is hdr_dout(110);
  alias  hdr_pyl_size         : std_logic_vector(13 downto 0) is hdr_dout(109 downto 96);
  alias  hdr_int_secs         : std_logic_vector(31 downto 0) is hdr_dout(95 downto 64);
  alias  hdr_frc_secs_hi      : std_logic_vector(31 downto 0) is hdr_dout(63 downto 32);
  alias  hdr_frc_secs_lo      : std_logic_vector(31 downto 0) is hdr_dout(31 downto 0);
  signal pkt_size             : std_logic_vector(15 downto 0);
  type   state_t is (idle, hdr1, hdr2, payload, wait_last_src_vld, trailer);
  signal state                : state_t;
  signal pkt_cnt              : unsigned(3 downto 0);
  signal pkt_cnt_slv          : std_logic_vector(3 downto 0);
  signal pkt_hdr_0            : std_logic_vector(31 downto 0);
  signal pkt_hdr_1            : std_logic_vector(31 downto 0);
  signal pkt_hdr_2            : std_logic_vector(31 downto 0);
  signal pkt_hdr_3            : std_logic_vector(31 downto 0);
  signal pkt_hdr_4            : std_logic_vector(31 downto 0);
  signal pkt_hdr_5            : std_logic_vector(31 downto 0);
  signal pkt_hdr_6            : std_logic_vector(31 downto 0);
  signal pkt_trailer          : std_logic_vector(31 downto 0);
  signal payload_0            : std_logic_vector(31 downto 0);
  signal payload_3_1_d        : std_logic_vector(95 downto 0);
  signal rem_pnt_dqw          : unsigned(13 downto 0);
  signal rem_data_vld_cnt     : unsigned(13 downto 0);
  signal dst_fifo_afull       : std_logic;
  signal dst_fifo_afull_d     : std_logic;
  signal dst_fifo_wren        : std_logic;
  signal dst_fifo_din         : std_logic_vector(127 downto 0) := (others => '0');

begin

  ------------------------------------------------------------------------------
  -- Synchronize srst to fs_clk domain
  ------------------------------------------------------------------------------
  process (srst, fs_clk)
  begin
    if (srst = '1') then
      fs_rst_sreg <= (others => '1');
    elsif (rising_edge(fs_clk)) then
      fs_rst_sreg <= fs_rst_sreg(fs_rst_sreg'high-1 downto 0) & '0';
    end if;
  end process;

  fs_rst <= fs_rst_sreg(fs_rst_sreg'high);

  ------------------------------------------------------------------------------
  -- Instantiate the data stacker
  ------------------------------------------------------------------------------
  din_vld_mskd <= din_vld and not src_fifo_afull;

  stacker : ii_stacker_128
  generic map (
    ibw                  => ibw,
    obw                  => obw
  )
  port map (
    srst                 => fs_rst,
    clk                  => fs_clk,
    frame                => din_frame,
    din_vld              => din_vld_mskd,
    din                  => din,
    dout_vld             => src_fifo_wren_int,
    dout                 => src_fifo_din,
    pad_bytes            => pad_bytes
  );

  src_fifo_wren <= src_fifo_wren_int;

  ------------------------------------------------------------------------------
  -- Keeping track of framed samples
  ------------------------------------------------------------------------------
  -- Calculate payload size based on frame_size in 32-bit words
  -- minus 7 for the header, minus 1 for the trailer
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      pyld_size_dw <= unsigned(frame_size) - 8;
    end if;
  end process;

  -- Payload size in double-quad-words (128-bit)
  pyld_size_dqw <= pyld_size_dw(pyld_size_dw'high downto 2);  -- div by 4

  ------------------------------------------------------------------------------
  -- Use din_frame posedge to latch timestamp value
  process (fs_clk)
  begin
    if (rising_edge(fs_clk)) then
      frame_d <= din_frame;
    end if;
  end process;

  frame_re <= din_frame and not frame_d;
  frame_fe <= not din_frame and frame_d;

  -- Latch timestamp when din_frame posedge or when a new packet starts
  process (fs_clk)
  begin
    if (rising_edge(fs_clk)) then
      if (frame_re = '1' or
      (src_fifo_wren_int = '1' and pnt_cnt = pyld_size_dqw)) then
        ts_int_secs_l_1b <= ts_int_secs;
        ts_frc_secs_l_1b <= ts_frc_secs;
      end if;
      if (src_fifo_wren_int = '1') then
        ts_int_secs_l <= ts_int_secs_l_1b;
        ts_frc_secs_l <= ts_frc_secs_l_1b;
      end if;
    end if;
  end process;

  -- Latch sof high on the rising edge of din_frame and
  -- reset to 0 when the header info is written to the header fifo
  process (fs_clk)
  begin
    if (rising_edge(fs_clk)) then
      if (fs_rst = '1') then
        sof_l <= '0';
      elsif (frame_re = '1') then
        sof_l <= '1';
      elsif (pkt_complete = '1') then
        sof_l <= '0';
      end if;
    end if;
  end process;

  -- Count the number of (128-bit) points that need to be read from data FIFO
  -- Signal packet complete when the point count reaches the frame size
  -- and make it a partial packet if din_frame deasserts
  process (fs_clk)
  begin
    if (rising_edge(fs_clk)) then
      if (fs_rst = '1') then
        pnt_cnt      <= to_unsigned(1, pnt_cnt'length);
        pkt_complete <= '0';
        eof          <= '0';
      else
        pkt_complete <= '0';
        eof          <= '0';
        if (src_fifo_wren_int = '1') then
          if (pnt_cnt = pyld_size_dqw or  -- complete packet done
              din_frame = '0') then       -- partial packet done
            pnt_cnt      <= to_unsigned(1, pnt_cnt'length);
            pkt_complete <= '1';
            -- Latch padding & pnt_cnt in case it's last point of packet
            pad_bytes_l <= pad_bytes;
            pnt_cnt_l   <= pnt_cnt;
            eof         <= not din_frame;
          else
            pnt_cnt <= pnt_cnt + 1;
          end if;
        elsif (frame_fe = '1') then       -- when not aligned with src_fifo_wren
          pnt_cnt      <= to_unsigned(1, pnt_cnt'length);
          pkt_complete <= '1';
          -- Latch padding & decrement pnt_cnt then latch it in case the din_frame deasserts
          pad_bytes_l <= pad_bytes;
          pnt_cnt_l   <= pnt_cnt - 1;
          eof         <= not din_frame;
        end if;
      end if;
    end if;
  end process;

  -- When packet is complete, store packet info into header FIFO
  hdr_wren <= pkt_complete;

  hdr_din <= pad_bytes_l &                  -- 127:124
             X"000" &                       -- 123:112
             eof &                          -- 111
             sof_l &                        -- 110
             std_logic_vector(pnt_cnt_l) &  -- 109:96
             ts_int_secs_l &                -- 95:64
             ts_frc_secs_l;                 -- 63:0

  -- FIFO holding header information for subpackets
  hdr_fifo : afifo_256x128
  port map (
    rst                  => srst,
    wr_clk               => fs_clk,
    rd_clk               => sys_clk,
    din                  => hdr_din,
    wr_en                => hdr_wren,
    rd_en                => hdr_rden,
    dout                 => hdr_dout,
    full                 => open,
    empty                => hdr_empty,
    valid                => hdr_valid
  );

  ------------------------------------------------------------------------------
  -- State Machine
  ------------------------------------------------------------------------------
  -- This FSM pulls a point at a time from the header FIFO,
  -- it parses it and construct a packet header based on this info.
  -- Then drains a number of points from the data FIFO to form the payload
  -- of a VITA packet, to be stored in the Packet FIFO
  ------------------------------------------------------------------------------
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        state         <= idle;
        pkt_cnt       <= to_unsigned(0, pkt_cnt'length);
        hdr_rden      <= '0';
        src_fifo_rden <= '0';
        dst_fifo_wren <= '0';
      else
        hdr_rden      <= '0';
        src_fifo_rden <= '0';
        dst_fifo_wren <= '0';
        case state is
          ------------------------------------------------------------
          when idle =>
            if (hdr_empty = '0' and dst_fifo_afull_d = '0' and
            src_fifo_empty = '0') then
              state    <= hdr1;
              hdr_rden <= '1';
            end if;
          ------------------------------------------------------------
          when hdr1 =>
            if (hdr_valid = '1') then
              state         <= hdr2;
              src_fifo_rden <= '1';       -- Prefetch first data point
              rem_pnt_dqw   <= unsigned(hdr_pyl_size) - 1; -- Payload size
              dst_fifo_wren <= '1';
              dst_fifo_din  <= pkt_hdr_3 & pkt_hdr_2 & pkt_hdr_1 & pkt_hdr_0;
            end if;
          ------------------------------------------------------------
          when hdr2 =>
            if (src_fifo_vld = '1') then
              state         <= payload;
              dst_fifo_wren <= '1';
              dst_fifo_din  <= payload_0 & pkt_hdr_6 & pkt_hdr_5 & pkt_hdr_4;
            end if;
          ------------------------------------------------------------
          when payload =>                 -- Bleed the source fifo
            if (rem_pnt_dqw = 0) then
              state <= trailer;
            elsif (dst_fifo_afull_d = '0') then
              src_fifo_rden <= '1';
              rem_pnt_dqw   <= rem_pnt_dqw - 1;
              if (rem_pnt_dqw = 1) then
                state <= wait_last_src_vld;
              end if;
            else
              src_fifo_rden <= '0';
            end if;
            dst_fifo_wren <= src_fifo_vld;
            dst_fifo_din  <= payload_0 & payload_3_1_d;
          ------------------------------------------------------------
          when wait_last_src_vld =>       -- Wait for the last src_data_vld
            if (rem_data_vld_cnt = 1 and src_fifo_vld = '1') then
              state <= trailer;
            end if;
            dst_fifo_wren <= src_fifo_vld;
            dst_fifo_din  <= payload_0 & payload_3_1_d;
          ------------------------------------------------------------
          when trailer =>
            state         <= idle;
            pkt_cnt       <= pkt_cnt + 1;
            dst_fifo_wren <= '1';
            dst_fifo_din  <= pkt_trailer & payload_3_1_d;
          ------------------------------------------------------------
          when others =>
            state <= idle;
        end case;
      end if;
    end if;
  end process;

  -- Keep track of source FIFO valid points read
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (hdr_valid = '1') then
        rem_data_vld_cnt <= unsigned(hdr_pyl_size); -- Packet size
      elsif (src_fifo_vld = '1') then
        rem_data_vld_cnt <= rem_data_vld_cnt - 1;
      end if;
    end if;
  end process;

  -- Handle 32-bit word stacking into destination FIFO
  -- Register 3 most significant words (3 to 1) to handle stacking
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (src_fifo_vld = '1') then
        payload_3_1_d <= src_fifo_dout(127 downto 32);
      end if;
    end if;
  end process;

  -- Word 0 comes straight from FIFO output
  payload_0 <= src_fifo_dout(31 downto 0);

  ------------------------------------------------------------------------------
  -- Construct VITA-49 header info
  pkt_size    <= std_logic_vector(unsigned(hdr_pyl_size & "00") + 8);
  pkt_cnt_slv <= std_logic_vector(pkt_cnt);

  pkt_hdr_0 <= "0001" &                 -- Packet Type (0001=Data packet)
               '1' &                    -- Class field included
               '1' &                    -- Trailer field included
               "00" &                   -- Reserved
               tsi &                    -- TSI (Integer-secs Timestamp type)
               tsf &                    -- TSF (Fractional-secs Timestamp type)
               pkt_cnt_slv &            -- Packet counter
               pkt_size;                -- Packet size
  pkt_hdr_1 <= stream_id;               -- Stream Id (PDN)
  pkt_hdr_2 <= (others => '0');         -- Class OUI
  pkt_hdr_3 <= x"000" & "00" &          -- Class Info
               hdr_eof &                -- End of frame (user defined)
               hdr_sof &                -- Start of frame (user defined)
               x"0000";                 -- Class Packet
  pkt_hdr_4 <= hdr_int_secs;            -- Timestamp Integer-seconds
  pkt_hdr_5 <= hdr_frc_secs_hi;         -- Timestamp Fractional-seconds Hi
  pkt_hdr_6 <= hdr_frc_secs_lo;         -- Timestamp Fractional-seconds Lo
  pkt_trailer <= X"00f00" & hdr_pad_bytes & X"00";

  -- Destination FIFO: it holds VITA-49 data packets
  dst_fifo: sfifo_512x128_bltin
  port map (
    valid                => dst_fifo_vld,
    rd_en                => dst_fifo_rden,
    prog_full            => dst_fifo_afull,
    wr_en                => dst_fifo_wren,
    full                 => open,
    empty                => dst_fifo_empty,
    clk                  => sys_clk,
    rst                  => srst,
    prog_empty           => dst_fifo_aempty,
    dout                 => dst_fifo_dout,
    din                  => dst_fifo_din
  );

  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      dst_fifo_afull_d <= dst_fifo_afull;
    end if;
  end process;

end arch;

