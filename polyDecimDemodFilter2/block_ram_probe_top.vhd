library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all;

use IEEE.MATH_REAL.all;

entity block_ram_probe is
generic (
	data_width 		   : integer := 16;
	ram_depth 		   : integer := 4096;
	addr_width 		   : integer := 12
	);
  port (
	clk_in 			     : in std_logic;
	clk_out 		     : in std_logic;
	rst 			       : in std_logic;
	start_writing 	 : in std_logic;
	readAddr 		     : in unsigned(addr_width-1 downto 0);
	dataIn 			     : in std_logic_vector(data_width-1 downto 0) ;
	dataOut 		     : out std_logic_vector(data_width-1 downto 0) 
  ) ;

  attribute incremental_synthesis: string;
  attribute incremental_synthesis of block_ram_probe: entity is "yes";
  
end entity ; -- block_ram_probe

architecture arch of block_ram_probe is

-- ram signals
signal ramWriteEn 	: std_logic;
signal writeAddr 	: unsigned(addr_width-1 downto 0);

begin

clock_in_probe : process( clk_in,rst,start_writing )
begin
  if rst='1' then
      writeAddr <= (others => '0');
      ramWriteEn <= '0';
    elsif rising_edge(clk_in) then
    if start_writing='1' then
      ramWriteEn <= '1';
      writeAddr <= writeAddr + '1';
    else
      ramWriteEn <= '0';
    end if;
    if writeAddr=(ram_depth-1) then
        writeAddr <= writeAddr;    
    end if;
  end if;
end process; -- transfer_coef_mac

-- ----------------------------------------
-- Block Ram to probe individual modules
-- ----------------------------------------

myprobe : entity work.block_ram16
  port map (
    clka => clk_in,
    wea(0) => ramWriteEn,
    addra => std_logic_vector(writeAddr),
    dina => dataIn,
    clkb => clk_out,
    addrb => std_logic_vector(readAddr),
    doutb => dataOut
  );


end architecture ; -- arch