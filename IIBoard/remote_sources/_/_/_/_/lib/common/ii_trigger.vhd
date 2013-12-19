-- Copyright 2007-2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_trigger
--*
--* @li Target Device: any
--* @li Tool versions: ISE 12.3
--*
--*     @short Trigger control
--*
--* Description:
--*
--*   This component provides a trigger for data capture.  Two trigger modes are
--*   supported : unframed and framed.  In unframed mode, the trigger output is
--*   true whenever the selected trigger source is true. In framed mode, the
--*   trigger output is true after a rising edge on the selected trigger source
--*   until the frame count number of sample clocks are counted. A point is
--*   counted on each rising edge of the sample clock input.
--*   The trigger mode is selected with trig_mode input to be either framed or
--*   unframed, software or external trigger, positive edge or level.
--*   The trigger sources are either external or software. The external trigger
--*   must be enabled to be used, however, the software trigger is always OR'd
--*   with the external trigger to allow it to be used anytime.
--*   In unframed mode, the mode can be positive edge or level. In the positive
--*   edge mode, the source trigger posedge enables the output, ignoring any
--*   subsequent changes. In Level mode, the output follows the source trigger.
--*
--*
--*   @generic SAMPLES_PER_CLK: integer, Parallel samples per sample clock
--*   @port reset           : input, async reset, active high
--*   @port clk             : input, sample clock
--*   @port ce              : input, chip en
--*   @port ext_sync        : input, external sync (trigger) input
--*   @port sw_trig         : input, software trigger input
--*   @port trig_mode       : input, select the trigger mode
--*                                  bit 0: 1 = posedge,  0 = level
--*                                  bit 1: 1 = framed,   0 = unframed
--*                                  bit 2: 1 = external, 0 = SW trigger
--*   @port frame_size      : input, number of points in a frame count
--*   @port decimation_coeff: input, number of gaps between output triggers
--*   @port decimation_en   :output, set when (decimation_coeff /= 0)
--*   @port trigger         :output, trigger
--*   @port trigger_en      :output, trigger window is enabled
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 6/22/06
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity ii_trigger is
  generic (
    SAMPLES_PER_CLK      : integer := 1
  );
  port (
    reset                : in  std_logic;
    clk                  : in  std_logic;
    ce                   : in  std_logic;
    ext_sync             : in  std_logic;
    sw_trig              : in  std_logic;
    trig_mode            : in  std_logic_vector(2 downto 0);
    frame_size           : in  std_logic_vector(23 downto 0);
    decimation_coeff     : in  std_logic_vector(11 downto 0);
    decimation_en        : out std_logic;
    trigger              : out std_logic;
    trigger_en           : out std_logic
  );
end ii_trigger;

architecture arch of ii_trigger is

  signal posedge_mode         : std_logic;
  signal framed_mode          : std_logic;
  signal ext_mode             : std_logic;
  signal ce_xdom              : std_logic;
  signal ce_demet             : std_logic;
  signal sw_trig_xdom         : std_logic;
  signal sw_trig_demet        : std_logic;
  signal trig_in              : std_logic;
  signal trig_in_d            : std_logic;
  signal trig_in_re           : std_logic;
  signal trigger_en_1b        : std_logic;
  signal decimation_en_int    : std_logic;
  signal scaled_dec_coeff     : unsigned(11 downto 0);
  signal decimation_cnt       : unsigned(11 downto 0);
  signal max_decimation_cnt   : std_logic;
  signal set_trigger          : std_logic;
  signal frame_cnt            : unsigned(23 downto 0);
  signal last_sample          : std_logic;
  signal turn_off_strb        : std_logic;

begin

  posedge_mode <= trig_mode(0);
  framed_mode  <= trig_mode(1);
  ext_mode     <= trig_mode(2);

  -- Sync signals to local clock
  process(clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1') then
        ce_xdom       <= '0';
        ce_demet      <= '0';
        sw_trig_xdom  <= '0';
        sw_trig_demet <= '0';
      else
        ce_xdom       <= ce;
        ce_demet      <= ce_xdom;
        sw_trig_xdom  <= sw_trig;
        sw_trig_demet <= sw_trig_xdom;
      end if;
    end if;
  end process;

  -- Select external or sw trigger
  trig_in <= ((ext_sync and ext_mode) or sw_trig_demet) and ce_demet;

  process (clk)
  begin
    if (rising_edge(clk)) then
      trig_in_d <= trig_in;
    end if;
  end process;

  -- Detect a rising edge on the selected input trigger when not already
  -- triggered
  trig_in_re <= not trig_in_d and trig_in and not trigger_en_1b;

  -- Generate the trigger enabled window
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1' or ce_demet = '0') then
        trigger_en_1b <= '0';
      else
        -- enable the output in both framed and unframed modes
        if (trig_in_re = '1') then
          trigger_en_1b <= '1';
        elsif (framed_mode = '0' and trigger_en_1b = '1' and
               posedge_mode = '0' and max_decimation_cnt = '1') then
          -- unframed mode, level -> follow input only on decimation boundaries
          trigger_en_1b <= trig_in;
        elsif (framed_mode = '1' and turn_off_strb = '1') then  -- framed mode
          trigger_en_1b <= '0';
        end if;
      end if;
    end if;
  end process;

--------------------------------------------------------------------------------
-- Logic to generate the set_trigger signal
--------------------------------------------------------------------------------
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (decimation_coeff = x"000") then
        decimation_en_int <= '0';
      else
        decimation_en_int <= '1';
      end if;
    end if;
  end process;

  decimation_en <= decimation_en_int;

  -- count sample sets for decimation
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1' or max_decimation_cnt = '1' or trigger_en_1b = '0') then
        decimation_cnt <= (others => '0');
      else
        decimation_cnt <= decimation_cnt + 1;
      end if;
    end if;
  end process;

  scaled_dec_coeff <= unsigned(decimation_coeff) srl
                      integer(log2(real(SAMPLES_PER_CLK)));

  max_decimation_cnt <= '1' when (decimation_cnt = scaled_dec_coeff) else '0';

  -- decimate at the rising edge of trig_in and when decimation count is reached
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1') then
        set_trigger <= '0';
      else
        if (trig_in_re = '1' or (max_decimation_cnt = '1' and
            trigger_en_1b = '1' and turn_off_strb = '0')) then
          set_trigger <= '1';
        else
          set_trigger <= '0';
        end if;
      end if;
    end if;
  end process;

--------------------------------------------------------------------------------
-- Frame count logic
--------------------------------------------------------------------------------
  -- Frame counter
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1' or framed_mode = '0') then  -- reset or unframed mode
        frame_cnt <= (others => '0');
      else                                      -- framed mode
        if (trig_in_re = '1') then              -- on the rising edge of trig in
          if (decimation_en_int = '1') then
            -- load the counter with an extra count to compensate for the
            -- decrement with the first set_trigger
            frame_cnt <= unsigned(frame_size) + 1;
          else
            frame_cnt <= unsigned(frame_size);  -- load the counter
          end if;
        elsif (set_trigger = '1') then          -- decrement the counter
          frame_cnt <= frame_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  last_sample   <= '1' when (frame_cnt = 1) else '0';
  turn_off_strb <= last_sample and max_decimation_cnt;

--------------------------------------------------------------------------------
-- make the trigger output
--------------------------------------------------------------------------------
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1') then
        trigger    <= '0';
        trigger_en <= '0';
      else
        trigger    <= trigger_en_1b and set_trigger;
        trigger_en <= trigger_en_1b;
      end if;
    end if;
  end process;

end arch;
