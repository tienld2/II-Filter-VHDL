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
	port (
  		clk1 	              : in 	 std_logic;  -- Pin "AB13"
	  	hi_in               : in    std_logic_vector(7 downto 0);
	  	hi_out              : out   std_logic_vector(1 downto 0);
	  	hi_inout            : inout std_logic_vector(15 downto 0);
      hi_aa               : inout std_logic; -- Necessary for IOBs
	  	hi_muxsel           : out   std_logic; 
	  	i2c_sda             : out   std_logic; -- I^2 C 
	  	i2c_scl             : out   std_logic; -- I^2 C
	  	led                 : out   std_logic_vector(7 downto 0)
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

-- clk divide signals:
signal clk_div            : std_logic;
constant decimFactor 			: natural := 4;

-- trigger signals:
-- signal tValidIn_Demod     : std_logic;
signal runFIRFilter       : std_logic;
signal reloadCoef         : std_logic;

-- polyDecimator signals:
signal max_count          : natural := 1;
signal rst                : std_logic :='0';
signal reloadFIRCoefData  : std_logic_vector(15 downto 0);
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
constant firfilter_length : integer := 36;
constant pulse_length     : integer := 4096;
constant window_length    : integer := integer(real(pulse_length)/real(decimFactor)); 
                                                 -- pulse_length / decimFactor 
                                                 --         4096 / 4 = 1024

-- FrontPanel Signals
-- [ ---------------------------------------------------------------------------------------- ]

-- set the okWire N-Value
constant numOutputs       : integer := 9;

signal ti_clk             : std_logic;
signal slow_clk           : std_logic_vector(15 downto 0) := (others => '0');
signal ok1                : std_logic_vector(30 downto 0);
signal ok2                : std_logic_vector(16 downto 0);
signal ok2s               : std_logic_vector(17*numOutputs-1 downto 0);
signal ledWire            : std_logic_vector(15 downto 0);

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

-- wireouts from probe
signal ramOutput          : std_logic_vector(15 downto 0) ;


-- [ ---------------------------------------------------------------------------------------- ]


begin

-- unpack triggerLines:

--			[ ----write enables----	]
-- [				    | inputSignalWE	]
-- [				    |		0 	 	      ]

-- assign addresses to dummy wireIns:
inSigWriteAddr <= unsigned(dummyAddrInWr(11 downto 0));
coefWriteAddr <= unsigned(dummyAddrCoef(11 downto 0));
firCoefWriteAddr <= unsigned(dummyfirCoefWr(11 downto 0));
outSigReadAddr <= unsigned(dummyAddrOutRd(11 downto 0));

-- inSigReadAddr <= unsigned(dummyAddrInRd(11 downto 0));

-- assign block ram probe addresses:
ramAddrRd <= unsigned(dummyRamRd(11 downto 0));

-- assign handshaking signals:
-- tValidIn_Demod <= tValidOut_Decim;

-- unpack wireInLines:
-- [	  | reloadCoef | runFIRFilter | run_mac | load_ram | rst ]
-- [	  |		 4  	   |		3         | 	   2  |   1      |  0  ]
rst <= wireInLines(0);
-- load_ram <= wireInLines(1);
-- run_mac <= wireInLines(2);
runFIRFilter <= wireInLines(3);
reloadCoef <= wireInLines(4);

-- ----------------------------------------
-- FrontPanel API Signals
-- ----------------------------------------

-- set I^2C to high impedance
-- set hi_muxsel to 0
i2c_sda    <= 'Z';
i2c_scl    <= 'Z';
hi_muxsel  <= '0';

-- setup LED for simple debugging
led <= not wireInLines(7 downto 0);

-- okHost and FrontPanel API instances:
okHI : okHost port map (
    hi_in=>hi_in, hi_out=>hi_out, hi_inout=>hi_inout,hi_aa=>hi_aa,
    ti_clk=>ti_clk, ok1=>ok1, ok2=>ok2);

okWO : okWireOR  generic map (N=>numOutputs) port map (ok2=>ok2, ok2s=>ok2s); -- see constants for numOutputs

ep00 : okWireIn port map (ok1=>ok1, ep_addr=>x"00", ep_dataout=>wireInLines);
ep01 : okWireIn port map (ok1=>ok1, ep_addr=>x"01", ep_dataout=>phaseInc);
ep02 : okWireIn port map (ok1=>ok1, ep_addr=>x"02", ep_dataout=>wireInputSignal);
ep03 : okWireIn port map (ok1=>ok1, ep_addr=>x"03", ep_dataout=>dummyAddrInWr);
ep04 : okWireIn port map (ok1=>ok1, ep_addr=>x"04", ep_dataout=>dummyAddrOutRd);
ep05 : okWireIn port map (ok1=>ok1, ep_addr=>x"05", ep_dataout=>windowCoef(15 downto 0));
ep06 : okWireIn port map (ok1=>ok1, ep_addr=>x"06", ep_dataout=>windowCoef(31 downto 16));
ep07 : okWireIn port map (ok1=>ok1, ep_addr=>x"07", ep_dataout=>dummyAddrCoef);
ep08 : okWireIn port map (ok1=>ok1, ep_addr=>x"08", ep_dataout=>dummyfirCoefWr);
ep09 : okWireIn port map (ok1=>ok1, ep_addr=>x"09", ep_dataout=>dummyRamRd);

ep0E : okWireIn port map (ok1=>ok1, ep_addr=>x"0E", ep_dataout=>ledWire);

oktriggerLines : okTriggerIn port map(ok1=>ok1, ep_addr=>x"40", ep_clk=>ti_clk, ep_trigger=>triggerLines);

-- ----------------------------------------
-- Load FIRFilter Block Ram
-- ----------------------------------------

inputSignal_blockram : entity  work.block_ram16
  port map (
    clka => ti_clk,
    wea(0) => triggerLines(0),
    addra => std_logic_vector(inSigWriteAddr),
    dina => wireInputSignal,
    clkb => clk1,
    addrb => std_logic_vector(inSigReadAddr),
    doutb => inputSignal
  );

-- ----------------------------------------
-- Reload FIRFilter Coefficients
-- ----------------------------------------

reloadFIR_blockram : entity  work.block_ram16
  port map (
    clka => ti_clk,
    wea(0) => triggerLines(0),
    addra => std_logic_vector(inSigWriteAddr),
    dina => wireFIRCoefData,
    clkb => clk1,
    addrb => std_logic_vector(inSigReadAddr),
    doutb => reloadFIRCoefData
  );

-- ----------------------------------------
-- Load MAC Block Ram
-- ----------------------------------------

mac_coef_blockram : entity  work.block_ram32
  port map (
    clka => ti_clk,
    wea(0) => triggerLines(0),
    addra => std_logic_vector(coefWriteAddr),
    dina => windowCoef,
    clkb => clk_div,
    addrb => std_logic_vector(coefReadAddr),
    doutb => accCoefs
  );

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
-- Pass reloadFIRCoefData to FIR Filter
-- ----------------------------------------

reloadCoefFIR : process( clk1,rst,reloadCoef )
begin
   if rst='1' then
      firCoefReadAddr <= (others => '0');
    elsif rising_edge(clk1) then
        if reloadCoef='1' then
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
  	reloadCoef => reloadCoef,
  	inputData => inputSignal,
  	reloadFIRCoefData => reloadFIRCoefData,
  	dataOutFromFilter(23 downto 20) => throwAwayBits,
  	dataOutFromFilter(19 downto 0) => dataOutFromFilter,
    tValidOut => tValidOut_Decim
    );


