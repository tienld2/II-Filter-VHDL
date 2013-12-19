-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design name: ii_vita_router
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.1
--*
--*     @short VITA-49 Packet Router
--*
--* Description:
--*
--*   This component routes VITA-49 format data packets, from num_src_ch
--*   source FIFOs into up to num_dst_ch local distributed FIFOs as
--*   specified in the packet header.  If more than one destination is selected
--*   in the packet header, then the packet is moved only when both
--*   destinations are available and ready for data. This mode is known as
--*   “multi-cast” packet.
--*   The component reads data from num_src_ch of data sources.
--*   The data width is 128; input and output are identical in size. The data
--*   sources provide data with valid after each src_rden().
--*   The input data is briefly stored in 16 dual-quad-word deep FIFOs
--*   waiting to be drained by external components.
--*
--*   @port srst            : input, synchronous active high reset
--*   @port sys_clk         : input, system clock
--*   @port src_aempty      : input, source channel fifo almost empty
--*   @port src_empty       : input, source channel fifo empty
--*   @port src_rden        :output, source channel fifo read enables
--*   @port src_vld         : input, source channel data is valid
--*   @port src_data        : input, source channel data
--*   @port dst_rdy         : input, destination channel is ready
--*   @port dst_wren        :output, destination channel data write enable
--*   @port dst_data        :output, destination channel data
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date created 06/30/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity ii_vita_router is
  generic (
    num_src_ch           : integer := 4;
    num_dst_ch           : integer := 3
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
    dst_rdy              : in  std_logic_vector(num_dst_ch-1 downto 0);
    dst_wren             : out std_logic_vector(num_dst_ch-1 downto 0);
    dst_data             : out std_logic_vector(128*num_dst_ch-1 downto 0)
  );
end ii_vita_router;

architecture arch of ii_vita_router is

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

  function min(arg1,arg2: integer) return integer is
  begin
    if (arg1 < arg2) then
      return arg1;
    else
      return arg2;
    end if;
  end function min;

  function REDUCTION_NOR(A: in std_logic_vector) return std_logic is
    variable tmp : std_logic := '0';
  begin
    for i in A'range loop
      tmp := tmp or A(i);
    end loop;
    return not tmp;
  end function REDUCTION_NOR;

  function REDUCTION_AND(A: in std_logic_vector) return std_logic is
    variable tmp : std_logic := '1';
  begin
    for i in A'range loop
      tmp := tmp and A(i);
    end loop;
    return tmp;
  end function REDUCTION_AND;

  constant num_mvr            : integer := min(num_src_ch,num_dst_ch);
  constant log2_num_src_ch    : integer := integer(ceil(log2(real(num_src_ch))));
  constant all_zeros          : std_logic_vector(15 downto num_dst_ch) := (others => '0');

  type srcx128_t is array (num_src_ch-1 downto 0) of std_logic_vector(127 downto 0);
  type srcx16_t is array (num_src_ch-1 downto 0) of std_logic_vector(15 downto 0);
  type mvrxlog2_src_t is array (num_mvr-1 downto 0) of std_logic_vector(log2_num_src_ch-1 downto 0);
  type mvrx128_t is array (num_mvr-1 downto 0) of std_logic_vector(127 downto 0);
  type mvrxdst_t is array (num_mvr-1 downto 0) of std_logic_vector(num_dst_ch-1 downto 0);
  type mvrxsrc_t is array (num_mvr-1 downto 0) of std_logic_vector(num_src_ch-1 downto 0);
  type dstx128_t is array (num_dst_ch-1 downto 0) of std_logic_vector(127 downto 0);

  signal src_aempty_d         : std_logic_vector(num_src_ch-1 downto 0);
  signal src_empty_d          : std_logic_vector(num_src_ch-1 downto 0);
  signal src_vld_d            : std_logic_vector(num_src_ch-1 downto 0);
  signal src_data_d           : std_logic_vector(128*num_src_ch-1 downto 0);
  signal set_src_idle         : std_logic_vector(num_src_ch-1 downto 0);
  signal src_idle             : std_logic_vector(num_src_ch-1 downto 0);
  signal src_hdr_rden         : std_logic_vector(num_src_ch-1 downto 0);
  signal wait_src_hdr         : std_logic_vector(num_src_ch-1 downto 0);
  signal src_hdr_arr          : srcx128_t;
  signal src_hdr_dst_arr      : srcx16_t;
  signal sel_ch_dst_rdy       : std_logic;
  signal set_src_req          : std_logic_vector(num_src_ch-1 downto 0);
  signal src_req              : std_logic_vector(num_src_ch-1 downto 0);
  signal ch_update_sreg       : std_logic_vector(2 downto 0);
  signal ch_update            : std_logic;
  signal ch_sel_vld           : std_logic;
  signal ch_sel               : integer range 0 to num_src_ch-1;
  signal clr_src_req          : std_logic_vector(num_src_ch-1 downto 0);
  signal mvr_en_strb          : std_logic_vector(num_mvr-1 downto 0);
  signal mvr_src_ch_sel       : mvrxlog2_src_t;
  signal mvr_src_ch_hdr       : mvrx128_t;
  signal mvr_busy             : std_logic_vector(num_mvr-1 downto 0);
  signal dst_wip_arr          : mvrxdst_t;
  signal src_rd_done_arr      : mvrxsrc_t;
  signal src_rden_arr         : mvrxsrc_t;
  signal mvr_sel              : integer range 0 to num_mvr-1;
  signal dst_wip              : std_logic_vector(num_dst_ch-1 downto 0);
  signal src_rd_done          : std_logic_vector(num_src_ch-1 downto 0);
  signal src_rden_1b          : std_logic_vector(num_src_ch-1 downto 0);
  signal dst_rdy_d            : std_logic_vector(num_dst_ch-1 downto 0);
  signal mvr_dst_wren         : std_logic_vector(num_mvr-1 downto 0);
  signal mvr_dst_data_arr     : mvrx128_t;
  signal dst_data_arr         : dstx128_t;
  signal dst_wren_1b          : std_logic_vector(num_dst_ch-1 downto 0);
  signal dst_data_1b          : std_logic_vector(128*num_dst_ch-1 downto 0);

