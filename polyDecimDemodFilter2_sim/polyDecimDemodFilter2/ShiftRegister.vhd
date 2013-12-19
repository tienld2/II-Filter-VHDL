library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_arith.all ; 
use IEEE.std_logic_unsigned.all ;



entity ShiftRegister is
	generic (n: integer := 1);
	port (
		RESET : in std_logic;
		CLK : in std_logic;
		d : in std_logic;
		q : out std_logic
	) ;
end entity ; -- ShiftRegister

architecture arch of ShiftRegister is

signal reg: std_logic_vector(n-1 downto 0) ;

begin
	shifter : process( RESET, CLK, d )
	begin
		if RESET = '1' then
			reg <= (others => '0');
		elsif rising_edge(CLK) then
				reg <= d & reg(reg'LEFT downto 1);
		end if;
	end process ; -- shifter

	q <= reg(0);

end architecture ; -- arch