-- ----------------------------------------
-- FIFO and clk_div stage 
-- ----------------------------------------

-- clk for demodulator and iir filter:
my_clk_div : entity work.clk_div_top
  port map(
    max_count => max_count,
    clk_in => clk1,
    rst => rst,
    clk_out => clk_div
    );

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
     decimFactor => 4   -- (valid values: 2,4,8,16)
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

-- ----------------------------------------
-- Probe to write to WireOut
-- ----------------------------------------

myblkram_probe : entity work.block_ram_probe
generic map(
  data_width => 16,
  ram_depth => window_length,
  addr_width => 12
  )
  port map(
    clk_in => clk_div,
    clk_out => ti_clk,
    rst => rst,
    start_writing => run_mac,
    readAddr => ramAddrRd,
    dataIn => acc(31 downto 16),
    dataOut => ramOutput
    );

----------------------------------------
-- Complex IIR Filtering Stage
----------------------------------------

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

-- ----------------------------------------
-- Write Data from MAC to Block Ram
-- ----------------------------------------

transfer_mac : process( clk_div,rst,run_mac )
begin
  if rst='1' then
    writeEn_acc <= '0';  
    tValidIn_mul <= '0';
    outSigWriteAddr <= (others => '0');
  elsif rising_edge(clk_div) then
    if run_mac='1' then
      tValidIn_mul <= '1';
      if outSigWriteAddr < (window_length-1) then
        writeEn_acc <= '1';
        outSigWriteAddr <= outSigWriteAddr + 1;
      else
        writeEn_acc <= '0';
      end if;
    else
      tValidIn_mul <= '0';
      writeEn_acc <= '0';
    end if;
  end if;
