-- Copyright 2011 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_trigger_pri
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 12.4
--*
--*     @short PRI trigger mode
--*
--* Description:
--*
--*   This component generates single clock cycle wide train of trigger pulses
--*   at repeated intervals defined by the (pri) input parameter once a rising
--*   edge is detected on the (trig_in) input until a stop is requested by the
--*   software. A start of frame (sof) signal is generated every (pri) number
--*   of clock cycles. Each output trigger pulse within a frame is generated
--*   after (trig_cycle_del) number of clock cycles from (sof).
--*   Since multiple and variable number of output triggers are needed per
--*   frame, their corresponding parameters (trig_cycle_del and trig_width) are
--*   loaded by the software and stored in a circular fifo. After a point is
--*   read from this fifo and used to generate a trigger pulse, the same point
--*   is written back into the fifo to be used during the next frame.
--*
--*
--*   @port srst               : input, synchronous active high reset
--*   @port clk                : input, clock
--*   @port en_pri_trig        : input, enable pri trigger mode
--*   @port trig_in            : input, external sync (trigger)
--*   @port stop_pri           : input, stop PRI triggering
--*   @port pri_busy           :output, PRI trigger is running
--*   @port pri                : input, PRI (pulse repetition interval)
--*   @port trig_fifo_rst      : input, reset the pri trigger parameters' fifo
--*   @port trig_fifo_wr       : input, write to the pri trigger parameters' fifo
--*   @port trig_cycle_del     : input, delay between the trigger and sof
--*   @port trig_width         : input, trigger width
--*   @port dig_trig_pls       :output, trigger pulse
--*   @port dig_trig_idx       :output, trigger index
--*   @port dig_trig_width     :output, trigger width
--*   @port pri_idx            :output, pri index
--*   @port pri_sof            :output, pri start-of-frame
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 1/31/11
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_trigger_pri is
  port (
    -- Reset and clock
    srst                 : in  std_logic;
    clk                  : in  std_logic;

    -- Controls
    en_pri_trig          : in  std_logic;
    trig_in              : in  std_logic;
    stop_pri             : in  std_logic;
    pri_busy             : out std_logic;
    pri                  : in  std_logic_vector(31 downto 0);

    -- Parameter FIFO interface
    trig_fifo_rst        : in  std_logic;
    trig_fifo_wr         : in  std_logic;
    trig_cycle_del       : in  std_logic_vector(23 downto 0);
    trig_width           : in  std_logic_vector(23 downto 0);

    -- Outputs
    dig_trig_pls         : out std_logic;
    dig_trig_idx         : out std_logic_vector(5 downto 0);
    dig_trig_width       : out std_logic_vector(23 downto 0);
    pri_idx              : out std_logic_vector(23 downto 0);
    pri_sof              : out std_logic
  );
end ii_trigger_pri;

architecture arch of ii_trigger_pri is

  component sfifo_32x48_ft
    port (
      clk                  : in  std_logic;
      rst                  : in  std_logic;
      din                  : in  std_logic_vector(47 downto 0);
      wr_en                : in  std_logic;
      rd_en                : in  std_logic;
      dout                 : out std_logic_vector(47 downto 0);
      full                 : out std_logic;
      empty                : out std_logic;
      valid                : out std_logic
    );
  end component;

  signal trig_in_d            : std_logic;
  signal trig_in_re           : std_logic;
  signal busy_int             : std_logic;
  signal frame_cnt            : unsigned(31 downto 0);
  signal sof                  : std_logic;
  signal gen_dig_trig         : std_logic;
  signal fifo_dout            : std_logic_vector(47 downto 0);
  signal fifo_empty           : std_logic;
  signal fifo_valid           : std_logic;
  signal fifo_rden            : std_logic;
  signal fifo_din             : std_logic_vector(47 downto 0);
  signal fifo_wren            : std_logic;
  type param_state_t is (idle, latch, wait_dig_trig);
  signal param_state          : param_state_t;
  signal param_rdy            : std_logic;
  signal store                : std_logic;
  signal curr_cycle_del       : std_logic_vector(23 downto 0);
  signal curr_width           : std_logic_vector(23 downto 0);
  signal nxt_trig_idx         : unsigned(5 downto 0);
  signal frame_idx            : unsigned(23 downto 0);


