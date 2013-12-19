-- Started 7/11/13, Modified 7/12/13
-- Raytheon BBN Technologies
-- Nick Materise
-- Check List:
--       Check for the mul modules and nco module                [x]
--       Attempt to add them here, route signals accordingly     [x]
--       Compile and implement digitalDemodTest_top              [x] 
--       Remember to add imag signals after real works           [x]
--       Contain both in single functional digitalDemod block    [x]

-- Check List: 7/15/13
--       Wire connections to FrontPanel API ports                [x]
--       Verify in hardware and write results back to host       [x]
--       diff hardware output with simulation waveform output    [ ]

-- Check List: 7/17/13
--       Remove mul8to16, replace with mul16to32                 [x]
--       Modify NCO to take 16-bit phaseInc, output 32-bit       [x]
--       Recompile all modules                                   [x]
--       Test output with cosine input signal                    [ ]
--       Compare Output with and without 16 LSB                  [ ]

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity digitalDemodTest_top is
  port (
	clk : in std_logic;
	rst : in std_logic;
	phaseInc : in std_logic_vector(15 downto 0);
	inputSignalData : in std_logic_vector(15 downto 0);
	-- final output from mul16to32:
  tValidIn : in std_logic;
  tValidOut : out std_logic;
	outputDemodRe : out std_logic_vector(31 downto 0);
  outputDemodIm : out std_logic_vector(31 downto 0) 
  ) ;
end entity ; -- digitalDemodTest_top


architecture arch of digitalDemodTest_top is

-- signals for the nco module:
signal ncoData : std_logic_vector(31 downto 0) ;

begin


-- port mapping of nco module:
myncotest : entity work.ncoTest
  port map (
    aclk => clk,
    s_axis_config_tvalid => tValidIn,
    s_axis_config_tdata => phaseInc,
    m_axis_data_tvalid => tValidOut,
    m_axis_data_tdata => ncoData
  );

-- splitting ncoData into sinData, cosData 
-- after ncotest populates ncoData  
-- sinData <= ncoData(31 downto 16);
-- cosData <= ncoData(15 downto 0);

-- muls for real component of inputDataSignal:
-- port mapping of cos(w_if t)*cos(w t), Re{A(t)} to mul16to32:
mynewmul16to32testRe : entity work.mul16to32
  port map (
    clk => clk,
    a => inputSignalData,
    b => ncoData(15 downto 0),
    sclr => rst,
    p => outputDemodRe
  );

-- muls for imag component of inputDataSignal:
-- port mapping of sin(w_if t)*cos(w t), Re{A(t)} to mul16to32:
mynewmul16to32testIm : entity work.mul16to32
  port map (
    clk => clk,
    a => inputSignalData,
    b => ncoData(31 downto 16),
    sclr => rst,
    p => outputDemodIm
  );



end architecture ; -- arch