end process; -- transfer_mac

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


transfer_mac : process( clk_div,rst,run_mac )
type stateType is (waitState, runState, doneState);
variable state : stateType;

begin
  if rising_edge(clk_div) then

  -- default statements:
  writeEn_acc <= '0';  
  tValidIn_mul <= '0';
  outSigWriteAddr <= (others => '0');
  case( state ) is
  
    when waitState =>
      if run_mac='1' then
        state := runState;
      end if;
  
    when runState =>
      writeEn_acc <= '1';
      tValidIn_mul <='1';
      outSigWriteAddr <= outSigWriteAddr + '1';
      if outSigWriteAddr=(window_length-1) then
        state := doneState;
      end if;
  
    when doneState =>
      if run_mac= '0' then
        state := waitState;
      end if;
  end case;
end if;
end process; -- transfer_mac

-- ----------------------------------------
-- Real MAC Block Ram
-- ----------------------------------------

myReacc50 : entity work.block_ram50
  port map (
    clka => clk_div,
    wea(0) => writeEn_acc,
    addra => std_logic_vector(outSigWriteAddr),
    dina => acc(49 downto 0),
    clkb => ti_clk,
    addrb => std_logic_vector(outSigReadAddr),
    doutb => acc_padRe(49 downto 0)
  );

-- ----------------------------------------
-- Imag MAC Block Ram
-- ----------------------------------------

myImacc50 : entity work.block_ram50
  port map (
    clka => clk_div,
    wea(0) => writeEn_acc,
    addra => std_logic_vector(outSigWriteAddr),
    dina => acc(99 downto 50),
    clkb => ti_clk,
    addrb => std_logic_vector(outSigReadAddr),
    doutb => acc_padIm(49 downto 0)
  );


-- FrontPanel Signals
-- [ ---------------------------------------------------------------------------------------- ]


-- real acc outputs
ep20 : okWireOut port map (ok1=>ok1, ok2=>ok2s(1*17-1 downto 0*17), ep_addr=>x"20", ep_datain=>acc_padRe(63 downto 48));
ep21 : okWireOut port map (ok1=>ok1, ok2=>ok2s(2*17-1 downto 1*17), ep_addr=>x"21", ep_datain=>acc_padRe(47 downto 32));
ep22 : okWireOut port map (ok1=>ok1, ok2=>ok2s(3*17-1 downto 2*17), ep_addr=>x"22", ep_datain=>acc_padRe(31 downto 16));
ep23 : okWireOut port map (ok1=>ok1, ok2=>ok2s(4*17-1 downto 3*17), ep_addr=>x"23", ep_datain=>acc_padRe(15 downto 0));

-- imag acc outputs
ep24 : okWireOut port map (ok1=>ok1, ok2=>ok2s(5*17-1 downto 4*17), ep_addr=>x"24", ep_datain=>acc_padIm(63 downto 48));
ep25 : okWireOut port map (ok1=>ok1, ok2=>ok2s(6*17-1 downto 5*17), ep_addr=>x"25", ep_datain=>acc_padIm(47 downto 32));
ep26 : okWireOut port map (ok1=>ok1, ok2=>ok2s(7*17-1 downto 6*17), ep_addr=>x"26", ep_datain=>acc_padIm(31 downto 16));
ep27 : okWireOut port map (ok1=>ok1, ok2=>ok2s(8*17-1 downto 7*17), ep_addr=>x"27", ep_datain=>acc_padIm(15 downto 0));

ep28 : okWireOut port map (ok1=>ok1, ok2=>ok2s(9*17-1 downto 8*17), ep_addr=>x"28", ep_datain=>ramOutput);

-- [ ---------------------------------------------------------------------------------------- ]


end Behavioral;

