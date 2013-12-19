LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;

entity clk_div_top is
  port (
  	max_count : in unsigned(3 downto 0);	-- 4-bit value = (clock cycles - 3)
	clk_in : in std_logic;
	rst : in std_logic;
	clk_out : out std_logic
  ) ;
end entity ; -- clk_div_top


architecture arch of clk_div_top is

-- counter and temp_clk:
signal clk_div_counter : unsigned(3 downto 0) := (others => '0');
signal temp_clk : std_logic := '0';

begin

	clk_out <= temp_clk;

	clk_div_gen : process( clk_in, rst, temp_clk )
	begin
		if rising_edge(clk_in) then
			clk_div_counter <= clk_div_counter + "1";
			if clk_div_counter=max_count then
				clk_div_counter <= (others => '0');	
				temp_clk <= not temp_clk;	
			end if ;
		end if ;
	end process clk_div_gen; -- clk_div_gen



end architecture ; -- arch