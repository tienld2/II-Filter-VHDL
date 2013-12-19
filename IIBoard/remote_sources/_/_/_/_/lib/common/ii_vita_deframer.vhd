-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design name: ii_vita_deframer
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short VITA-49 Deframer
--*
--* Description:
--*
--*   This component strips off the VITA-49 packet header and trailer, and
--*   produces the framed payload data with a valid per byte on its output.
--*   Packet header info are also latched and produced to the output.
--*
--*   @port srst            : input, synchronous active high reset
--*   @port sys_clk         : input, system clock
--*   @port src_aempty      : input, source fifo almost empty
--*   @port src_empty       : input, source fifo empty
--*   @port src_rden        :output, source fifo read enables
--*   @port src_vld         : input, source data is valid
--*   @port src_din         : input, source data in
--*   @port pkt_hdr_vld     :output, packet header valid
--*   @port pkt_pyld_size   :output, payload size
--*   @port pkt_idx         :output, packet index
--*   @port pkt_tsi         :output, Timestamp integer-seconds type
--*   @port pkt_tsf         :output, Timestamp fractional-seconds type
--*   @port pkt_stream_id   :output, Unique stream identification
--*   @port pkt_ts_int_secs :output, Timestamp integer-seconds
--*   @port pkt_ts_frc_secs :output, Timestamp fractional-seconds
--*   @port dst_rdy         : input, destination is ready
--*   @port dst_frame       :output, destination data frame
--*   @port dst_byte_vld    :output, destination per byte data valid
--*   @port dst_dout        :output, destination data out
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 07/21/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_vita_deframer is
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
end ii_vita_deframer;

architecture arch of ii_vita_deframer is

  component ii_fifo_drainer
    port (
      srst                 : in  std_logic;
      clk                  : in  std_logic;
      ce                   : in  std_logic;
      src_empty            : in  std_logic;
      src_aempty           : in  std_logic;
      dest_rdy             : in  std_logic;
      src_rden             : out std_logic
    );
  end component;

  signal src_vld_d            : std_logic;
  signal src_din_d            : std_logic_vector(127 downto 0);
  signal src_din_dd           : std_logic_vector(127 downto 0);
  signal rem_pkt_dqwrds       : unsigned(13 downto 0);
  type   state_type is (idle, wait_hdr2, wait_pyld);
  signal state                : state_type;
  signal pkt_sof              : std_logic;
  signal pkt_eof              : std_logic;

begin

  src_drainer: ii_fifo_drainer
  port map (
    srst                 => srst,
    clk                  => sys_clk,
    ce                   => '1',
    src_empty            => src_empty,
    src_aempty           => src_aempty,
    dest_rdy             => dst_rdy,
    src_rden             => src_rden
  );

  -- Data pipe
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      src_vld_d <= src_vld;
      if (src_vld = '1') then
        src_din_d  <= src_din;
        src_din_dd <= src_din_d;
      end if;
      if (state = wait_pyld) then
        dst_dout <= src_din_d(95 downto 0) & src_din_dd(127 downto 96);
      else
        dst_dout <= (others => '0');
      end if;
    end if;
  end process;

  -- Deframer state machine
  process (sys_clk)
    variable pad_bytes  : std_logic_vector(3 downto 0);
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        pkt_hdr_vld     <= '0';
        pkt_pyld_size   <= (others => '0');
        pkt_idx         <= (others => '0');
        pkt_tsi         <= (others => '0');
        pkt_tsf         <= (others => '0');
        pkt_stream_id   <= (others => '0');
        pkt_sof         <= '0';
        pkt_eof         <= '0';
        pkt_ts_int_secs <= (others => '0');
        pkt_ts_frc_secs <= (others => '0');
        rem_pkt_dqwrds  <= (others => '0');
        state           <= idle;
        dst_frame       <= '0';
        dst_byte_vld    <= (others => '0');
      else
        dst_byte_vld    <= (others => '0');
        case state is
          ----------------------------------------------------------------------
          when idle =>
            if (src_vld_d = '1') then
              state          <= wait_hdr2;
              rem_pkt_dqwrds <= unsigned(src_din_d(15 downto 2)) - 1;
            end if;
            pkt_hdr_vld      <= '0';
            if (pkt_eof = '1') then
              dst_frame      <= '0';
            end if;
          ----------------------------------------------------------------------
          when wait_hdr2 =>
            if (src_vld_d = '1') then
              state           <= wait_pyld;
              rem_pkt_dqwrds  <= rem_pkt_dqwrds - 1;
              -- Latch packet header info
              pkt_hdr_vld     <= '1';
              pkt_pyld_size   <= std_logic_vector(rem_pkt_dqwrds - 1);
              pkt_idx         <= src_din_dd(19 downto 16);
              pkt_tsf         <= src_din_dd(21 downto 20);
              pkt_tsi         <= src_din_dd(23 downto 22);
              pkt_stream_id   <= src_din_dd(63 downto 32);
              pkt_sof         <= src_din_dd(112);
              pkt_eof         <= src_din_dd(113);
              pkt_ts_int_secs <= src_din_d(31 downto 0);
              pkt_ts_frc_secs <= (src_din_d(63 downto 32) &  -- Hi
                                  src_din_d(95 downto 64));  -- Lo
            end if;
          ----------------------------------------------------------------------
          when wait_pyld =>              -- Wait for payload data
            if (src_vld_d = '1') then
              rem_pkt_dqwrds <= rem_pkt_dqwrds - 1;
              if (pkt_sof = '1') then
                dst_frame    <= '1';
              end if;
              if (rem_pkt_dqwrds = 1) then
                state <= idle;
                pad_bytes := src_din_d(107 downto 104);
                case pad_bytes is
                  when "0000" => dst_byte_vld <= x"ffff";
                  when "0001" => dst_byte_vld <= x"7fff";
                  when "0010" => dst_byte_vld <= x"3fff";
                  when "0011" => dst_byte_vld <= x"1fff";
                  when "0100" => dst_byte_vld <= x"0fff";
                  when "0101" => dst_byte_vld <= x"07ff";
                  when "0110" => dst_byte_vld <= x"03ff";
                  when "0111" => dst_byte_vld <= x"01ff";
                  when "1000" => dst_byte_vld <= x"00ff";
                  when "1001" => dst_byte_vld <= x"007f";
                  when "1010" => dst_byte_vld <= x"003f";
                  when "1011" => dst_byte_vld <= x"001f";
                  when "1100" => dst_byte_vld <= x"000f";
                  when "1101" => dst_byte_vld <= x"0007";
                  when "1110" => dst_byte_vld <= x"0003";
                  when "1111" => dst_byte_vld <= x"0001";
                  when others => dst_byte_vld <= (others => '1');
                end case;
              else
                dst_byte_vld <= (others => '1');
              end if;
            end if;
          ----------------------------------------------------------------------
          when others =>
            state <= idle;
          ----------------------------------------------------------------------
        end case;
      end if;
    end if;
  end process;

end arch;

