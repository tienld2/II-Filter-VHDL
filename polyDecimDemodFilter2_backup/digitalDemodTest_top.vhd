-- Started 7/11/13, Modified 9/25/13
-- Raytheon BBN Technologies
-- Nick Materise


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.all;


entity digitalDemodTest_top is
  generic ( 
    decimFactor : integer := 4          -- (valid values: 2,4,8,16)
   );
  port (
	clk : in std_logic;
	rst : in std_logic;
	phaseInc : in std_logic_vector(15 downto 0);
	inputSignalData : in std_logic_vector(19 downto 0);
	-- final output from mul16to32:
  tValidIn : in std_logic;
  tValidOut : out std_logic;
	outputDemodRe : out std_logic_vector(35 downto 0);
  outputDemodIm : out std_logic_vector(35 downto 0) 
  ) ;
end entity ; -- digitalDemodTest_top


architecture arch of digitalDemodTest_top is

-- padding signal
signal bit_growth : real := LOG2(real(decimFactor));

signal pad : std_logic_vector(integer(bit_growth)-1 downto 0);


-- multiplier signals
signal ncoData : std_logic_vector(31 downto 0) ;
signal inputB : std_logic_vector(47 downto 0)  := (others => '0');

signal outputData : std_logic_vector(79 downto 0) := (others => '0') ;



begin

-- populate pad array with zeros:
pad <= (others => '0');

-- outputData = outputDemodRe + j * outputDemodIm
              -- [75       40|35     0]
              -- [   imag    |  real  ]
-- outputDemodRe <= outputData(35 downto 0);
-- outputDemodIm <= outputData(75 downto 40);

-- port mapping of nco module:
myncotest : entity work.ncoTest
  port map (
    aclk => clk,
    s_axis_config_tvalid => tValidIn,
    s_axis_config_tdata => phaseInc,
    m_axis_data_tvalid => tValidOut,
    m_axis_data_tdata => ncoData
  );

-- Complex Multiplier
-- mycomplex_mul16by20 : entity work.mul16by20
--   port map (
--     aclk => clk,
--     s_axis_a_tvalid => tValidIn_mul20by16,
--     s_axis_a_tdata => ncoData,
--     s_axis_b_tvalid => tValidIn_mul20by16,
--     s_axis_b_tdata => inputB,
--     m_axis_dout_tvalid => tValidOut,
--     m_axis_dout_tdata => outputData
--   );

-- muls for real component of inputDataSignal:
-- port mapping of cos(w_if t)*cos(w t), Re{A(t)} to mul16to32:
mynewmul16by20Re : entity work.mul16by20
  port map (
    clk => clk,
    a => ncoData(15 downto 0),
    b => inputSignalData,
    sclr => rst,
    p => outputDemodRe
  );

-- muls for imag component of inputDataSignal:
-- port mapping of sin(w_if t)*cos(w t), Re{A(t)} to mul16to32:
mynewmul16by20Im : entity work.mul16by20
  port map (
    clk => clk,
    a => ncoData(31 downto 16),
    b => inputSignalData,
    sclr => rst,
    p => outputDemodIm
  );



end architecture ; -- arch