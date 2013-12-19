-- Copyright 2005 by Innovative Integration Inc., All Rights Reserved.

--************************************************************************
--* Design Name:    ii_dio
--*
--* @li Target Device:  generic
--* @li Tool versions:  ISE 10.1
--*
--*     @short Digital I/O
--*
--* Description:
--*   This component is a basic digital I/O component.  This is a simple
--*   latch from the data port. This component may be used as the starting point
--*   for more complex custom designs.
--*   Each configuration bit (dio_oe) sets the corresponding dio bit as output.
--*   The inputs are latched on each clock cycle, after demetastable circuit.
--*
--*     @generic width_io   : number of I/O bits
--*                         : equal to width_data when diff_en is TRUE
--*     @generic width_data : number of data bits to/from the host registers
--*     @port clk           : system clock
--*     @port dio_p         : diff-p digital input/output port
--*     @port dio_n         : diff-n digital input/output port
--*     @port host_dout     : host-driven output (ie. from host to I/O)
--*     @port host_din      : host-sampled input (ie. from I/O to host)
--*     @port dio_oe        : output enable configuration bits
--*     @port dio_wr        : write enable, update I/O pins
--*
--*     @author Innovative Integration
--*     @version 1.1
--*     @date Created 04/20/10
--*
--*
--************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity ii_dio is
  generic (
    width_io   : integer;
    width_data : integer
  );
  port (
    clk        : in    std_logic;                               -- system clock
    dio_p      : inout std_logic_vector(width_io-1 downto 0);   -- I/O
    dio_n      : inout std_logic_vector(width_io-1 downto 0);   -- I/O
    host_dout  : in    std_logic_vector(width_data-1 downto 0); -- host output
    host_din   : out   std_logic_vector(width_data-1 downto 0); -- host input
    dio_oe     : in    std_logic_vector(width_data-1 downto 0); -- enables
    dio_wr     : in    std_logic                                -- write strobe
  );
end ii_dio;

architecture arch of ii_dio is

  constant diff_en  : boolean := (width_io = width_data);
  signal dio        : std_logic_vector(width_data-1 downto 0);
  signal dio_out    : std_logic_vector(width_data-1 downto 0);
  signal dio_xdom   : std_logic_vector(width_data-1 downto 0);
  signal dio_demet  : std_logic_vector(width_data-1 downto 0);
  signal dio_oe_n   : std_logic_vector(width_data-1 downto 0);

begin

  --* Latch dio inputs, after demetastability circuit
  process (clk)
  begin
    if (rising_edge(clk)) then
      dio_xdom  <= dio;
      dio_demet <= dio_xdom;
      host_din  <= dio_demet;
    end if;
  end process;

  --* Write host data to the outputs, if configured as outputs
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (dio_wr = '1') then
        dio_out <= host_dout;
      end if;
    end if;
  end process;

  -- When T = 0, I is driven to IO/IOB
  -- When T = 1, IO/IOB is Z
  dio_oe_n <= not dio_oe;

------------------------------------------------------------------------------
-- The single ended dio_n/dio_p inputs are interleaved concatenated, 
-- so that dio_p is on even bits, dio_n is on odd bits.
-- ie.
-- ... dio_n(2) & dio_p(2) & dio_n(1) & dio_p(1) & dio_n(0) & dio_p(0)

  dio_single : if (diff_en = FALSE) generate

    dio_iobs : for j in 0 to width_io-1 generate

      iobuf_even_inst : IOBUF
      generic map (
        DRIVE            => 12,
        IBUF_DELAY_VALUE => "0",
        IFD_DELAY_VALUE  => "AUTO",
        IOSTANDARD       => "DEFAULT",
        SLEW             => "SLOW"
      )
      port map (
        O   => dio(j*2),
        IO  => dio_p(j),
        I   => dio_out(j*2),
        T   => dio_oe_n(j*2)
      );

      iobuf_odd_inst : IOBUF
      generic map (
        DRIVE            => 12,
        IBUF_DELAY_VALUE => "0",
        IFD_DELAY_VALUE  => "AUTO",
        IOSTANDARD       => "DEFAULT",
        SLEW             => "SLOW"
      )
      port map (
        O   => dio(j*2+1),
        IO  => dio_n(j),
        I   => dio_out(j*2+1),
        T   => dio_oe_n(j*2+1)
      );

    end generate;

  end generate;

------------------------------------------------------------------------------
  dio_diff : if (diff_en = TRUE) generate
    dio_iobs : for j in 0 to width_io-1 generate

      iobufds_inst : IOBUFDS
      generic map (
        IBUF_DELAY_VALUE => "0",
        IFD_DELAY_VALUE  => "AUTO",
        IOSTANDARD       => "LVDS_25"
      )
      port map (
        O   => dio(j),
        IO  => dio_p(j),
        IOB => dio_n(j),
        I   => dio_out(j),
        T   => dio_oe_n(j)
      );

    end generate;
  end generate;

end arch;

