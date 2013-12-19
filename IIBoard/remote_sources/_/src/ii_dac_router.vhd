-- Copyright 2011 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_dac_router
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 13.3
--*
--*     @short DAC data and command packet router
--*
--* Description:
--*
--*   This component routes VITA-49 format packets received from the Velocia
--*   deframer to the various VFIFO_PB ports. Packets are routed based on the
--*   stream ID specified in the VITA-49 packet's header and the DAC's stream
--*   ID register. The destination ID is not used in this case to select the
--*   packet destination.
--*   VFIFO_PB command port packets are VITA deframed before being sent out.
--*   Each destination peripheral provides a fifo ready for data flow control.
--*
--*   @port srst            : input, synchronous active high reset
--*   @port sys_clk         : input, system clock
--*   @port dac0_stream_id  : input, DAC0 stream ID
--*   @port dac1_stream_id  : input, DAC1 stream ID
--*   @port dac_rtr_rdy     :output, DAC router is ready for data
--*   @port dac_rtr_wren    : input, DAC router data write strobe
--*   @port dac_rtr_data    : input, DAC router data
--*   @port dac0_pbcmd_rdy  : input, DAC0 playback command fifo is ready
--*   @port dac0_pbcmd_wren :output, DAC0 playback command fifo write strobe
--*   @port dac0_pbcmd_data :output, DAC0 playback command fifo data
--*   @port dac0_vfifo_rdy  : input, DAC0 vfifo is ready
--*   @port dac0_vfifo_wren :output, DAC0 vfifo write strobe
--*   @port dac0_vfifo_data :output, DAC0 vfifo data
--*   @port dac1_pbcmd_rdy  : input, DAC1 playback command fifo is ready
--*   @port dac1_pbcmd_wren :output, DAC1 playback command fifo write strobe
--*   @port dac1_pbcmd_data :output, DAC1 playback command fifo data
--*   @port dac1_vfifo_rdy  : input, DAC1 vfifo is ready
--*   @port dac1_vfifo_wren :output, DAC1 vfifo write strobe
--*   @port dac1_vfifo_data :output, DAC1 vfifo data
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 11/04/11
--*
--******************************************************************************
--/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_dac_router is
  port (
    -- Reset and clock
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;

    -- Routing configuration
    dac0_stream_id       : in  std_logic_vector(15 downto 0);
    dac1_stream_id       : in  std_logic_vector(15 downto 0);

    -- Data source interface
    dac_rtr_rdy          : out std_logic;
    dac_rtr_wren         : in  std_logic;
    dac_rtr_data         : in  std_logic_vector(127 downto 0);

    -- Destination channels interface
    dac0_pbcmd_rdy       : in  std_logic;
    dac0_pbcmd_wren      : out std_logic;
    dac0_pbcmd_data      : out std_logic_vector(127 downto 0);
    dac0_vfifo_rdy       : in  std_logic;
    dac0_vfifo_wren      : out std_logic;
    dac0_vfifo_data      : out std_logic_vector(127 downto 0);
    dac1_pbcmd_rdy       : in  std_logic;
    dac1_pbcmd_wren      : out std_logic;
    dac1_pbcmd_data      : out std_logic_vector(127 downto 0);
    dac1_vfifo_rdy       : in  std_logic;
    dac1_vfifo_wren      : out std_logic;
    dac1_vfifo_data      : out std_logic_vector(127 downto 0)
  );
end ii_dac_router;

