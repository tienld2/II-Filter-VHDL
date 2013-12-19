-- Copyright 2011 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_sample_sort
--*
--* @li Target Device: any
--* @li Tool versions: ISE 13.1
--*
--*     @short Sample sorting
--*
--* Description:
--*
--*   This component provides sample sorting based on the external sync
--*   phase.
--*
--*   @port clk             : input, clock
--*   @port adc_sync_phase  : input, latched ADC sync phase
--*   @port ext_sync_phase  : input, external sync phase
--*   @port din             : input, input data from ADC PHY
--*   @port dout            :output, aligned output data
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 5/3/11
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_sample_sort is
  port (
    -- Clock
    clk                  : in  std_logic;

    -- Controls
    adc_sync_phase       : in  std_logic;
    ext_sync_phase       : in  std_logic_vector(1 downto 0);

    -- Data in and out
    din                  : in  std_logic_vector(47 downto 0);
    dout                 : out std_logic_vector(47 downto 0)
  );
end ii_sample_sort;

architecture arch of ii_sample_sort is

  signal din_s0               : std_logic_vector(47 downto 0);
  signal din_s1               : std_logic_vector(47 downto 0);
  signal phase_adj            : unsigned(2 downto 0);
  attribute keep              : string;
  attribute keep of phase_adj : signal is "TRUE";

begin

  din_s0 <= din after 1 ps;  -- hack to avoid simulation issue

  -- Pipeline input data to help select samples
  process (clk)
  begin
    if (rising_edge(clk)) then
      din_s1 <= din_s0;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (adc_sync_phase = '1') then
        phase_adj <= resize(unsigned(ext_sync_phase),3) + 1;
      else
        phase_adj <= resize(unsigned(ext_sync_phase),3);
      end if;
    end if;
  end process;

  -- Select output samples based on phase_adj
  process (clk)
  begin
    if (rising_edge(clk)) then
      case phase_adj is
        when "000"  => dout <= din_s1(47 downto 0);
        when "001"  => dout <= din_s0(11 downto 0) & din_s1(47 downto 12);
        when "010"  => dout <= din_s0(23 downto 0) & din_s1(47 downto 24);
        when "011"  => dout <= din_s0(35 downto 0) & din_s1(47 downto 36);
        when "100"  => dout <= din_s0(47 downto 0);
        when others => null;
      end case;
    end if;
  end process;

end arch;

