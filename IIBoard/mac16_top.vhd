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
	clk 				    : in std_logic;
	clk_en 				  : in std_logic;
	rst 				    : in std_logic;
	run_mac 			  : in std_logic;
	coefDataIn 			: in std_logic_vector(31 downto 0);
	iirData 			  : in std_logic_vector(39 downto 0);
	tValidIn_mul 		: in std_logic;
	acc 				    : out std_logic_vector(99 downto 0)
  );

  attribute incremental_synthesis: string;
  attribute incremental_synthesis of mac16_top: entity is "yes";

end entity; -- mac16_top

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
signal write_en, read_en  : std_logic_vector(0 downto 0);


-- address signals:
signal readAddr           : std_logic_vector(11 downto 0);
signal writeAddr          : std_logic_vector(11 downto 0);

-- multiplier signals:
signal tValidOut_mul      : std_logic;
signal inputA             : std_logic_vector(47 downto 0) := (others => '0');
signal outputProd         : std_logic_vector(79 downto 0);

-- accumulator singals
signal acc_rst            : std_logic := '1';
signal acc_rst_l          : std_logic := '1';


begin

-- assigning signals to array:
-- [					| run_mac | load_ram ]
-- [					|	1	  |	  0      ]
-- load_ram <= trigger_array(0);
-- run_mac <= trigger_array(1);

-- assign appropriate bits of iirData to inputA:
inputA(19 downto 0) <= iirData(19 downto 0); 	-- Real component mapping
inputA(43 downto 24) <= iirData(39 downto 20); 	-- Imag component mapping

acc_rst <= bool_to_std_logic(tValidOut_mul = '0' or run_mac = '0');
acc_rst_l <= acc_rst;


-- complex mul32by40, multiplies data from
-- IIR Filter with complex coefficients
myc_mul32by40 : entity work.c_mul32by40
  port map (
	aclk => clk,
    s_axis_a_tvalid => tValidIn_mul,
    s_axis_a_tdata => inputA,
    s_axis_b_tvalid => tValidIn_mul,
    s_axis_b_tdata => coefDataIn,
    m_axis_dout_tvalid => tValidOut_mul,
    m_axis_dout_tdata => outputProd
);


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


end architecture; -- arch