architecture arch of ii_dac_router is

  component sfifo_512x128_bltin
    port (
      clk                  : in  std_logic;
      rst                  : in  std_logic;
      din                  : in  std_logic_vector(127 downto 0);
      wr_en                : in  std_logic;
      rd_en                : in  std_logic;
      dout                 : out std_logic_vector(127 downto 0);
      full                 : out std_logic;
      empty                : out std_logic;
      valid                : out std_logic;
      prog_full            : out std_logic;
      prog_empty           : out std_logic
    );
  end component;

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

  component sfifo_32x128_dist
    port (
      clk                  : in  std_logic;
      srst                 : in  std_logic;
      wr_en                : in  std_logic;
      rd_en                : in  std_logic;
      full                 : out std_logic;
      almost_full          : out std_logic;
      empty                : out std_logic;
      valid                : out std_logic;
      prog_full            : out std_logic;
      prog_empty           : out std_logic;
      din                  : in  std_logic_vector(127 downto 0);
      dout                 : out std_logic_vector(127 downto 0)
    );
  end component;

  component ii_vita_deframer
    port (
      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- Source interface
      src_aempty           : in  std_logic;
      src_empty            : in  std_logic;
      src_rden             : out std_logic;
      src_vld              : in  std_logic;
      src_din              : in  std_logic_vector(127 downto 0);

      -- Packet header info
      pkt_hdr_vld          : out std_logic;
      pkt_pyld_size        : out std_logic_vector(13 downto 0);
      pkt_idx              : out std_logic_vector(3 downto 0);
      pkt_tsi              : out std_logic_vector(1 downto 0);
      pkt_tsf              : out std_logic_vector(1 downto 0);
      pkt_stream_id        : out std_logic_vector(31 downto 0);
      pkt_ts_int_secs      : out std_logic_vector(31 downto 0);
      pkt_ts_frc_secs      : out std_logic_vector(63 downto 0);

      -- Destination interface
      dst_rdy              : in  std_logic;
      dst_frame            : out std_logic;
      dst_byte_vld         : out std_logic_vector(15 downto 0);
      dst_dout             : out std_logic_vector(127 downto 0)
    );
  end component;

  signal dac_rtr_rden         : std_logic;
  signal dac_rtr_dout         : std_logic_vector(127 downto 0);
  signal dac_rtr_empty        : std_logic;
  signal dac_rtr_vld          : std_logic;
  signal dac_rtr_afull        : std_logic;
  signal dac_rtr_aempty       : std_logic;
  signal dac_rtr_aempty_slv   : std_logic_vector(0 downto 0);
  signal dac_rtr_empty_slv    : std_logic_vector(0 downto 0);
  signal dac_rtr_vld_slv      : std_logic_vector(0 downto 0);

  type   sid_array is array (3 downto 0) of std_logic_vector(15 downto 0);
  signal stream_id_arr        : sid_array;
  type   state_type is (idle, rd_hdr, dec_hdr, wait_mvr);
  signal state                : state_type;
  signal hdr_rden             : std_logic;
  signal latched_hdr          : std_logic_vector(127 downto 0);
  alias  stream_id            : std_logic_vector(15 downto 0) is latched_hdr(47 downto 32);
  signal dest_id              : std_logic_vector(15 downto 0);
  signal mvr_en_strb          : std_logic;
  signal mvr_src_ch_hdr       : std_logic_vector(127 downto 0);
  signal mvr_src_rd_done      : std_logic_vector(0 downto 0);
  signal mvr_src_rden         : std_logic_vector(0 downto 0);
  signal mvr_dst_rdy          : std_logic_vector(3 downto 0);
  signal mvr_dst_wren         : std_logic;
  signal mvr_dst_data         : std_logic_vector(127 downto 0);

  signal dac0_cmdfifo_wren    : std_logic;
  signal dac0_cmdfifo_rden    : std_logic;
  signal dac0_cmdfifo_empty   : std_logic;
  signal dac0_cmdfifo_vld     : std_logic;
  signal dac0_cmdfifo_afull   : std_logic;
  signal dac0_cmdfifo_aempty  : std_logic;
  signal dac0_cmdfifo_dout    : std_logic_vector(127 downto 0);
  signal dac0_cmdfifo_rdy     : std_logic;
  signal dac1_cmdfifo_wren    : std_logic;
  signal dac1_cmdfifo_rden    : std_logic;
  signal dac1_cmdfifo_empty   : std_logic;
  signal dac1_cmdfifo_vld     : std_logic;
  signal dac1_cmdfifo_afull   : std_logic;
  signal dac1_cmdfifo_aempty  : std_logic;
  signal dac1_cmdfifo_dout    : std_logic_vector(127 downto 0);
  signal dac1_cmdfifo_rdy     : std_logic;
  signal dac0_pbcmd_byte_vld  : std_logic_vector(15 downto 0);
  signal dac1_pbcmd_byte_vld  : std_logic_vector(15 downto 0);

begin