begin

  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      src_aempty_d <= src_aempty;
      src_empty_d  <= src_empty;
      src_vld_d    <= src_vld;
      src_data_d   <= src_data;
    end if;
  end process;

  gen_src_intf : for i in 0 to num_src_ch-1 generate
    -- When a source fifo indicates that it has gotton a data packet
    -- and when there is no already packets being read from the same
    -- source, this code reads the first header word, latches it, and
    -- asserts a request to the FSM.
    process (sys_clk)
    begin
      if (rising_edge(sys_clk)) then
        if (srst = '1') then
          set_src_idle(i) <= '0';
          src_idle(i)     <= '1';
          src_hdr_rden(i) <= '0';
          wait_src_hdr(i) <= '0';
          src_hdr_arr(i)  <= (others => '0');
          set_src_req(i)  <= '0';
          src_req(i)      <= '0';
        else
          src_hdr_rden(i) <= '0';
          if (src_idle(i) = '1' and src_empty_d(i) = '0') then
            src_idle(i)     <= '0';
            src_hdr_rden(i) <= '1';
          elsif (src_rd_done(i) = '1') then
            set_src_idle(i) <= '1';
          elsif (set_src_idle(i) = '1' and ch_sel_vld = '1' and ch_sel = i) then
            set_src_idle(i) <= '0';
            src_idle(i)     <= '1';
          end if;
          if (src_hdr_rden(i) = '1') then
            wait_src_hdr(i) <= '1';
          elsif (wait_src_hdr(i) = '1' and src_vld_d(i) = '1') then
            wait_src_hdr(i) <= '0';
            src_hdr_arr(i)  <= src_data_d((i+1)*128-1 downto i*128);
          end if;
          set_src_req(i) <= wait_src_hdr(i) and src_vld_d(i);
          if (set_src_req(i) = '1') then
            src_req(i) <= '1';
          elsif (clr_src_req(i) = '1') then
            src_req(i) <= '0';
          end if;
        end if;
      end if;
    end process;
  end generate;

  -- Find out each source channel packet destination(s).
  process (src_hdr_arr)
  begin
    for i in 0 to num_src_ch-1 loop
      src_hdr_dst_arr(i) <= src_hdr_arr(i)(63 downto 48);
    end loop;
  end process;

  -- Register dst_rdy to ease timing closure
  -- Check if the required destination fifos in the selected source header
  -- are in use by some mover and if they are ready for a new packet.
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      dst_rdy_d      <= dst_rdy;
      sel_ch_dst_rdy <= REDUCTION_NOR(src_hdr_dst_arr(ch_sel) and (all_zeros & dst_wip)) and
                        REDUCTION_NOR(src_hdr_dst_arr(ch_sel) and (all_zeros & not dst_rdy_d));
    end if;
  end process;

  -- Channel update pacing shift register and
  -- Source channel select counter
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        ch_update_sreg <= "100";
      else
        ch_update_sreg <= ch_update_sreg(1 downto 0) & ch_update_sreg(2);
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
  ch_sel_vld <= ch_update_sreg(2) and not srst;

  -- For each polled source channel, check for the following cases:
  --  1) Is there a request to move data from that source?
  --  2) Are all the required destinations idle?
  --  3) Is there a data mover available to transfer the packet?
  -- If all of these conditions are met, then command the first available
  -- mover to start moving data.
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (ch_sel_vld = '1' and src_req(ch_sel) = '1' and
         sel_ch_dst_rdy = '1' and REDUCTION_AND(mvr_busy) = '0') then
        clr_src_req(ch_sel)     <= '1';
        mvr_en_strb(mvr_sel)    <= '1';
        mvr_src_ch_sel(mvr_sel) <= std_logic_vector(to_unsigned(ch_sel,log2_num_src_ch));
        mvr_src_ch_hdr(mvr_sel) <= src_hdr_arr(ch_sel);
      else
        clr_src_req <= (others => '0');
        mvr_en_strb <= (others => '0');
      end if;
    end if;
  end process;

  gen_mvr_inst : for i in 0 to num_mvr-1 generate
    mvr_inst : ii_vita_mover
    generic map (
      num_src_ch           => num_src_ch,
      log2_num_src_ch      => log2_num_src_ch,
      num_dst_ch           => num_dst_ch
    )
    port map (
      -- Reset and clock
      srst                 => srst,
      sys_clk              => sys_clk,

      -- Control and Status
      en_strb              => mvr_en_strb(i),
      src_ch_sel           => mvr_src_ch_sel(i),
      src_ch_hdr           => mvr_src_ch_hdr(i),
      mvr_busy             => mvr_busy(i),
      dst_wip              => dst_wip_arr(i),
      src_rd_done          => src_rd_done_arr(i),

      -- Source channels interface
      src_aempty           => src_aempty_d,
      src_empty            => src_empty_d,
      src_rden             => src_rden_arr(i),
      src_vld              => src_vld_d,
      src_data             => src_data_d,

      -- Destination FIFOs interface
      dst_rdy              => dst_rdy_d,
      dst_wren             => mvr_dst_wren(i),
      dst_data             => mvr_dst_data_arr(i)
    );
  end generate;

  -- Find the first idle mover
  process (mvr_busy)
    variable mvr_sel_tmp : integer range 0 to num_mvr-1;
  begin
    mvr_sel_tmp := 0;
    for i in mvr_busy'range loop
      if (mvr_busy(i) = '0') then
        mvr_sel_tmp := i;
        exit;
      end if;
    end loop;
    mvr_sel <= mvr_sel_tmp;
  end process;

  -- OR all the mover status output arrays
  process (dst_wip_arr)
    variable dst_wip_tmp : std_logic_vector(num_dst_ch-1 downto 0);
  begin
    dst_wip_tmp := (others => '0');
    for i in 0 to num_mvr-1 loop
      dst_wip_tmp := dst_wip_tmp or dst_wip_arr(i);
    end loop;
    dst_wip <= dst_wip_tmp;
  end process;

  process (src_rd_done_arr)
    variable src_rd_done_tmp : std_logic_vector(num_src_ch-1 downto 0);
  begin
    src_rd_done_tmp := (others => '0');
    for i in 0 to num_mvr-1 loop
      src_rd_done_tmp := src_rd_done_tmp or src_rd_done_arr(i);
    end loop;
    src_rd_done <= src_rd_done_tmp;
  end process;

  -- OR all the mover src fifo read enables output arrays
  process (src_rden_arr)
    variable src_rden_tmp : std_logic_vector(num_src_ch-1 downto 0);
  begin
    src_rden_tmp := (others => '0');
    for i in 0 to num_mvr-1 loop
      src_rden_tmp := src_rden_tmp or src_rden_arr(i);
    end loop;
    src_rden_1b <= src_rden_tmp;
  end process;

  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        src_rden <= (others => '0');
      else
        src_rden <= src_rden_1b or src_hdr_rden;
      end if;
    end if;
  end process;

  gen_dst : for dst_idx in 0 to num_dst_ch-1 generate
    -- MUX the output of the mover into destination fifos.
    process (dst_wip_arr, mvr_dst_wren, mvr_dst_data_arr)
    begin
      dst_wren_1b(dst_idx)  <= '0';
      dst_data_arr(dst_idx) <= (others => '0');
      for mvr_idx in 0 to num_mvr-1 loop
        if (dst_wip_arr(mvr_idx)(dst_idx) = '1') then
          dst_wren_1b(dst_idx)  <= mvr_dst_wren(mvr_idx);
          dst_data_arr(dst_idx) <= mvr_dst_data_arr(mvr_idx);
          exit;
        end if;
      end loop;
    end process;

    process (dst_data_arr)
    begin
      dst_data_1b((dst_idx+1)*128-1 downto dst_idx*128) <= dst_data_arr(dst_idx);
    end process;
  end generate;

  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        dst_wren <= (others => '0');
      else
        dst_wren <= dst_wren_1b;
        dst_data <= dst_data_1b;
      end if;
    end if;
  end process;

end arch;

