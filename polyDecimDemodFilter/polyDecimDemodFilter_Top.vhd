----------------------------------------------------------------------------------
-- Company: Raytheon BBN Technologies	
-- Engineer: Nick Materise
-- 
-- Create Date:    13:58:36 09/05/2013 
-- Design Name: 
-- Module Name:    polyDecimDemodFilter_Top - Behavioral 
-- Project Name: 
-- Target Devices: Virtex-6 I^2 Board, Spartan-6 Opal Kelly XEM 6010 LX45 Board
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;

entity polyDecimDemodFilter_Top is
	port (
		clk : in std_logic;
		clk_enable : in std_logic;
		max_count : in unsigned(3 downto 0);
		rst : in std_logic;
		tValidIn_Array : in std_logic_vector(15 downto 0) ;
		runSignals : in std_logic_vector(15 downto 0);
		numTaps : in std_logic_vector(4 downto 0) ;
		decimFactor : in real;
		reloadCoefData : std_logic_vector(15 downto 0) ;
		phaseInc : in std_logic_vector(15 downto 0);
		-- -------------------------------------------------
		-- temporary signals -------------------------------
		datatoDemodTop 		: out std_logic_vector(15 downto 0) ;
		dataOutFromDemodRe	: out std_logic_vector(31 downto 0) ;
		dataOutFromDemodIm	: out std_logic_vector(31 downto 0) ;
		-- temporary signals -------------------------------
		-- -------------------------------------------------
		inputSignal : in std_logic_vector(15 downto 0) ;
		outputDataRe : out std_logic_vector(15 downto 0) ;
		outputDataIm : out std_logic_vector(15 downto 0) 
	);
end entity;

architecture Behavioral of polyDecimDemodFilter_Top is

-- clk divide signals:
signal clk_div : std_logic;

-- internal trigger signals:
signal tValidIn_Decim, tValidIn_NCO : std_logic;
signal runFIRFilter, reloadCoef : std_logic;

-- polyDecimator signals:
signal dataOutFromFilter : std_logic_vector(15 downto 0) ;
signal throwAwayBits : std_logic_vector(7 downto 0) ;
signal dataInToDemod : std_logic_vector(15 downto 0) ;
signal tValidOut_Decim : std_logic;

-- fifo triggers:
signal readEn, writeEn : std_logic;
signal full, empty : std_logic;

-- demod signals:
signal outputDemodRe, outputDemodIm : std_logic_vector(31 downto 0) ;
signal tValidOut_NCO : std_logic;



begin

-- -------------------------------------------------
-- temporary signals -------------------------------
datatoDemodTop <= dataOutFromFilter;
dataOutFromDemodRe <= outputDemodRe;
dataOutFromDemodIm <= outputDemodIm;
-- temporary signals -------------------------------
-- -------------------------------------------------


-- unpack tValidIn_Array:
-- [							tValidIn_NCO | tValidIn_decim ]
tValidIn_decim <= tValidIn_Array(0);
tValidIn_NCO <= tValidIn_Array(1);

-- unpack runSignals:
-- [					 reloadCoef | runFIRFilter ]
runFIRFilter <= runSignals(0);
reloadCoef <= runSignals(1);

-- ----------------------------------------
-- Filter and Decimate Stage
-- ----------------------------------------

-- polyDecimator instantion:
mypolyDecimator : entity work.firFilter_top
port map (
	clk1 => clk,
	rst => rst,
  	tValidIn => tValidIn_Decim,
	runFilter => runFIRFilter,
	reloadCoef => reloadCoef,
	inputData => inputSignal,
	reloadCoefData => reloadCoefData,
	dataOutFromFilter(23 downto 16) => throwAwayBits,
	dataOutFromFilter(15 downto 0) => dataOutFromFilter,
  	tValidOut => tValidOut_Decim,
  	numtaps => numTaps
  ) ;

-- ----------------------------------------
-- FIFO and clk_div stage FSM
-- ----------------------------------------

-- clk for demodulator and iir filter:
my_clk_div : entity work.clk_div_top
port map(
  	max_count => max_count,
	clk_in => clk,
	rst => rst,
	clk_out => clk_div
  ) ;

-- fifo to cross clk and clk_div domains:
fifo_decim_demod : entity work.fifo_clk_to_decim
  port map (
    rst => rst,
    wr_clk => clk_div,
    rd_clk => clk,
    din => dataOutFromFilter,
    wr_en => writeEn,
    rd_en => readEn,
    dout => dataInToDemod,
    full => full,
    empty => empty
  );

-- read data from demicator and write to demodulator:
transfer_demod : process( clk, clk_div, rst, tValidOut_Decim, tValidIn_NCO )
begin
	if rst='1' then
		writeEn <= '0';
		readEn <= '0';
	else
		-- read from clk, write with clk_div:
		if rising_edge(clk) and tValidOut_Decim='1' then
			readEn <='1';
		end if ;
		if rising_edge(clk_div) and tValidIn_NCO='1' then
			writeEn <= '1';
		end if ;

		-- stop reading when full, stop writing when empty:
		if full='1' then
			readEn <= '0';
		end if ;
		if empty='1' and readEn <='0' then
			writeEn <= '0';
		end if ;
	end if ;
end process ; -- transfer_demod

-- ----------------------------------------
-- Demodulate and Multiply Stage
-- ----------------------------------------

-- demodulator instantiation:
mydigitalDemod : entity work.digitalDemodTest_top
port map (
	clk => clk_div,
	rst => rst,
	phaseInc =>	phaseInc,
	inputSignalData => dataInToDemod,
  	tValidIn => tValidIn_NCO,
  	tValidOut => tValidOut_NCO,
	outputDemodRe => outputDemodRe,
  	outputDemodIm => outputDemodIm
  ) ;

----------------------------------------
-- IIR Filtering Stage
----------------------------------------

-- butterworth iir filter instantiation for real signal:
mybutterworthRe : entity work.butter_quantized0_08
port map(
	clk => clk_div,
    clk_enable => clk_enable,
    reset => rst,     
    filter_in => outputDemodRe(31 downto 16),
    filter_out => outputDataRe
  ) ;

-- butterworth iir filter instantiation for imag signal:
mybutterworthIm : entity work.butter_quantized0_08
port map(
	clk => clk_div,
    clk_enable => clk_enable,
    reset => rst,     
    filter_in => outputDemodIm(31 downto 16),
    filter_out => outputDataIm
  ) ;


end Behavioral;