--------------------------------------------------------------------------------
-- Instantiate sfifo_512x128_bltin to store the source data
--------------------------------------------------------------------------------
  dac_rtr_fifo : sfifo_512x128_bltin
  port map (
    clk                  => sys_clk,
    rst                  => srst,
    din                  => dac_rtr_data,
    wr_en                => dac_rtr_wren,
    rd_en                => dac_rtr_rden,
    dout                 => dac_rtr_dout,
    full                 => open,
    empty                => dac_rtr_empty,
    valid                => dac_rtr_vld,
    prog_full            => dac_rtr_afull,
    prog_empty           => dac_rtr_aempty
  );

  -- register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      dac_rtr_rdy <= not dac_rtr_afull;
    end if;
  end process;

  dac_rtr_aempty_slv(0) <= dac_rtr_aempty;
  dac_rtr_empty_slv(0)  <= dac_rtr_empty;
  dac_rtr_vld_slv(0)    <= dac_rtr_vld;

--------------------------------------------------------------------------------
-- Main state machine that reads a header from the input fifo, compares its
-- stream ID with the various channel's stream ID, sets the destination ID
-- accordingly, then triggers the mover to move that packet to the selected
-- destination.
--------------------------------------------------------------------------------
  -- Place the stream IDs in an array
  stream_id_arr <= (dac1_stream_id,
                    not dac1_stream_id(15) & dac1_stream_id(14 downto 0),
                    dac0_stream_id,
                    not dac0_stream_id(15) & dac0_stream_id(14 downto 0));

  process (sys_clk )
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        state       <= idle;
        hdr_rden    <= '0';
        latched_hdr <= (others => '0');
        dest_id     <= (others => '0');
        mvr_en_strb <= '0';
      else
        hdr_rden    <= '0';
        mvr_en_strb <= '0';
        case state is
          ----------------------------------------------------------------------
          when idle =>
            if (dac_rtr_empty = '0') then      -- a point is available
              state    <= rd_hdr;
              hdr_rden <= '1';
            else
              state    <= idle;
            end if;
            dest_id    <= (others => '0');
          ----------------------------------------------------------------------
          when rd_hdr =>                       -- latch the header
            if (dac_rtr_vld = '1') then
              state       <= dec_hdr;
              latched_hdr <= dac_rtr_dout;
            else
              state       <= rd_hdr;
            end if;
          ----------------------------------------------------------------------
          when dec_hdr =>
            state   <= wait_mvr;
            dest_id <= (others => '0');
            for i in 0 to 3 loop               -- lookup sid in sid array table
              if (stream_id = stream_id_arr(i)) then
                dest_id <= std_logic_vector(to_unsigned(2**i,16));
              end if;
            end loop;
            mvr_en_strb <= '1';
          ----------------------------------------------------------------------
          when wait_mvr =>                     -- wait for the mover
            if (mvr_src_rd_done(0) = '1') then
              state <= idle;
            else
              state <= wait_mvr;
            end if;
          ----------------------------------------------------------------------
          when others =>
            state <= idle;
          ----------------------------------------------------------------------
        end case;
      end if;
    end if;
  end process;

  dac_rtr_rden <= hdr_rden or mvr_src_rden(0);

--------------------------------------------------------------------------------
-- Instantiate ii_vita_mover to route the input packet into one of the selected
-- destinations.
--------------------------------------------------------------------------------
  mvr_src_ch_hdr <= latched_hdr(127 downto 64) & dest_id &
                    latched_hdr(47 downto 0);

  mvr_dst_rdy <= dac1_vfifo_rdy & dac1_cmdfifo_rdy &
                 dac0_vfifo_rdy & dac0_cmdfifo_rdy;

  inst_mvr : ii_vita_mover
  generic map (
    num_src_ch           => 1,
    log2_num_src_ch      => 1,
    num_dst_ch           => 4
  )
  port map (
    -- Reset and clock
    srst                 => srst,
    sys_clk              => sys_clk,

    -- Control and Status
    en_strb              => mvr_en_strb,
    src_ch_sel           => "0",
    src_ch_hdr           => mvr_src_ch_hdr,
    mvr_busy             => open,
    dst_wip              => open,
    src_rd_done          => mvr_src_rd_done,

    -- Source channels interface
    src_aempty           => dac_rtr_aempty_slv,
    src_empty            => dac_rtr_empty_slv,
    src_rden             => mvr_src_rden,
    src_vld              => dac_rtr_vld_slv,
    src_data             => dac_rtr_dout,

    -- Destination FIFOs interface
    dst_rdy              => mvr_dst_rdy,
    dst_wren             => mvr_dst_wren,
    dst_data             => mvr_dst_data
  );

  -- Demux and register the DAC0 & DAC1 data
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      dac0_vfifo_wren <= mvr_dst_wren and dest_id(1);
      dac0_vfifo_data <= mvr_dst_data;
      dac1_vfifo_wren <= mvr_dst_wren and dest_id(3);
      dac1_vfifo_data <= mvr_dst_data;
    end if;
  end process;

