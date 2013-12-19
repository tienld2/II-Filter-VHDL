-- ----------------------------------------------------------------------------------
-- -- Company: 
-- -- Engineer: 
-- -- 
-- -- Create Date:    17:21:18 07/23/2013 
-- -- Design Name: 
-- -- Module Name:    file_reader - Behavioral 
-- -- Project Name: 
-- -- Target Devices: 
-- -- Tool versions: 
-- -- Description: 
-- --
-- -- Dependencies: 
-- --
-- -- Revision: 
-- -- Revision 0.01 - File Created
-- -- Additional Comments: 
-- --
-- ----------------------------------------------------------------------------------
-- library IEEE;
-- use IEEE.STD_LOGIC_1164.ALL;

-- -- Uncomment the following library declaration if using
-- -- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.ALL;

-- -- Uncomment the following library declaration if instantiating
-- -- any Xilinx primitives in this code.
-- --library UNISIM;
-- --use UNISIM.VComponents.all;

-- use std.textio.all;


-- library ieee_proposed;
-- use ieee_proposed.fixed_float_types.all;
-- use ieee_proposed.fixed_pkg.all;

-- -- use work.common_functions.all;


-- entity file_writer is
-- 	generic ( 
-- 		wordWidth : natural := 4;
-- 		dataWidth : natural := 16;
-- 		dataFrac : natural := 10;
-- 		fileName : string
-- 	);
-- 	port( 
-- 		reset : in std_logic;
-- 		clk : in  std_logic;
-- 		enable : in  std_logic;
-- 		data : in std_logic_vector(wordWidth*dataWidth-1 downto 0);
-- 		data_valid : in std_logic
-- 	);
-- end file_writer;

-- architecture Behavioral of file_writer is


-- file outfile: TEXT open write_mode is fileName;
-- signal line_cnt : natural range 0 to 32000;

-- begin
-- -- read data and control information from a file


-- write_data: process(reset,clk, enable, data_valid)
-- variable  line  : line;   --line number declaration  
-- variable i : integer;
-- variable myVar : UNRESOLVED_sfixed(dataWidth-1 downto 0);
-- begin                                       
-- 	if reset = '1' then
-- 		line_cnt <= 0;
-- 	elsif rising_edge(clk) and enable = '1' and data_valid = '1' then
-- 			for cnt in 0 to (wordWidth-1) loop
-- 				-- i := to_integer(data((cnt+1)*dataWidth-1 downto cnt*dataWidth));
-- 				myVar := to_SFix(data((cnt+1)*dataWidth-1 downto cnt*dataWidth),dataWidth,dataFrac);
-- 				-- write(line, i, right, 16);
-- 				write(line,myVar);
-- 				writeline(outfile, line);
-- 				line_cnt <= line_cnt + 1;
-- 			end loop;
--    end if;
--  end process;

-- end Behavioral;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:21:18 07/23/2013 
-- Design Name: 
-- Module Name:    file_reader - Behavioral 
-- Project Name: 
-- Target Devices: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use std.textio.all;
use ieee.std_logic_textio.all;
-- use work.common_functions.all;


entity file_writer is
	generic ( 
		wordWidth : natural := 4;
		dataWidth : natural := 16;
		fileName : string	:= "./"
	);
	port( 
		reset : in std_logic;
		clk : in  std_logic;
		enable : in  std_logic;
		data : in std_logic_vector(wordWidth*dataWidth-1 downto 0);
		data_valid : in std_logic
	);
end file_writer;

architecture Behavioral of file_writer is

file outfile: TEXT open write_mode is fileName;
signal line_cnt : natural range 0 to 32000;

begin
-- read data and control information from a file


write_data: process(reset,clk, enable, data_valid)
variable  line  : line;   --line number declaration  
variable i : integer :=0;
-- variable i : std_logic_vector(dataWidth-1 downto 0) ;
begin                                       
	if reset = '1' then
		line_cnt <= 0;
	elsif rising_edge(clk) and enable = '1' and data_valid = '1' then
			for cnt in 0 to (wordWidth-1) loop
				-- i := to_integer(unsigned(data((cnt+1)*dataWidth-1 downto cnt*dataWidth)));
				i := to_integer(signed(data((cnt+1)*dataWidth-1 downto cnt*dataWidth)));
				write(line, i);
				writeline(outfile, line);
				line_cnt <= line_cnt + 1;
			end loop;
   end if;
 end process;

end Behavioral;
