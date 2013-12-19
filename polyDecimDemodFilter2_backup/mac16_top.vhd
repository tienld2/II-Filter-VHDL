-- 9/23/13
-- Multiply-Accumulate Unit

-- Contains 16-bit block ram to load weighting 
-- function coefficents

-- Integrates DC terms from the IIR Filter stage

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;

entity mac16_top is
  port (
	clk_in 				: in std_logic;
	clk 				: in std_logic;
	clk_en 				: in std_logic;
	rst 				: in std_logic;
	trigger_array 		: in std_logic_vector(4 downto 0) ;
	coefDataIn 			: in std_logic_vector(31 downto 0) ;
	iirData 			: in std_logic_vector(39 downto 0) ;
	-- tempory signals --------------------------------------
	mulOutput 			: out std_logic_vector(79 downto 0) ;
	blockRamOutput  	: out std_logic_vector(31 downto 0) ;
	-- tempory signals --------------------------------------
	acc 				: out std_logic_vector(99 downto 0) 
  ) ;
end entity ; -- mac16_top

architecture arch of mac16_top is

-- bool to std_logic conversion
function bool_to_std_logic(mybool : boolean) return std_logic is
begin
	if mybool then
		return('1');
	else
		return('0');
	end if;
end bool_to_std_logic;


-- block ram signals:
signal coefDataOut : std_logic_vector(31 downto 0) := (others => '0') ;
signal write_en, read_en : std_logic_vector(0 downto 0) ;


-- address signals:
signal readAddr : std_logic_vector(11 downto 0) ;
signal writeAddr : std_logic_vector(11 downto 0) ;

-- trigger signals:
signal load_ram,run_mac : std_logic;

-- multiplier signals:
signal tValidIn_mul : std_logic;
signal tValidOut_mul : std_logic;
signal inputA : std_logic_vector(47 downto 0) := (others => '0');
signal outputProd : std_logic_vector(79 downto 0);

-- accumulator singals
signal acc_rst : std_logic := '1';
signal acc_rst_l : std_logic := '1';


begin

-- assigning signals to array:
-- [					run_mac | load_ram | write_en ]

load_ram <= trigger_array(1);
run_mac <= trigger_array(2);

-- assign appropriate bits of iirData to inputA:
inputA(19 downto 0) <= iirData(19 downto 0); 	-- Real component mapping
inputA(43 downto 24) <= iirData(39 downto 20); 	-- Imag component mapping


-- tempory signals --------------------------------------
mulOutput <= outputProd;
blockRamOutput <= coefDataOut;
-- tempory signals --------------------------------------

acc_rst <= bool_to_std_logic(tValidOut_mul = '0' or run_mac = '0');


-- process to write coefficients
-- read data into mac
run_mac16 : process( clk,clk_in,rst,load_ram,run_mac )
begin
	if rst='1' then
		write_en <= (others => '0');
		writeAddr <= (others => '0');
		readAddr <= (others => '0');
		tValidIn_mul <='0';
	elsif rising_edge(clk) then
		if load_ram='1' then
			write_en <= (others => '1');
			writeAddr <= writeAddr + '1';
		end if;
		if run_mac='1' then
			-- write_en <= (others => '0');
			-- writeAddr <= (others => '0');
			readAddr <= readAddr + '1';
			tValidIn_mul <= '1';
		-- else
		-- 	readAddr <= (others => '0');
		end if ;
		acc_rst_l <= acc_rst;
	end if ;
end process ; -- run_mac16


--  32-bit block ram to store  complex weighting 
-- 	coefficients from window function
myblock_ram32 : entity  work.block_ram16
  port map (
    clka => clk,
    wea => write_en,
    addra => writeAddr,
    dina => coefDataIn,
    clkb => clk,
    addrb => readAddr,
    doutb => coefDataOut
  );

-- complex mul32by40, multiplies data from
-- IIR Filter with complex coefficients
myc_mul32by40 : entity work.c_mul32by40
  port map (
	aclk => clk,
    s_axis_a_tvalid => tValidIn_mul,
    s_axis_a_tdata => inputA,
    s_axis_b_tvalid => tValidIn_mul,
    s_axis_b_tdata => coefDataOut,
    m_axis_dout_tvalid => tValidOut_mul,
    m_axis_dout_tdata => outputProd
);


-- mul_to_acc_handshake : entity work.ShiftRegister
--   generic map (
--   	n => 1)
--   port map (
--   	RESET => rst,
--   	CLK => clk,
--   	d => tValidOut_mul,
--   	q => );

-- accumulator to sum real results from multiplier
myacc40Re : entity work.acc40
  port map (
    b => outputProd(35 downto 0),
    clk => clk,
    sclr => acc_rst_l,
    q => acc(49 downto 0)
  );

myacc40Im : entity work.acc40
  port map (
    b => outputProd(75 downto 40),
    clk => clk,
    sclr => acc_rst_l,
    q => acc(99 downto 50)
  );






end architecture ; -- arch