library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all ;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use IEEE.MATH_REAL.all;


entity decimate is
generic(
	decimFactor : integer := 3;
	dataIn_width : integer := 16;
	dataOut_width : integer := 16
	);
  port (
	clk : in std_logic;
	rst : in std_logic;
	dataIn : in std_logic_vector(dataIn_width-1 downto 0) ;
	dataOut : out std_logic_vector(dataOut_width-1 downto 0) 
  ) ;
end entity ; -- decimate

architecture arch of decimate is

-- number of bits for counter register
constant delay_bits : real := LOG2(real(decimFactor));
-- register to count decimFactor samples
signal delay_register : unsigned(delay_bits downto 0) ;

begin

-- process to take decimFactor
-- samples from input and
-- pipe them to output
decim : process( clk,rst )
begin
	if rst='1' then
		dataOut <= (others => '0');
		delay_register <= (others => '0');
	elsif rising_edge(clk) then
		delay_register <= delay_register + 1;
		if delay_register=(decimFactor-1) then
			dataOut <= dataIn;
			delay_register <= (others => '0');
		end if ;
	end if ;
end process ; -- decim


end architecture ; -- arch