begin

  ---------------------------------------------------------------------------
  -- Detect a rising edge on trig_in
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        trig_in_d <= '0';
      else
        trig_in_d <= trig_in;
      end if;
    end if;
  end process;

  trig_in_re <= trig_in and not trig_in_d;

  -- Frame counter
  -- starts with a rising edge on trig_in when enabled, not busy,
  -- and no software stop requested.
  -- stops only at the end of a frame when a software stop is requested
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        busy_int <= '0';
      elsif (trig_in_re = '1' and param_rdy = '1' and
             stop_pri = '0' and busy_int = '0') then
        busy_int  <= '1';
        frame_cnt <= (others => '0');
      elsif (busy_int = '1') then
        if (frame_cnt = unsigned(pri)) then
          frame_cnt <= (others => '0');
          if (stop_pri = '1') then
            busy_int <= '0';
          end if;
        else
          frame_cnt <= frame_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  pri_busy <= busy_int;

  -- Generate a start of frame pulse on the first cycle of the frame counter
  -- whenever it's running
  sof <= '1' when (busy_int = '1' and frame_cnt = x"00000000") else
         '0';

  gen_dig_trig <= '1' when (frame_cnt = unsigned(X"00" & curr_cycle_del) and
                            busy_int = '1') else
                  '0';

  -- Generate an index that increments from 0 on each sof pulse
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        frame_idx <= (others => '1');
      elsif (sof = '1') then
        frame_idx <= frame_idx + 1;
      end if;
    end if;
  end process;

  pri_idx <= std_logic_vector(frame_idx);

  pri_sof <= sof;

  ---------------------------------------------------------------------------
  -- Parameters' fifo
  trig_fifo_inst : sfifo_32x48_ft
  port map (
    clk                  => clk,
    rst                  => trig_fifo_rst,
    din                  => fifo_din,
    wr_en                => fifo_wren,
    rd_en                => fifo_rden,
    dout                 => fifo_dout,
    full                 => open,
    empty                => fifo_empty,
    valid                => fifo_valid
  );

  ---------------------------------------------------------------------------
  -- Main state machine that controls the circular fifo
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (trig_fifo_rst = '1') then
        param_state <= idle;
        param_rdy   <= '0';
        fifo_rden   <= '0';
        store       <= '0';
      else
        fifo_rden   <= '0';
        store       <= '0';
        case (param_state) is
          when idle =>
            if (en_pri_trig = '1' and stop_pri = '0' and fifo_empty = '0') then
              param_state <= latch;
            else
              param_state <= idle;
            end if;
          when latch =>
            if (fifo_valid = '1') then
              param_state    <= wait_dig_trig;
              param_rdy      <= '1';
              fifo_rden      <= '1';
              store          <= '1';
              curr_cycle_del <= fifo_dout(23 downto 0);
              curr_width     <= fifo_dout(47 downto 24);
            else
              param_state    <= latch;
              param_rdy      <= '0';
            end if;
          when wait_dig_trig =>
            if (gen_dig_trig = '1') then
              param_state <= latch;
              param_rdy   <= '0';
            else
              param_state <= wait_dig_trig;
            end if;
          when others =>
            param_state <= idle;
        end case;
      end if;
    end if;
  end process;

  -- Select between the input or looped back parameters
  fifo_din  <= (trig_width & trig_cycle_del) when (trig_fifo_wr = '1') else
               (curr_width & curr_cycle_del);
  fifo_wren <= (trig_fifo_wr and not busy_int) or store;

  ---------------------------------------------------------------------------
  -- Calculate the next output trigger index
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (param_state = wait_dig_trig) then
        if (sof = '1' and gen_dig_trig = '1') then
          nxt_trig_idx <= "000001";
        elsif (sof = '1') then
          nxt_trig_idx <= "000000";
        elsif (gen_dig_trig = '1') then
          nxt_trig_idx   <= nxt_trig_idx + 1;
        end if;
      end if;
    end if;
  end process;

  -- Generate the output
  process (clk)
  begin
    if (rising_edge(clk)) then
      dig_trig_pls     <= gen_dig_trig;
      if (gen_dig_trig = '1') then
        dig_trig_width <= curr_width;
        if (sof = '1') then
          dig_trig_idx <= "000000";
        else
          dig_trig_idx <= std_logic_vector(nxt_trig_idx);
        end if;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------

end arch;
