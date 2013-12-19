-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_temp_control
--*
--* @li Target Device: generic
--* @li Tool versions: any
--*
--*     @short Temperature control component
--*
--* Description:
--*
--*   This component issues temperature warning and fan enable signals by
--*   comparing the measured temperature with thresholds
--*
--*   @port srst            : input, synchronous active high reset
--*   @port clk             : input, clock
--*   @port temp_valid      : input, temperature data valid strobe
--*   @port temperature     : input, temperature data
--*   @port warning_thresh  : input, warning threshold from the host
--*   @port warning         :output, warning signal
--*   @port fan_thresh      : input, fan temperature threshold
--*   @port fan_en          :output, fan enable
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 03/26/10
--*
--******************************************************************************
--/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_temp_control is
  port (
    srst                 : in  std_logic;
    clk                  : in  std_logic;
    temp_valid           : in  std_logic;
    temperature          : in  std_logic_vector(7 downto 0);
    warning_thresh       : in  std_logic_vector(7 downto 0);
    warning              : out std_logic;
    fan_thresh           : in  std_logic_vector(7 downto 0);
    fan_en               : out std_logic
  );
end ii_temp_control;

architecture arch of ii_temp_control is

  signal temp_gt_warn_th      : boolean;
  signal temp_gt_fan_th       : boolean;
  signal temp_valid_cnt       : unsigned(2 downto 0);

begin

  -- register comparison to ease timing closure
  process (clk)
  begin
    if (rising_edge(clk)) then
      temp_gt_warn_th <= signed(temperature) >= signed(warning_thresh);
      temp_gt_fan_th  <= signed(temperature) >= signed(fan_thresh);
    end if;
  end process;

  -- increment counter when crossing warning threshold, to avoid aberrations
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        temp_valid_cnt <= (others => '0');
      elsif (temp_valid = '1') then
        if (temp_gt_warn_th = true) then
          if (temp_valid_cnt(2) = '0') then
            temp_valid_cnt <= temp_valid_cnt + 1;
          end if;
        else
          temp_valid_cnt <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  -- assert warning/fan_en signals
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (srst = '1') then
        warning <= '0';
        fan_en  <= '0';
      else
        warning <= temp_valid_cnt(2);
        if (temp_valid = '1' and temp_gt_fan_th = true) then
          fan_en <= '1';
        else
          fan_en <= '0';
        end if;
      end if;
    end if;
  end process;

end arch;
