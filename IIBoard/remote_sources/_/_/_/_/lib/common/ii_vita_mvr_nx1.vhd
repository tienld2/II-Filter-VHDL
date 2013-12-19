-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design name: ii_vita_mvr_nx1
--*
--* @li Target Device: any
--* @li Tool versions: ISE 13.1
--*
--*     @short VITA-49 Packet Router
--*
--* Description:
--*
--*   This component moves VITA-49 format data packets, from num_src_ch
--*   source FIFOs into a local distributed FIFO regardless of what the
--*   destination ID is specified in the packet header.
--*   The component reads data from num_src_ch of data sources.
--*   The data width is 128; input and output are identical in size. The data
--*   sources provide data with valid after each src_rden().
--*   The input data is briefly stored in a 512 deep dual-quad-word FIFO
--*   waiting to be drained by external components.
--*
--*   @port srst            : input, synchronous active high reset
--*   @port sys_clk         : input, system clock
--*   @port src_aempty      : input, source channel fifo almost empty
--*   @port src_empty       : input, source channel fifo empty
--*   @port src_rden        :output, source channel fifo read enables
--*   @port src_vld         : input, source channel data is valid
--*   @port src_data        : input, source channel data
--*   @port dst_wrd_cnt     :output, destination fifo word count
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

entity ii_vita_mvr_nx1 is
  generic (
    num_src_ch           : integer := 4
  );
  port (
    -- Reset and clock
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;

    -- Source channels interface
    src_aempty           : in  std_logic_vector(num_src_ch-1 downto 0);
    src_empty            : in  std_logic_vector(num_src_ch-1 downto 0);
    src_rden             : out std_logic_vector(num_src_ch-1 downto 0);
    src_vld              : in  std_logic_vector(num_src_ch-1 downto 0);
    src_data             : in  std_logic_vector(128*num_src_ch-1 downto 0);

    -- Destination channels interface
    dst_wrd_cnt          : out std_logic_vector(8 downto 0);
    dst_aempty           : out std_logic;
    dst_empty            : out std_logic;
    dst_rden             : in  std_logic;
    dst_vld              : out std_logic;
    dst_dout             : out std_logic_vector(127 downto 0)
  );
end ii_vita_mvr_nx1;

architecture arch of ii_vita_mvr_nx1 is

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

  signal ch_update_sreg       : std_logic_vector(3 downto 0);
  signal ch_update            : std_logic;
  signal ch_sel_vld           : std_logic;
  signal ch_sel               : integer range 0 to num_src_ch-1;
  signal src_vld_d            : std_logic_vector(num_src_ch-1 downto 0);
  signal src_data_d           : std_logic_vector(128*num_src_ch-1 downto 0);
  signal fifo_rst             : std_logic;
  signal sel_ch_aempty        : std_logic;
  signal sel_ch_empty         : std_logic;
  signal sel_ch_vld           : std_logic;
  signal sel_ch_data          : std_logic_vector(127 downto 0);
  type   state_type is (idle, rd_hdr, wait_hdr, mv_pyld, wait_last_src_vld);
  signal state                : state_type;
  signal rem_pkt_dqwrds       : unsigned(13 downto 0);
  signal drip_dly_cnt         : unsigned(2 downto 0);
  signal sel_ch_rden          : std_logic;
  signal rem_data_vld_cnt     : unsigned(13 downto 0);
  signal dst_wren             : std_logic;
  signal dst_data             : std_logic_vector(127 downto 0);
  signal dst_afull            : std_logic;

begin

  -- Channel update pacing shift register and
  -- Source channel select counter
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or state /= idle) then
        ch_update_sreg <= "1000";
      else
        ch_update_sreg <= ch_update_sreg(2 downto 0) & ch_update_sreg(3);
      end if;
      if (ch_update = '1') then
        -- if we have examined the last channel then go back to channel 0
        if (ch_sel = num_src_ch-1) then
          ch_sel <= 0;
        else
          ch_sel <= ch_sel + 1;
        end if;
      end if;
    end if;
  end process;

  ch_update  <= ch_update_sreg(0);
  ch_sel_vld <= ch_update_sreg(2);

  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      src_vld_d  <= src_vld;
      src_data_d <= src_data;
      fifo_rst   <= srst;
    end if;
  end process;

  -- Mux to select the status and config parameter of
  -- one of the source channels specified by ch_sel
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      sel_ch_aempty <= src_aempty(ch_sel);
      sel_ch_empty  <= src_empty(ch_sel);
      sel_ch_vld    <= src_vld_d(ch_sel);
      sel_ch_data   <= src_data_d(127+128*ch_sel downto 128*ch_sel);
    end if;
  end process;

  -- State machine
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        state          <= idle;
        rem_pkt_dqwrds <= (others => '0');
        drip_dly_cnt   <= (others => '0');
        sel_ch_rden    <= '0';
      else
        sel_ch_rden <= '0';
        case state is
          ----------------------------------------------------------------------
          when idle =>
            if (ch_sel_vld = '1' and sel_ch_empty = '0') then
              state <= rd_hdr;
            else
              state <= idle;
            end if;
          ----------------------------------------------------------------------
          when rd_hdr =>
            if (dst_afull = '0') then
              state       <= wait_hdr;
              sel_ch_rden <= '1';
            else
              state       <= rd_hdr;
            end if;
          ----------------------------------------------------------------------
          when wait_hdr =>
            if (sel_ch_vld = '1') then
              state          <= mv_pyld;
              rem_pkt_dqwrds <= unsigned(sel_ch_data(15 downto 2)) - 1;
            else
              state          <= wait_hdr;
            end if;
          ----------------------------------------------------------------------
          when mv_pyld =>              -- Bleed and drip the source fifo
            if (dst_afull = '0' and sel_ch_empty = '0' and
                (sel_ch_aempty = '0' or drip_dly_cnt = "000")) then
              sel_ch_rden    <= '1';
              rem_pkt_dqwrds <= rem_pkt_dqwrds - 1;
              drip_dly_cnt   <= "111";
              if (rem_pkt_dqwrds = 1) then
                state <= wait_last_src_vld;
              end if;
            else
              if (drip_dly_cnt /= "000") then
                drip_dly_cnt <= drip_dly_cnt - 1;
              end if;
            end if;
          ----------------------------------------------------------------------
          when wait_last_src_vld =>    -- wait for the last src_vld
            if (rem_data_vld_cnt = to_unsigned(0,rem_data_vld_cnt'length)) then
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

  -- Demux sel_ch_rden to src_rden according to ch_sel
  gen_src_rden: for i in 0 to num_src_ch-1 generate
    process (sys_clk)
    begin
      for i in 0 to num_src_ch-1 loop
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

  -- MUX the selected channel data to the destination FIFO
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        dst_wren <= '0';
      else
        if (sel_ch_vld = '1') then
          if (state = wait_hdr) then
            rem_data_vld_cnt <= unsigned(sel_ch_data(15 downto 2)) - 1;
          else
            rem_data_vld_cnt <= rem_data_vld_cnt - 1;
          end if;
        end if;
        dst_wren <= sel_ch_vld;
        dst_data <= sel_ch_data;
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
    dout                 => dst_dout,
    full                 => open,
    empty                => dst_empty,
    valid                => dst_vld,
    data_count           => dst_wrd_cnt,
    prog_full            => dst_afull,
    prog_empty           => dst_aempty
  );

end arch;