--------------------------------------------------------------------------------
-- Instantiate DAC0 and DAC1 command fifos to hold the VITA-49 packetized
-- playback commands.
--------------------------------------------------------------------------------

  dac0_cmdfifo_wren <= mvr_dst_wren and dest_id(0);
  dac1_cmdfifo_wren <= mvr_dst_wren and dest_id(2);

  inst_dac0_cmdfifo : sfifo_32x128_dist
  port map (
    clk                  => sys_clk,
    srst                 => srst,
    wr_en                => dac0_cmdfifo_wren,
    rd_en                => dac0_cmdfifo_rden,
    full                 => open,
    almost_full          => open,
    empty                => dac0_cmdfifo_empty,
    valid                => dac0_cmdfifo_vld,
    prog_full            => dac0_cmdfifo_afull,
    prog_empty           => dac0_cmdfifo_aempty,
    din                  => mvr_dst_data,
    dout                 => dac0_cmdfifo_dout
  );

  inst_dac1_cmdfifo : sfifo_32x128_dist
  port map (
    clk                  => sys_clk,
    srst                 => srst,
    wr_en                => dac1_cmdfifo_wren,
    rd_en                => dac1_cmdfifo_rden,
    full                 => open,
    almost_full          => open,
    empty                => dac1_cmdfifo_empty,
    valid                => dac1_cmdfifo_vld,
    prog_full            => dac1_cmdfifo_afull,
    prog_empty           => dac1_cmdfifo_aempty,
    din                  => mvr_dst_data,
    dout                 => dac1_cmdfifo_dout
  );

  -- register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      dac0_cmdfifo_rdy <= not dac0_cmdfifo_afull;
      dac1_cmdfifo_rdy <= not dac1_cmdfifo_afull;
    end if;
  end process;

--------------------------------------------------------------------------------
-- Instantiate ii_vita_deframer modules to read from the DAC's command fifos and
-- deframe the VITA-49 packetized playback commands.
--------------------------------------------------------------------------------
  inst_dac0_cmd_deframer : ii_vita_deframer
  port map (
    -- Reset and clock
    srst                 => srst,
    sys_clk              => sys_clk,

    -- Source interface
    src_aempty           => dac0_cmdfifo_aempty,
    src_empty            => dac0_cmdfifo_empty,
    src_rden             => dac0_cmdfifo_rden,
    src_vld              => dac0_cmdfifo_vld,
    src_din              => dac0_cmdfifo_dout,

    -- Packet header info
    pkt_hdr_vld          => open,
    pkt_pyld_size        => open,
    pkt_idx              => open,
    pkt_tsi              => open,
    pkt_tsf              => open,
    pkt_stream_id        => open,
    pkt_ts_int_secs      => open,
    pkt_ts_frc_secs      => open,

    -- Destination interface
    dst_rdy              => dac0_pbcmd_rdy,
    dst_frame            => open,
    dst_byte_vld         => dac0_pbcmd_byte_vld,
    dst_dout             => dac0_pbcmd_data
  );

  dac0_pbcmd_wren <= dac0_pbcmd_byte_vld(0);

  inst_dac1_cmd_deframer : ii_vita_deframer
  port map (
    -- Reset and clock
    srst                 => srst,
    sys_clk              => sys_clk,

    -- Source interface
    src_aempty           => dac1_cmdfifo_aempty,
    src_empty            => dac1_cmdfifo_empty,
    src_rden             => dac1_cmdfifo_rden,
    src_vld              => dac1_cmdfifo_vld,
    src_din              => dac1_cmdfifo_dout,

    -- Packet header info
    pkt_hdr_vld          => open,
    pkt_pyld_size        => open,
    pkt_idx              => open,
    pkt_tsi              => open,
    pkt_tsf              => open,
    pkt_stream_id        => open,
    pkt_ts_int_secs      => open,
    pkt_ts_frc_secs      => open,

    -- Destination interface
    dst_rdy              => dac1_pbcmd_rdy,
    dst_frame            => open,
    dst_byte_vld         => dac1_pbcmd_byte_vld,
    dst_dout             => dac1_pbcmd_data
  );

  dac1_pbcmd_wren <= dac1_pbcmd_byte_vld(0);

end arch;
