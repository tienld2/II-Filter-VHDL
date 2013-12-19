library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ClockDivider is
  generic	(
  	divideConstant : natural);
  port (
    RST : in std_logic;
  	fastClock : in std_logic;
  	slowClock : out std_logic
  );
end entity ; -- ClockDivider

architecture arch of ClockDivider is

signal outClock : std_logic;

begin

slowClock <= outClock;

clkDivider : process( RST, fastClock )
	variable count : natural := 0;
begin
	if RST = '1' then
		outClock <= '0';
		count := 0;
	elsif rising_edge(fastClock) then
		count := count+1;
		if count = divideConstant then
			count := 0;
			outClock <= not outClock;
		else
			outClock <= outClock;
		end if ;
	end if ;
end process ; -- clkDivider



end architecture ; -- arch


