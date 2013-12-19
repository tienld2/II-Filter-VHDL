--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:34:34 09/05/2013
-- Design Name:   
-- Module Name:   /home/nick/polyDecimDemodFilter/polyDecimDemodFilter_Top_tb.vhd
-- Project Name:  polyDecimDemodFilter
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: polyDecimDemodFilter_Top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

 
ENTITY polyDecimDemodFilter_Top_tb IS
END polyDecimDemodFilter_Top_tb;
 
ARCHITECTURE behavior OF polyDecimDemodFilter_Top_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT polyDecimDemodFilter_Top
    PORT(
         clk : IN  std_logic;
         clk_enable : IN  std_logic;
         max_count : IN unsigned(3 downto 0);
         rst : IN  std_logic;
         tValidIn_Array : IN  std_logic_vector(15 downto 0);
         runSignals : IN  std_logic_vector(15 downto 0);
         numTaps : IN  std_logic_vector(4 downto 0);
         decimFactor : IN  real;
         reloadCoefData : IN  std_logic_vector(15 downto 0);
         phaseInc : IN  std_logic_vector(15 downto 0);
         inputSignal : IN  std_logic_vector(15 downto 0);
         -- -------------------------------------------------
         -- temporary signals -------------------------------
         datatoDemodTop : out std_logic_vector(15 downto 0) ;
         dataOutFromDemodRe : out std_logic_vector(31 downto 0) ;
         dataOutFromDemodIm  : out std_logic_vector(31 downto 0) ;
         -- temporary signals -------------------------------
         -- -------------------------------------------------
         outputDataRe : OUT  std_logic_vector(15 downto 0);
         outputDataIm : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;


   function cast_to_signed_int16(signal slv: std_logic_vector) return signed is
   begin
     return to_signed(to_integer(signed(slv)),16);
   end cast_to_signed_int16;

    
   --Inputs
   signal clk : std_logic := '0';
   signal clk_enable : std_logic := '0';
   signal clk_div : std_logic := '0';                         --   (samplingFreq / decimFactor) / 2
   signal max_count : unsigned(3 downto 0) := b"0001";   --   (100 MHz      / 4          ) / 2 = 12500000 
   signal rst : std_logic := '0';
   signal tValidIn_Array : std_logic_vector(15 downto 0) := (others => '0');
   signal runSignals : std_logic_vector(15 downto 0) := (others => '0');
   signal numTaps : std_logic_vector(4 downto 0) := (others => '0');
   signal decimFactor : real := 4.0;
   signal reloadCoefData : std_logic_vector(15 downto 0) := (others => '0');
   signal phaseInc : std_logic_vector(15 downto 0) := (others => '0');
   signal inputSignal : std_logic_vector(15 downto 0) := (others => '0');
   -- -------------------------------------------------
   -- temporary signals -------------------------------
   signal datatoDemodTop : std_logic_vector(15 downto 0) := (others => '0');
   signal dataOutFromDemodRe : std_logic_vector(31 downto 0) := (others => '0');
   signal dataOutFromDemodIm  : std_logic_vector(31 downto 0) := (others => '0');
   -- temporary signals -------------------------------
   -- -------------------------------------------------


  -- Constants
  constant inputSize : integer := 4095;

 	--Outputs
   signal outputDataRe : std_logic_vector(15 downto 0);
   signal outputDataIm : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant clk_enable_period : time := 10 ns;

    -- clock divided clock:
    signal clk_div_counter : integer := 0;
    signal clk_div_temp : std_logic := '1';


  type input_array is array (inputSize downto 0) of std_logic_vector(15 downto 0) ;
		signal myCosine : input_array :=(x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"58C8",x"5834",x"579E",x"5708",x"5670",x"55D8",x"553F",x"54A5",x"540A",x"536E",x"52D2",x"5234",x"5196",x"50F7",x"5057",x"4FB6",x"4F15",x"4E73",x"4DD0",x"4D2C",x"4C87",x"4BE2",x"4B3B",x"4A95",x"49ED",x"4944",x"489B",x"47F1",x"4747",x"469B",x"45EF",x"4542",x"4495",x"43E7",x"4338",x"4288",x"41D8",x"4127",x"4076",x"3FC4",x"3F11",x"3E5D",x"3DA9",x"3CF4",x"3C3F",x"3B89",x"3AD3",x"3A1B",x"3964",x"38AB",x"37F2",x"3739",x"367F",x"35C4",x"3509",x"344E",x"3392",x"32D5",x"3218",x"315A",x"309C",x"2FDD",x"2F1E",x"2E5E",x"2D9E",x"2CDD",x"2C1C",x"2B5B",x"2A99",x"29D7",x"2914",x"2851",x"278D",x"26C9",x"2605",x"2540",x"247B",x"23B5",x"22EF",x"2229",x"2162",x"209C",x"1FD4",x"1F0D",x"1E45",x"1D7D",x"1CB4",x"1BEB",x"1B22",x"1A59",x"198F",x"18C6",x"17FB",x"1731",x"1666",x"159C",x"14D1",x"1405",x"133A",x"126E",x"11A2",x"10D6",x"100A",x"0F3E",x"0E71",x"0DA5",x"0CD8",x"0C0B",x"0B3E",x"0A71",x"09A4",x"08D6",x"0809",x"073B",x"066E",x"05A0",x"04D2",x"0405",x"0337",x"0269",x"019B",x"00CD",x"0000",x"FF33",x"FE65",x"FD97",x"FCC9",x"FBFB",x"FB2E",x"FA60",x"F992",x"F8C5",x"F7F7",x"F72A",x"F65C",x"F58F",x"F4C2",x"F3F5",x"F328",x"F25B",x"F18F",x"F0C2",x"EFF6",x"EF2A",x"EE5E",x"ED92",x"ECC6",x"EBFB",x"EB2F",x"EA64",x"E99A",x"E8CF",x"E805",x"E73A",x"E671",x"E5A7",x"E4DE",x"E415",x"E34C",x"E283",x"E1BB",x"E0F3",x"E02C",x"DF64",x"DE9E",x"DDD7",x"DD11",x"DC4B",x"DB85",x"DAC0",x"D9FB",x"D937",x"D873",x"D7AF",x"D6EC",x"D629",x"D567",x"D4A5",x"D3E4",x"D323",x"D262",x"D1A2",x"D0E2",x"D023",x"CF64",x"CEA6",x"CDE8",x"CD2B",x"CC6E",x"CBB2",x"CAF7",x"CA3C",x"C981",x"C8C7",x"C80E",x"C755",x"C69C",x"C5E5",x"C52D",x"C477",x"C3C1",x"C30C",x"C257",x"C1A3",x"C0EF",x"C03C",x"BF8A",x"BED9",x"BE28",x"BD78",x"BCC8",x"BC19",x"BB6B",x"BABE",x"BA11",x"B965",x"B8B9",x"B80F",x"B765",x"B6BC",x"B613",x"B56B",x"B4C5",x"B41E",x"B379",x"B2D4",x"B230",x"B18D",x"B0EB",x"B04A",x"AFA9",x"AF09",x"AE6A",x"ADCC",x"AD2E",x"AC92",x"ABF6",x"AB5B",x"AAC1",x"AA28",x"A990",x"A8F8",x"A862",x"A7CC",x"A738",x"A6A4",x"A611",x"A57F",x"A4EE",x"A45D",x"A3CE",x"A340",x"A2B2",x"A226",x"A19A",x"A110",x"A086",x"9FFE",x"9F76",x"9EEF",x"9E6A",x"9DE5",x"9D61",x"9CDE",x"9C5D",x"9BDC",x"9B5C",x"9ADD",x"9A60",x"99E3",x"9968",x"98ED",x"9873",x"97FB",x"9784",x"970D",x"9698",x"9624",x"95B0",x"953E",x"94CD",x"945D",x"93EE",x"9381",x"9314",x"92A8",x"923E",x"91D5",x"916C",x"9105",x"909F",x"903A",x"8FD7",x"8F74",x"8F12",x"8EB2",x"8E53",x"8DF5",x"8D98",x"8D3C",x"8CE2",x"8C88",x"8C30",x"8BD9",x"8B83",x"8B2E",x"8ADB",x"8A88",x"8A37",x"89E7",x"8998",x"894B",x"88FF",x"88B3",x"8869",x"8821",x"87D9",x"8793",x"874E",x"870A",x"86C7",x"8685",x"8645",x"8606",x"85C8",x"858C",x"8551",x"8517",x"84DE",x"84A6",x"8470",x"843B",x"8407",x"83D4",x"83A3",x"8373",x"8344",x"8317",x"82EA",x"82BF",x"8296",x"826D",x"8246",x"8220",x"81FB",x"81D8",x"81B6",x"8195",x"8175",x"8157",x"813A",x"811E",x"8104",x"80EB",x"80D3",x"80BC",x"80A7",x"8093",x"8080",x"806F",x"805F",x"8050",x"8042",x"8036",x"802B",x"8021",x"8019",x"8012",x"800C",x"8007",x"8004",x"8002",x"8001",x"8002",x"8004",x"8007",x"800C",x"8012",x"8019",x"8021",x"802B",x"8036",x"8042",x"8050",x"805F",x"806F",x"8080",x"8093",x"80A7",x"80BC",x"80D3",x"80EB",x"8104",x"811E",x"813A",x"8157",x"8175",x"8195",x"81B6",x"81D8",x"81FB",x"8220",x"8246",x"826D",x"8296",x"82BF",x"82EA",x"8317",x"8344",x"8373",x"83A3",x"83D4",x"8407",x"843B",x"8470",x"84A6",x"84DE",x"8517",x"8551",x"858C",x"85C8",x"8606",x"8645",x"8685",x"86C7",x"870A",x"874E",x"8793",x"87D9",x"8821",x"8869",x"88B3",x"88FF",x"894B",x"8998",x"89E7",x"8A37",x"8A88",x"8ADB",x"8B2E",x"8B83",x"8BD9",x"8C30",x"8C88",x"8CE2",x"8D3C",x"8D98",x"8DF5",x"8E53",x"8EB2",x"8F12",x"8F74",x"8FD7",x"903A",x"909F",x"9105",x"916C",x"91D5",x"923E",x"92A8",x"9314",x"9381",x"93EE",x"945D",x"94CD",x"953E",x"95B0",x"9624",x"9698",x"970D",x"9784",x"97FB",x"9873",x"98ED",x"9968",x"99E3",x"9A60",x"9ADD",x"9B5C",x"9BDC",x"9C5D",x"9CDE",x"9D61",x"9DE5",x"9E6A",x"9EEF",x"9F76",x"9FFE",x"A086",x"A110",x"A19A",x"A226",x"A2B2",x"A340",x"A3CE",x"A45D",x"A4EE",x"A57F",x"A611",x"A6A4",x"A738",x"A7CC",x"A862",x"A8F8",x"A990",x"AA28",x"AAC1",x"AB5B",x"ABF6",x"AC92",x"AD2E",x"ADCC",x"AE6A",x"AF09",x"AFA9",x"B04A",x"B0EB",x"B18D",x"B230",x"B2D4",x"B379",x"B41E",x"B4C5",x"B56B",x"B613",x"B6BC",x"B765",x"B80F",x"B8B9",x"B965",x"BA11",x"BABE",x"BB6B",x"BC19",x"BCC8",x"BD78",x"BE28",x"BED9",x"BF8A",x"C03C",x"C0EF",x"C1A3",x"C257",x"C30C",x"C3C1",x"C477",x"C52D",x"C5E5",x"C69C",x"C755",x"C80E",x"C8C7",x"C981",x"CA3C",x"CAF7",x"CBB2",x"CC6E",x"CD2B",x"CDE8",x"CEA6",x"CF64",x"D023",x"D0E2",x"D1A2",x"D262",x"D323",x"D3E4",x"D4A5",x"D567",x"D629",x"D6EC",x"D7AF",x"D873",x"D937",x"D9FB",x"DAC0",x"DB85",x"DC4B",x"DD11",x"DDD7",x"DE9E",x"DF64",x"E02C",x"E0F3",x"E1BB",x"E283",x"E34C",x"E415",x"E4DE",x"E5A7",x"E671",x"E73A",x"E805",x"E8CF",x"E99A",x"EA64",x"EB2F",x"EBFB",x"ECC6",x"ED92",x"EE5E",x"EF2A",x"EFF6",x"F0C2",x"F18F",x"F25B",x"F328",x"F3F5",x"F4C2",x"F58F",x"F65C",x"F72A",x"F7F7",x"F8C5",x"F992",x"FA60",x"FB2E",x"FBFB",x"FCC9",x"FD97",x"FE65",x"FF33",x"0000",x"00CD",x"019B",x"0269",x"0337",x"0405",x"04D2",x"05A0",x"066E",x"073B",x"0809",x"08D6",x"09A4",x"0A71",x"0B3E",x"0C0B",x"0CD8",x"0DA5",x"0E71",x"0F3E",x"100A",x"10D6",x"11A2",x"126E",x"133A",x"1405",x"14D1",x"159C",x"1666",x"1731",x"17FB",x"18C6",x"198F",x"1A59",x"1B22",x"1BEB",x"1CB4",x"1D7D",x"1E45",x"1F0D",x"1FD4",x"209C",x"2162",x"2229",x"22EF",x"23B5",x"247B",x"2540",x"2605",x"26C9",x"278D",x"2851",x"2914",x"29D7",x"2A99",x"2B5B",x"2C1C",x"2CDD",x"2D9E",x"2E5E",x"2F1E",x"2FDD",x"309C",x"315A",x"3218",x"32D5",x"3392",x"344E",x"3509",x"35C4",x"367F",x"3739",x"37F2",x"38AB",x"3964",x"3A1B",x"3AD3",x"3B89",x"3C3F",x"3CF4",x"3DA9",x"3E5D",x"3F11",x"3FC4",x"4076",x"4127",x"41D8",x"4288",x"4338",x"43E7",x"4495",x"4542",x"45EF",x"469B",x"4747",x"47F1",x"489B",x"4944",x"49ED",x"4A95",x"4B3B",x"4BE2",x"4C87",x"4D2C",x"4DD0",x"4E73",x"4F15",x"4FB6",x"5057",x"50F7",x"5196",x"5234",x"52D2",x"536E",x"540A",x"54A5",x"553F",x"55D8",x"5670",x"5708",x"579E",x"5834",x"58C8",x"595C",x"59EF",x"5A81",x"5B12",x"5BA3",x"5C32",x"5CC0",x"5D4E",x"5DDA",x"5E66",x"5EF0",x"5F7A",x"6002",x"608A",x"6111",x"6196",x"621B",x"629F",x"6322",x"63A3",x"6424",x"64A4",x"6523",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000");		

BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: polyDecimDemodFilter_Top PORT MAP (
          clk => clk,
          clk_enable => clk_enable,
          max_count => max_count,
          rst => rst,
          tValidIn_Array => tValidIn_Array,
          runSignals => runSignals,
          numTaps => numTaps,
          decimFactor => decimFactor,
          reloadCoefData => reloadCoefData,
          phaseInc => phaseInc,
          inputSignal => inputSignal,
          -- -------------------------------------------------
          -- temporary signals -------------------------------
          datatoDemodTop => datatoDemodTop,
          dataOutFromDemodRe => dataOutFromDemodRe,
          dataOutFromDemodIm => dataOutFromDemodIm,
          -- temporary signals -------------------------------
          -- -------------------------------------------------
          outputDataRe => outputDataRe,
          outputDataIm => outputDataIm
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   clk_enable_process :process
   begin
		clk_enable <= '0';
		wait for clk_enable_period/2;
		clk_enable <= '1';
		wait for clk_enable_period/2;
   end process;


   -- ------------------------------------------------------------------------------------------------------
   --                                       temporary signals 
   -- ------------------------------------------------------------------------------------------------------
   output_filedatatoDemodTop : entity work.file_writer 
   generic map( 
     dataWidth => 16,
     wordWidth => 1,
     -- dataFrac => 15,
     fileName => "/home/nick/polyDecimDemodFilter/datatoDemodTopoutput25MHz.dat"
   )
   port map( 
     reset => rst,
     clk => clk_div,
     enable => tValidIn_Array(0),
     data => datatoDemodTop,
     data_valid => tValidIn_Array(0)
   );

   output_filedataDemodReoutput : entity work.file_writer 
   generic map( 
     dataWidth => 32,
     wordWidth => 1,
     -- dataFrac => 15,
     fileName => "/home/nick/polyDecimDemodFilter/dataDemodReoutput25MHz.dat"
   )
   port map( 
     reset => rst,
     clk => clk_div,
     enable => tValidIn_Array(0),
     data => dataOutFromDemodRe,-- to_slv(to_SFix(dataOutFromDemodRe(31 downto 16),16,15)),
     data_valid => tValidIn_Array(0)
   );

   output_filedataDemodImoutput : entity work.file_writer 
   generic map( 
     dataWidth => 32,
     wordWidth => 1,
     -- dataFrac => 15,
     fileName => "/home/nick/polyDecimDemodFilter/dataDemodImoutput25MHz.dat"
   )
   port map( 
     reset => rst,
     clk => clk_div,
     enable => tValidIn_Array(0),
     data => dataOutFromDemodIm,--to_slv(to_SFix(dataOutFromDemodIm(31 downto 16),16,15)),
     data_valid => tValidIn_Array(0)
   );
   -- ------------------------------------------------------------------------------------------------------
   -- ------------------------------------------------------------------------------------------------------



   -- clk for file writer from iir filters:
   my_clk_div : entity work.clk_div_top
    port map(
      max_count => max_count,
      clk_in => clk,
      rst => rst,
      clk_out => clk_div
    ) ;

  output_fileCos : entity work.file_writer 
  generic map( 
    dataWidth => 16,
    wordWidth => 1,
    -- dataFrac => 15,
    fileName => "/home/nick/polyDecimDemodFilter/cosoutput25MHz.dat"
  )
  port map( 
    reset => rst,
    clk => clk_div,
    enable => tValidIn_Array(0),
    data => inputSignal,
    data_valid => tValidIn_Array(0)
  );


  -- ------------------------------------------------------------------------------------------------------
  --                        plotted with plotChannelizer.py
  -- ------------------------------------------------------------------------------------------------------

  output_fileRe : entity work.file_writer 
  generic map( 
    dataWidth => 16,
    wordWidth => 1,
    -- dataFrac => 10,
    fileName => "/home/nick/polyDecimDemodFilter/polyDecimDemodFilterReoutput25MHz.dat"
  )
  port map( 
    reset => rst,
    clk => clk_div,
    enable => tValidIn_Array(0),
    data => outputDataRe,
    data_valid => tValidIn_Array(0)
  );

  output_fileIm : entity work.file_writer 
  generic map( 
    dataWidth => 16,
    wordWidth => 1,
    -- dataFrac => 10,
    fileName => "/home/nick/polyDecimDemodFilter/polyDecimDemodFilterImoutput25MHz.dat"
  )
  port map( 
    reset => rst,
    clk => clk_div,
    enable => tValidIn_Array(0),
    data => outputDataIm,
    data_valid => tValidIn_Array(0)
  );

  -- ------------------------------------------------------------------------------------------------------
  -- ------------------------------------------------------------------------------------------------------



   -- Stimulus process
   stim_proc: process
   begin		

      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;

      -- insert, stimulus here 
      -- pulse the reset line:
      rst <= '1'; wait until (rising_edge(clk));
      wait for clk_period*4;
      rst <= '0'; wait until (rising_edge(clk));
      report "System reset with global signal rst.\n";


      -- feed data into polyDecimator, start filtering:
      tValidIn_Array(0) <= '1'; wait until (rising_edge(clk));
      runSignals(0) <= '1'; wait until (rising_edge(clk));
      report "polyDecimator triggered, transmitting data to filter now...\n";

      tValidIn_Array(1) <= '1';
						phaseInc <= x"0106"; wait until (rising_edge(clk));						

      for i in 0 to inputSize loop
        inputSignal <= myCosine(i); wait until (rising_edge(clk)); 
      end loop;



      -- initiate demodulator when signal available from filter, set phaseInc:
      

      report "Setting phaseInc to 0x0CCC, initiating demodulator...\n";

      report "Finished processing.";

      wait;
   end process;

END;
