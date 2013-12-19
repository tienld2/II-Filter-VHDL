-- Raytheon BBN Technologies
-- Nick Materise
-- 8/16/13

-- FIR Filter using IP CORE
-- Perform polyphase decimation on demodulated signal
-- Generate coefficients with SciPy
-- Rolloff of 50%

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all ;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;

entity firFilter_top is
  port (
	clk1 				: in std_logic;
	rst 				: in std_logic;
    tValidIn    : in std_logic;
	runFilter 			: in std_logic;
	reloadCoef 			: in std_logic;
	inputData			: in std_logic_vector(15 downto 0) ;
	reloadFIRCoefData 		: in std_logic_vector(15 downto 0) ;
	dataOutFromFilter			: out std_logic_vector(23 downto 0);
  tValidOut : out std_logic
    ) ;
end entity ; -- firFilter_top

architecture arch of firFilter_top is

-- input channel signals
signal tReadyData : std_logic;

-- config channel signals
signal tValidConfig : std_logic;
signal tReadyConfig : std_logic;
signal configData : std_logic_vector(7 downto 0) ;

-- reload channel signals
signal tValidReload : std_logic;
signal tReadyReload : std_logic;
signal tlastReload : std_logic;
signal dataToReloadFilter : std_logic_vector(15 downto 0) ;

-- reload events signals
signal reloadMissing, reloadUnexpected : std_logic;


begin

myfirFilterTest : entity work.polyDecimator
  port map (
    aclk => clk1,
    -- slave channel/input to filter:
    s_axis_data_tvalid => tValidIn,
    s_axis_data_tready => tReadyData,
    s_axis_data_tdata => inputData,
    
    -- slave config channel:
    s_axis_config_tvalid => tValidConfig,
    s_axis_config_tready => tReadyConfig,
    s_axis_config_tdata => configData,
    
    -- slave reload channel:
    s_axis_reload_tvalid => tValidReload,
    s_axis_reload_tready => tReadyReload,
    s_axis_reload_tlast => tlastReload,
    s_axis_reload_tdata => reloadFIRCoefData,
    
    -- master output channel:
    m_axis_data_tvalid => tValidOut,
    m_axis_data_tdata => dataOutFromFilter,

    -- slave reload events:
    event_s_reload_tlast_missing => reloadMissing,
    event_s_reload_tlast_unexpected => reloadUnexpected
  );

-- ----------------------------------------------------------------------------


end architecture ; -- arch