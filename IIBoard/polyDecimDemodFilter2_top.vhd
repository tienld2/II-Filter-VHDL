----------------------------------------------------------------------------------
-- Company: Raytheon BBN Technologies	
-- Engineer: Nick Materise
-- 
-- Create Date:    13:58:36 09/25/2013 
-- Design Name: 
-- Module Name:    polyDecimDemodFilter2_Top - Behavioral 
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all;

use IEEE.MATH_REAL.all;
use work.FRONTPANEL.all;

entity polyDecimDemodFilter2_Top is
generic(
  decimFactor             : in integer := 4;
  firfilter_length        : in integer := 36
  );
	port (
  		clk1 	              : in std_logic;  -- ~260 MHz
      clk_div             : in std_logic;  -- Decimated clock
      rst                 : in std_logic;  -- front_end_rst
      runFilter           : in std_logic;
      reloadCoefEn        : in std_logic;
      inputSignal         : in std_logic_vector(15 downto 0);
      firCoefs            : in std_logic_vector(15 downto 0);
      accCoefs            : in std_logic_vector(31 downto 0) ;
      dataReady           : out std_logic;   -- data from MAC is valid
      macData             : out std_logic_vector(99 downto 0) 
        );
end entity;


architecture Behavioral of polyDecimDemodFilter2_Top is

-- top level signals:
signal accCoefs           : std_logic_vector(31 downto 0);
signal inputSignal        : std_logic_vector(15 downto 0);
signal wireInputSignal    : std_logic_vector(15 downto 0);

signal acc                :  std_logic_vector(99 downto 0);
signal acc_padRe          :  std_logic_vector(63 downto 0);
signal acc_padIm          :  std_logic_vector(63 downto 0);

-- polyDecimator signals:
signal max_count          : natural := 1;
signal rst                : std_logic :='0';
signal firCoefs           : std_logic_vector(15 downto 0);
signal wireFIRCoefData    : std_logic_vector(15 downto 0);
signal dataOutFromFilter  : std_logic_vector(19 downto 0);
signal throwAwayBits      : std_logic_vector(3 downto 0);
signal dataInToDemod      : std_logic_vector(19 downto 0);
signal tValidOut_Decim    : std_logic;


-- fifo triggers:
signal readEn, writeEn    : std_logic;
signal full, empty        : std_logic;
signal full16, empty16    : std_logic;
signal full32, empty32    : std_logic;

-- demod signals:
signal phaseInc           : std_logic_vector(15 downto 0);
signal outputDemodRe      : std_logic_vector(35 downto 0);
signal outputDemodIm      : std_logic_vector(35 downto 0);
signal tValidOut_NCO      : std_logic;
signal tValidOut_Demod    : std_logic;

-- mac signals
signal iirFilterData      : std_logic_vector(39 downto 0);
signal load_ram,run_mac   : std_logic := '0';
signal windowCoef         : std_logic_vector(31 downto 0);
signal writeEn_acc        : std_logic := '0';
signal tValidIn_mul       : std_logic := '0';
signal read_blkram        : std_logic := '0';

-- pulse width settings
constant pulse_length     : integer := 4096;
constant window_length    : integer := integer(real(pulse_length)/real(decimFactor)); 
                                                 -- pulse_length / decimFactor 
                                                 --         4096 / 4 = 1024


signal triggerLines       : std_logic_vector(15 downto 0); 
signal wireInLines        : std_logic_vector(15 downto 0);

signal coefWriteAddr      : unsigned(11 downto 0);
signal coefReadAddr       : unsigned(11 downto 0);
signal dummyAddrCoef      : std_logic_vector(15 downto 0) := (others => '0');

signal firCoefWriteAddr   : unsigned(11 downto 0);
signal firCoefReadAddr    : unsigned(11 downto 0);
signal dummyfirCoefWr     : std_logic_vector(15 downto 0) := (others => '0');

signal inSigWriteAddr     : unsigned(11 downto 0) := (others => '0');
signal dummyAddrInWr      : std_logic_vector(15 downto 0) := (others => '0'); 
signal inSigReadAddr      : unsigned(11 downto 0) := (others => '0');
signal dummyAddrInRd      : std_logic_vector(15 downto 0) := (others => '0');

signal outSigWriteAddr    : unsigned(11 downto 0) := (others => '0');
signal outSigReadAddr     : unsigned(11 downto 0) := (others => '0');
signal dummyAddrOutRd     : std_logic_vector(15 downto 0) := (others => '0');

-- auxiliary addresses 
-- to clock data to
-- and from probe
signal ramAddrWr          : unsigned(11 downto 0) := (others => '0');
signal ramAddrRd          : unsigned(11 downto 0) := (others => '0');
signal dummyRamWr         : std_logic_vector(15 downto 0) := (others => '0');
signal dummyRamRd         : std_logic_vector(15 downto 0) := (others => '0');
signal ramWriteEn         : std_logic := '0';


begin

-- unpack triggerLines:

-- unpack wireInLines:
-- [	  | reloadCoefEn | runFIRFilter | run_mac | load_ram | rst ]
-- [	  |		 4  	   |		3         | 	   2  |   1      |  0  ]
rst <= wireInLines(0);
-- load_ram <= wireInLines(1);
-- run_mac <= wireInLines(2);
runFIRFilter <= wireInLines(3);
reloadCoefEn <= wireInLines(4);


-- update the ready output signal:
dataReady <= run_mac;
macData <= acc;


-- ----------------------------------------
-- Pass inputSignal to FIR Filter
-- ----------------------------------------

transferPolyDecimator : process( clk1,rst,runFIRFilter )
begin
   if rst='1' then
      inSigReadAddr <= (others => '0');
    elsif rising_edge(clk1) then
        if runFIRFilter='1' then
          inSigReadAddr <= inSigReadAddr + '1';
        end if;
        if inSigReadAddr=(pulse_length-1) then
          inSigReadAddr <= inSigReadAddr;
        end if;
    end if;
end process; -- transferPolyDecimator

-- ----------------------------------------
-- Pass firCoefs to FIR Filter
-- ----------------------------------------

reloadCoefEnFIR : process( clk1,rst,reloadCoefEn )
begin
   if rst='1' then
      firCoefReadAddr <= (others => '0');
    elsif rising_edge(clk1) then
        if reloadCoefEn='1' then
          firCoefReadAddr <= firCoefReadAddr + '1';
        end if;
        if firCoefReadAddr=(firfilter_length-1) then
          firCoefReadAddr <= firCoefReadAddr;
        end if;
    end if;
end process; -- transferPolyDecimator

-- ----------------------------------------
-- Pass coefs to MAC
-- ----------------------------------------

transfer_coef_mac : process( clk_div,rst,run_mac )
begin
  if rst='1' then
      coefReadAddr <= (others => '0');
    elsif rising_edge(clk_div) then
    if run_mac='1' then
      coefReadAddr <= coefReadAddr + '1';
    end if;
    if coefReadAddr=(window_length-1) then
        coefReadAddr <= coefReadAddr;    
    end if;
  end if;
end process; -- transfer_coef_mac

-- ----------------------------------------
-- Filter and Decimate Stage
-- ----------------------------------------

-- polyDecimator instantion:
mypolyDecimator : entity work.firFilter_top
  port map (
  	clk1 => clk1,
  	rst => rst,
   	tValidIn => runFIRFilter,
  	runFilter => runFIRFilter,
  	reloadCoefEn => reloadCoefEn,
  	inputData => inputSignal,
  	firCoefs => firCoefs,
  	dataOutFromFilter(23 downto 20) => throwAwayBits,
  	dataOutFromFilter(19 downto 0) => dataOutFromFilter,
    tValidOut => tValidOut_Decim
    );


-- ----------------------------------------
-- FIFO and clk_div stage 
-- ----------------------------------------

-- fifo to cross clk and clk_div domains:
fifo_decim_demod : entity work.fifo_clk_to_decim
  port map (
    rst => rst,
    wr_clk => clk1,
    rd_clk => clk_div,
    din => dataOutFromFilter,
    wr_en => tValidOut_Decim,
    rd_en => not empty,
    dout => dataInToDemod,
    full => full,
    empty => empty
  );

-- ----------------------------------------
-- Demodulate and Multiply Stage
-- ----------------------------------------

-- demodulator instantiation:
mydigitalDemod : entity work.digitalDemodTest_top
  generic map( 
     decimFactor => decimFactor   -- (valid values: 2,4,8,16)
  )
  port map (
    clk => clk_div,
    rst => rst,
    phaseInc => phaseInc,
    inputSignalData => dataInToDemod,
    tValidIn => not empty,
    tValidOut_NCO => tValidOut_NCO,
    tValidOut => tValidOut_Demod,
    outputDemodRe => outputDemodRe,
    outputDemodIm => outputDemodIm
    );

mybutterworth20bit : entity work.butter_quantized_20bit 
  port map( clk       => clk_div,
       clk_enable    => '1',
       reset         => not run_mac,
       filter_in_re  => outputDemodRe(30 downto 11),
       filter_in_im  => outputDemodIm(30 downto 11),
       filter_out_re => iirFilterData(19 downto 0),
       filter_out_im => iirFilterData(39 downto 20)
       );

-- ----------------------------------------
-- Shift Register to FIR Filter
-- ----------------------------------------

iir_to_mac_handshake : entity work.ShiftRegister
  generic map (
   n => 9)         
  port map (
   RESET => rst,
   CLK => clk_div,
   d => tValidOut_Demod,
   q => run_mac);

----------------------------------------
-- Multiply-Accumulate Stage
----------------------------------------

mymac20 : entity work.mac16_top 
  port map( 
  clk => clk_div,
  clk_en => '1',
  rst => rst,
  run_mac => run_mac,
  coefDataIn => accCoefs,
  iirData => iirFilterData,
  tValidIn_mul => tValidIn_mul,
  acc  => acc
);



end Behavioral;

