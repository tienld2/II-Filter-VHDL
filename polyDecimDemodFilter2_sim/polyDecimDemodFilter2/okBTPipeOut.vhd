--------------------------------------------------------------------------
-- okBTPipeOut.vhd
--
-- This entity simulates the "Block Throttled Output Pipe" endpoint.
--
--------------------------------------------------------------------------
-- Copyright (c) 2005-2010 Opal Kelly Incorporated
-- $Rev: 591 $ $Date: 2010-10-05 21:31:38 -0700 (Tue, 05 Oct 2010) $
--------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use work.parameters.all;
use work.mappings.all;

entity okBTPipeOut is
	port (
		ok1            : in   std_logic_vector(30 downto 0);
		ok2            : out  std_logic_vector(16 downto 0);
		ep_addr        : in   std_logic_vector(7 downto 0);
		ep_read        : out  std_logic;
		ep_blockstrobe : out  std_logic;
		ep_datain      : in   std_logic_vector(15 downto 0);
		ep_ready       : in   std_logic);
end okBTPipeOut;

architecture arch of okBTPipeOut is
	signal ti_read        : std_logic;
	signal ti_addr        : std_logic_vector(7 downto 0);
	signal ti_blockstrobe : std_logic;
	
begin
	ti_read          <= ok1(OK_TI_READ);
	ti_addr          <= ok1(OK_TI_ADDR_END downto OK_TI_ADDR_START);
	ti_blockstrobe   <= ok1(OK_TI_BLOCKSTROBE);
	
	ok2(OK_DATAOUT_END downto OK_DATAOUT_START) <= ep_datain when (ti_addr = ep_addr) else (others => '0');
	ok2(OK_READY) <= ep_ready when (ti_addr = ep_addr) else '0';
	ep_read <= '1' when ((ti_read = '1') and (ti_addr = ep_addr)) else '0';
	ep_blockstrobe <= '1' when ((ti_blockstrobe = '1') and (ti_addr = ep_addr)) else '0';
	
end arch;