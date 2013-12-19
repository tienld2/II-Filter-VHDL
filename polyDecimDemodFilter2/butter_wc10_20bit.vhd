-- -------------------------------------------------------------
--
-- Module: butter_wc10_20bit
-- Generated by MATLAB(R) 8.1 and the Filter Design HDL Coder 2.9.3.
-- Generated on: 2013-09-26 11:31:25
-- -------------------------------------------------------------

-- -------------------------------------------------------------
-- HDL Code Generation Options:
--
-- TargetLanguage: VHDL
-- TargetDirectory: /home/MQCO/matlab_iirFilter
-- Name: butter_wc10_20bit
-- InputComplex: on
-- TestBenchName: butter_wc10_20bit_tb
-- TestBenchStimulus: impulse step 

-- Filter Specifications:
--
-- Sampling Frequency : N/A (normalized frequency)
-- Response           : Lowpass
-- Specification      : N,F3dB
-- Filter Order       : 5
-- 3-dB Point         : 0.08
-- -------------------------------------------------------------

-- -------------------------------------------------------------
-- HDL Implementation    : Fully parallel
-- Multipliers           : 8
-- Folding Factor        : 1
-- -------------------------------------------------------------
-- Filter Settings:
--
-- Discrete-Time IIR Filter (real)
-- -------------------------------
-- Filter Structure    : Direct-Form II, Second-Order Sections
-- Number of Sections  : 3
-- Stable              : Yes
-- Linear Phase        : No
-- Arithmetic          : fixed
-- Numerator           : s16,13 -> [-4 4)
-- Denominator         : s16,14 -> [-2 2)
-- Scale Values        : s16,18 -> [-1.250000e-01 1.250000e-01)
-- Input               : s20,19 -> [-1 1)
-- Section Input       : s16,12 -> [-8 8)
-- Section Output      : s16,10 -> [-32 32)
-- Output              : s20,14 -> [-32 32)
-- State               : s16,15 -> [-1 1)
-- Numerator Prod      : s32,28 -> [-8 8)
-- Denominator Prod    : s32,29 -> [-4 4)
-- Numerator Accum     : s40,28 -> [-2048 2048)
-- Denominator Accum   : s40,29 -> [-1024 1024)
-- Round Mode          : convergent
-- Overflow Mode       : wrap
-- Cast Before Sum     : true
-- -------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.ALL;

ENTITY butter_wc10_20bit IS
   PORT( clk                             :   IN    std_logic; 
         clk_enable                      :   IN    std_logic; 
         reset                           :   IN    std_logic; 
         filter_in_re                    :   IN    std_logic_vector(19 DOWNTO 0); -- sfix20_En19
         filter_in_im                    :   IN    std_logic_vector(19 DOWNTO 0); -- sfix20_En19
         filter_out_re                   :   OUT   std_logic_vector(19 DOWNTO 0); -- sfix20_En14
         filter_out_im                   :   OUT   std_logic_vector(19 DOWNTO 0)  -- sfix20_En14
         );

END butter_wc10_20bit;


----------------------------------------------------------------
--Module Architecture: butter_wc10_20bit
----------------------------------------------------------------
ARCHITECTURE rtl OF butter_wc10_20bit IS
  -- Local Functions
  -- Type Definitions
  TYPE delay_pipeline_type IS ARRAY (NATURAL range <>) OF signed(15 DOWNTO 0); -- sfix16_En15
  -- Constants
  CONSTANT scaleconst1                    : signed(15 DOWNTO 0) := to_signed(3824, 16); -- sfix16_En18
  CONSTANT coeff_b1_section1              : signed(15 DOWNTO 0) := to_signed(8192, 16); -- sfix16_En13
  CONSTANT coeff_b2_section1              : signed(15 DOWNTO 0) := to_signed(16384, 16); -- sfix16_En13
  CONSTANT coeff_b3_section1              : signed(15 DOWNTO 0) := to_signed(8192, 16); -- sfix16_En13
  CONSTANT coeff_a2_section1              : signed(15 DOWNTO 0) := to_signed(-29474, 16); -- sfix16_En14
  CONSTANT coeff_a3_section1              : signed(15 DOWNTO 0) := to_signed(14046, 16); -- sfix16_En14
  CONSTANT scaleconst2                    : signed(15 DOWNTO 0) := to_signed(3428, 16); -- sfix16_En18
  CONSTANT coeff_b1_section2              : signed(15 DOWNTO 0) := to_signed(8192, 16); -- sfix16_En13
  CONSTANT coeff_b2_section2              : signed(15 DOWNTO 0) := to_signed(16384, 16); -- sfix16_En13
  CONSTANT coeff_b3_section2              : signed(15 DOWNTO 0) := to_signed(8192, 16); -- sfix16_En13
  CONSTANT coeff_a2_section2              : signed(15 DOWNTO 0) := to_signed(-26422, 16); -- sfix16_En14
  CONSTANT coeff_a3_section2              : signed(15 DOWNTO 0) := to_signed(10896, 16); -- sfix16_En14
  CONSTANT scaleconst3                    : signed(15 DOWNTO 0) := to_signed(29402, 16); -- sfix16_En18
  CONSTANT coeff_b1_section3              : signed(15 DOWNTO 0) := to_signed(8192, 16); -- sfix16_En13
  CONSTANT coeff_b2_section3              : signed(15 DOWNTO 0) := to_signed(8192, 16); -- sfix16_En13
  CONSTANT coeff_b3_section3              : signed(15 DOWNTO 0) := to_signed(0, 16); -- sfix16_En13
  CONSTANT coeff_a2_section3              : signed(15 DOWNTO 0) := to_signed(-12709, 16); -- sfix16_En14
  CONSTANT coeff_a3_section3              : signed(15 DOWNTO 0) := to_signed(0, 16); -- sfix16_En14
  -- Signals
  SIGNAL input_register_re                : signed(19 DOWNTO 0); -- sfix20_En19
  SIGNAL input_register_im                : signed(19 DOWNTO 0); -- sfix20_En19
  SIGNAL scale1_re                        : signed(40 DOWNTO 0); -- sfix41_En37
  SIGNAL scale1_im                        : signed(40 DOWNTO 0); -- sfix41_En37
  SIGNAL mul_temp                         : signed(35 DOWNTO 0); -- sfix36_En37
  SIGNAL mul_temp_1                       : signed(35 DOWNTO 0); -- sfix36_En37
  SIGNAL scaletypeconvert1_re             : signed(15 DOWNTO 0); -- sfix16_En12
  SIGNAL scaletypeconvert1_im             : signed(15 DOWNTO 0); -- sfix16_En12
  -- Section 1 Signals 
  SIGNAL a1sum1_re                        : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL a1sum1_im                        : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL a2sum1_re                        : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL a2sum1_im                        : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL b1sum1_re                        : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL b1sum1_im                        : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL b2sum1_re                        : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL b2sum1_im                        : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL typeconvert1_re                  : signed(15 DOWNTO 0); -- sfix16_En15
  SIGNAL typeconvert1_im                  : signed(15 DOWNTO 0); -- sfix16_En15
  SIGNAL delay_section1_re                : delay_pipeline_type(0 TO 1); -- sfix16_En15
  SIGNAL delay_section1_im                : delay_pipeline_type(0 TO 1); -- sfix16_En15
  SIGNAL inputconv1_re                    : signed(15 DOWNTO 0); -- sfix16_En12
  SIGNAL inputconv1_im                    : signed(15 DOWNTO 0); -- sfix16_En12
  SIGNAL a2mul1_re                        : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL a2mul1_im                        : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL a3mul1_re                        : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL a3mul1_im                        : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL b1mul1_re                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b1mul1_im                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b2mul1_re                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b2mul1_im                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b3mul1_re                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b3mul1_im                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL sub_cast                         : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_1                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp                         : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL sub_cast_2                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_3                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp_1                       : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL sub_cast_4                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_5                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp_2                       : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL sub_cast_6                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_7                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp_3                       : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL b1multypeconvert1_re             : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL b1multypeconvert1_im             : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast                         : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_1                       : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_temp                         : signed(40 DOWNTO 0); -- sfix41_En28
  SIGNAL add_cast_2                       : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_3                       : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_temp_1                       : signed(40 DOWNTO 0); -- sfix41_En28
  SIGNAL add_cast_4                       : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_5                       : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_temp_2                       : signed(40 DOWNTO 0); -- sfix41_En28
  SIGNAL add_cast_6                       : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_7                       : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_temp_3                       : signed(40 DOWNTO 0); -- sfix41_En28
  SIGNAL section_result1_re               : signed(15 DOWNTO 0); -- sfix16_En10
  SIGNAL section_result1_im               : signed(15 DOWNTO 0); -- sfix16_En10
  SIGNAL scale2_re                        : signed(40 DOWNTO 0); -- sfix41_En37
  SIGNAL scale2_im                        : signed(40 DOWNTO 0); -- sfix41_En37
  SIGNAL mul_temp_2                       : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL mul_temp_3                       : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL scaletypeconvert2_re             : signed(15 DOWNTO 0); -- sfix16_En12
  SIGNAL scaletypeconvert2_im             : signed(15 DOWNTO 0); -- sfix16_En12
  -- Section 2 Signals 
  SIGNAL a1sum2_re                        : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL a1sum2_im                        : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL a2sum2_re                        : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL a2sum2_im                        : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL b1sum2_re                        : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL b1sum2_im                        : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL b2sum2_re                        : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL b2sum2_im                        : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL typeconvert2_re                  : signed(15 DOWNTO 0); -- sfix16_En15
  SIGNAL typeconvert2_im                  : signed(15 DOWNTO 0); -- sfix16_En15
  SIGNAL delay_section2_re                : delay_pipeline_type(0 TO 1); -- sfix16_En15
  SIGNAL delay_section2_im                : delay_pipeline_type(0 TO 1); -- sfix16_En15
  SIGNAL inputconv2_re                    : signed(15 DOWNTO 0); -- sfix16_En12
  SIGNAL inputconv2_im                    : signed(15 DOWNTO 0); -- sfix16_En12
  SIGNAL a2mul2_re                        : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL a2mul2_im                        : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL a3mul2_re                        : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL a3mul2_im                        : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL b1mul2_re                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b1mul2_im                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b2mul2_re                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b2mul2_im                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b3mul2_re                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b3mul2_im                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL sub_cast_8                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_9                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp_4                       : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL sub_cast_10                      : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_11                      : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp_5                       : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL sub_cast_12                      : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_13                      : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp_6                       : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL sub_cast_14                      : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_15                      : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp_7                       : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL b1multypeconvert2_re             : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL b1multypeconvert2_im             : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_8                       : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_9                       : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_temp_4                       : signed(40 DOWNTO 0); -- sfix41_En28
  SIGNAL add_cast_10                      : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_11                      : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_temp_5                       : signed(40 DOWNTO 0); -- sfix41_En28
  SIGNAL add_cast_12                      : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_13                      : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_temp_6                       : signed(40 DOWNTO 0); -- sfix41_En28
  SIGNAL add_cast_14                      : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_15                      : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_temp_7                       : signed(40 DOWNTO 0); -- sfix41_En28
  SIGNAL section_result2_re               : signed(15 DOWNTO 0); -- sfix16_En10
  SIGNAL section_result2_im               : signed(15 DOWNTO 0); -- sfix16_En10
  SIGNAL scale3_re                        : signed(40 DOWNTO 0); -- sfix41_En37
  SIGNAL scale3_im                        : signed(40 DOWNTO 0); -- sfix41_En37
  SIGNAL mul_temp_4                       : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL mul_temp_5                       : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL scaletypeconvert3_re             : signed(15 DOWNTO 0); -- sfix16_En12
  SIGNAL scaletypeconvert3_im             : signed(15 DOWNTO 0); -- sfix16_En12
  --   -- Section 3 Signals 
  SIGNAL a1sum3_re                        : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL a1sum3_im                        : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL b1sum3_re                        : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL b1sum3_im                        : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL a1sumtypeconvert3_re             : signed(15 DOWNTO 0); -- sfix16_En15
  SIGNAL a1sumtypeconvert3_im             : signed(15 DOWNTO 0); -- sfix16_En15
  SIGNAL delay_section3_re                : signed(15 DOWNTO 0); -- sfix16_En15
  SIGNAL delay_section3_im                : signed(15 DOWNTO 0); -- sfix16_En15
  SIGNAL inputconv3_re                    : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL inputconv3_im                    : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL a2mul3_re                        : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL a2mul3_im                        : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL b1mul3_re                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b1mul3_im                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b2mul3_re                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL b2mul3_im                        : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL sub_cast_16                      : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_17                      : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp_8                       : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL sub_cast_18                      : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_19                      : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp_9                       : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL b1multypeconvert3_re             : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL b1multypeconvert3_im             : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_16                      : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_17                      : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_temp_8                       : signed(40 DOWNTO 0); -- sfix41_En28
  SIGNAL add_cast_18                      : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_cast_19                      : signed(39 DOWNTO 0); -- sfix40_En28
  SIGNAL add_temp_9                       : signed(40 DOWNTO 0); -- sfix41_En28
  SIGNAL output_typeconvert_re            : signed(19 DOWNTO 0); -- sfix20_En14
  SIGNAL output_typeconvert_im            : signed(19 DOWNTO 0); -- sfix20_En14
  SIGNAL output_register_re               : signed(19 DOWNTO 0); -- sfix20_En14
  SIGNAL output_register_im               : signed(19 DOWNTO 0); -- sfix20_En14


BEGIN

  -- Block Statements
  input_reg_process : PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      input_register_re <= (OTHERS => '0');
      input_register_im <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN
      IF clk_enable = '1' THEN
        input_register_re <= signed(filter_in_re);
        input_register_im <= signed(filter_in_im);
      END IF;
    END IF; 
  END PROCESS input_reg_process;

  mul_temp <= input_register_re * scaleconst1;
  scale1_re <= resize(mul_temp, 41);

  mul_temp_1 <= input_register_im * scaleconst1;
  scale1_im <= resize(mul_temp_1, 41);

  scaletypeconvert1_re <= resize(shift_right(scale1_re(40 DOWNTO 0) + ( "0" & (scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25) & NOT scale1_re(25))), 25), 16);
  scaletypeconvert1_im <= resize(shift_right(scale1_im(40 DOWNTO 0) + ( "0" & (scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25) & NOT scale1_im(25))), 25), 16);

  --   ------------------ Section 1 ------------------

  typeconvert1_re <= resize(shift_right(a1sum1_re(29 DOWNTO 0) + ( "0" & (a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14) & NOT a1sum1_re(14))), 14), 16);
  typeconvert1_im <= resize(shift_right(a1sum1_im(29 DOWNTO 0) + ( "0" & (a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14) & NOT a1sum1_im(14))), 14), 16);

  delay_process_section1 : PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      delay_section1_re <= (OTHERS => (OTHERS => '0'));
      delay_section1_im <= (OTHERS => (OTHERS => '0'));
    ELSIF clk'event AND clk = '1' THEN
      IF clk_enable = '1' THEN
        delay_section1_re(1) <= delay_section1_re(0);
        delay_section1_im(1) <= delay_section1_im(0);
        delay_section1_re(0) <= typeconvert1_re;
        delay_section1_im(0) <= typeconvert1_im;
      END IF;
    END IF;
  END PROCESS delay_process_section1;

  inputconv1_re <= scaletypeconvert1_re;
  inputconv1_im <= scaletypeconvert1_im;

  a2mul1_re <= delay_section1_re(0) * coeff_a2_section1;

  a2mul1_im <= delay_section1_im(0) * coeff_a2_section1;

  a3mul1_re <= delay_section1_re(1) * coeff_a3_section1;

  a3mul1_im <= delay_section1_im(1) * coeff_a3_section1;

  b1mul1_re <= resize(typeconvert1_re(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);
  b1mul1_im <= resize(typeconvert1_im(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);

  b2mul1_re <= resize(delay_section1_re(0)(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);

  b2mul1_im <= resize(delay_section1_im(0)(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);

  b3mul1_re <= resize(delay_section1_re(1)(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);
  b3mul1_im <= resize(delay_section1_im(1)(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);

  sub_cast <= resize(inputconv1_re(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 40);
  sub_cast_1 <= resize(a2mul1_re, 40);
  sub_temp <= resize(sub_cast, 41) - resize(sub_cast_1, 41);
  a2sum1_re <= sub_temp(39 DOWNTO 0);

  sub_cast_2 <= resize(inputconv1_im(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 40);
  sub_cast_3 <= resize(a2mul1_im, 40);
  sub_temp_1 <= resize(sub_cast_2, 41) - resize(sub_cast_3, 41);
  a2sum1_im <= sub_temp_1(39 DOWNTO 0);

  sub_cast_4 <= a2sum1_re;
  sub_cast_5 <= resize(a3mul1_re, 40);
  sub_temp_2 <= resize(sub_cast_4, 41) - resize(sub_cast_5, 41);
  a1sum1_re <= sub_temp_2(39 DOWNTO 0);

  sub_cast_6 <= a2sum1_im;
  sub_cast_7 <= resize(a3mul1_im, 40);
  sub_temp_3 <= resize(sub_cast_6, 41) - resize(sub_cast_7, 41);
  a1sum1_im <= sub_temp_3(39 DOWNTO 0);

  b1multypeconvert1_re <= resize(b1mul1_re, 40);
  b1multypeconvert1_im <= resize(b1mul1_im, 40);

  add_cast <= b1multypeconvert1_re;
  add_cast_1 <= resize(b2mul1_re, 40);
  add_temp <= resize(add_cast, 41) + resize(add_cast_1, 41);
  b2sum1_re <= add_temp(39 DOWNTO 0);

  add_cast_2 <= b1multypeconvert1_im;
  add_cast_3 <= resize(b2mul1_im, 40);
  add_temp_1 <= resize(add_cast_2, 41) + resize(add_cast_3, 41);
  b2sum1_im <= add_temp_1(39 DOWNTO 0);

  add_cast_4 <= b2sum1_re;
  add_cast_5 <= resize(b3mul1_re, 40);
  add_temp_2 <= resize(add_cast_4, 41) + resize(add_cast_5, 41);
  b1sum1_re <= add_temp_2(39 DOWNTO 0);

  add_cast_6 <= b2sum1_im;
  add_cast_7 <= resize(b3mul1_im, 40);
  add_temp_3 <= resize(add_cast_6, 41) + resize(add_cast_7, 41);
  b1sum1_im <= add_temp_3(39 DOWNTO 0);

  section_result1_re <= resize(shift_right(b1sum1_re(33 DOWNTO 0) + ( "0" & (b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18) & NOT b1sum1_re(18))), 18), 16);
  section_result1_im <= resize(shift_right(b1sum1_im(33 DOWNTO 0) + ( "0" & (b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18) & NOT b1sum1_im(18))), 18), 16);

  mul_temp_2 <= section_result1_re * scaleconst2;
  scale2_re <= resize(mul_temp_2(31 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 41);

  mul_temp_3 <= section_result1_im * scaleconst2;
  scale2_im <= resize(mul_temp_3(31 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 41);

  scaletypeconvert2_re <= resize(shift_right(scale2_re(40 DOWNTO 0) + ( "0" & (scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25) & NOT scale2_re(25))), 25), 16);
  scaletypeconvert2_im <= resize(shift_right(scale2_im(40 DOWNTO 0) + ( "0" & (scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25) & NOT scale2_im(25))), 25), 16);

  --   ------------------ Section 2 ------------------

  typeconvert2_re <= resize(shift_right(a1sum2_re(29 DOWNTO 0) + ( "0" & (a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14) & NOT a1sum2_re(14))), 14), 16);
  typeconvert2_im <= resize(shift_right(a1sum2_im(29 DOWNTO 0) + ( "0" & (a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14) & NOT a1sum2_im(14))), 14), 16);

  delay_process_section2 : PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      delay_section2_re <= (OTHERS => (OTHERS => '0'));
      delay_section2_im <= (OTHERS => (OTHERS => '0'));
    ELSIF clk'event AND clk = '1' THEN
      IF clk_enable = '1' THEN
        delay_section2_re(1) <= delay_section2_re(0);
        delay_section2_im(1) <= delay_section2_im(0);
        delay_section2_re(0) <= typeconvert2_re;
        delay_section2_im(0) <= typeconvert2_im;
      END IF;
    END IF;
  END PROCESS delay_process_section2;

  inputconv2_re <= scaletypeconvert2_re;
  inputconv2_im <= scaletypeconvert2_im;

  a2mul2_re <= delay_section2_re(0) * coeff_a2_section2;

  a2mul2_im <= delay_section2_im(0) * coeff_a2_section2;

  a3mul2_re <= delay_section2_re(1) * coeff_a3_section2;

  a3mul2_im <= delay_section2_im(1) * coeff_a3_section2;

  b1mul2_re <= resize(typeconvert2_re(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);
  b1mul2_im <= resize(typeconvert2_im(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);

  b2mul2_re <= resize(delay_section2_re(0)(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);

  b2mul2_im <= resize(delay_section2_im(0)(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);

  b3mul2_re <= resize(delay_section2_re(1)(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);
  b3mul2_im <= resize(delay_section2_im(1)(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);

  sub_cast_8 <= resize(inputconv2_re(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 40);
  sub_cast_9 <= resize(a2mul2_re, 40);
  sub_temp_4 <= resize(sub_cast_8, 41) - resize(sub_cast_9, 41);
  a2sum2_re <= sub_temp_4(39 DOWNTO 0);

  sub_cast_10 <= resize(inputconv2_im(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 40);
  sub_cast_11 <= resize(a2mul2_im, 40);
  sub_temp_5 <= resize(sub_cast_10, 41) - resize(sub_cast_11, 41);
  a2sum2_im <= sub_temp_5(39 DOWNTO 0);

  sub_cast_12 <= a2sum2_re;
  sub_cast_13 <= resize(a3mul2_re, 40);
  sub_temp_6 <= resize(sub_cast_12, 41) - resize(sub_cast_13, 41);
  a1sum2_re <= sub_temp_6(39 DOWNTO 0);

  sub_cast_14 <= a2sum2_im;
  sub_cast_15 <= resize(a3mul2_im, 40);
  sub_temp_7 <= resize(sub_cast_14, 41) - resize(sub_cast_15, 41);
  a1sum2_im <= sub_temp_7(39 DOWNTO 0);

  b1multypeconvert2_re <= resize(b1mul2_re, 40);
  b1multypeconvert2_im <= resize(b1mul2_im, 40);

  add_cast_8 <= b1multypeconvert2_re;
  add_cast_9 <= resize(b2mul2_re, 40);
  add_temp_4 <= resize(add_cast_8, 41) + resize(add_cast_9, 41);
  b2sum2_re <= add_temp_4(39 DOWNTO 0);

  add_cast_10 <= b1multypeconvert2_im;
  add_cast_11 <= resize(b2mul2_im, 40);
  add_temp_5 <= resize(add_cast_10, 41) + resize(add_cast_11, 41);
  b2sum2_im <= add_temp_5(39 DOWNTO 0);

  add_cast_12 <= b2sum2_re;
  add_cast_13 <= resize(b3mul2_re, 40);
  add_temp_6 <= resize(add_cast_12, 41) + resize(add_cast_13, 41);
  b1sum2_re <= add_temp_6(39 DOWNTO 0);

  add_cast_14 <= b2sum2_im;
  add_cast_15 <= resize(b3mul2_im, 40);
  add_temp_7 <= resize(add_cast_14, 41) + resize(add_cast_15, 41);
  b1sum2_im <= add_temp_7(39 DOWNTO 0);

  section_result2_re <= resize(shift_right(b1sum2_re(33 DOWNTO 0) + ( "0" & (b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18) & NOT b1sum2_re(18))), 18), 16);
  section_result2_im <= resize(shift_right(b1sum2_im(33 DOWNTO 0) + ( "0" & (b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18) & NOT b1sum2_im(18))), 18), 16);

  mul_temp_4 <= section_result2_re * scaleconst3;
  scale3_re <= resize(mul_temp_4(31 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 41);

  mul_temp_5 <= section_result2_im * scaleconst3;
  scale3_im <= resize(mul_temp_5(31 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 41);

  scaletypeconvert3_re <= resize(shift_right(scale3_re(40 DOWNTO 0) + ( "0" & (scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25) & NOT scale3_re(25))), 25), 16);
  scaletypeconvert3_im <= resize(shift_right(scale3_im(40 DOWNTO 0) + ( "0" & (scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25) & NOT scale3_im(25))), 25), 16);

  --   ------------------ Section 3 (First Order) ------------------

  a1sumtypeconvert3_re <= resize(shift_right(a1sum3_re(29 DOWNTO 0) + ( "0" & (a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14) & NOT a1sum3_re(14))), 14), 16);
  a1sumtypeconvert3_im <= resize(shift_right(a1sum3_im(29 DOWNTO 0) + ( "0" & (a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14) & NOT a1sum3_im(14))), 14), 16);

  delay_process_section3 : PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      delay_section3_re <= (OTHERS => '0');
      delay_section3_im <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN
      IF clk_enable = '1' THEN
        delay_section3_re <= a1sumtypeconvert3_re;
        delay_section3_im <= a1sumtypeconvert3_im;
      END IF;
    END IF; 
  END PROCESS delay_process_section3;

  inputconv3_re <= resize(scaletypeconvert3_re(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 40);
  inputconv3_im <= resize(scaletypeconvert3_im(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 40);

  a2mul3_re <= delay_section3_re * coeff_a2_section3;

  a2mul3_im <= delay_section3_im * coeff_a2_section3;

  b1mul3_re <= resize(a1sumtypeconvert3_re(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);
  b1mul3_im <= resize(a1sumtypeconvert3_im(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);

  b2mul3_re <= resize(delay_section3_re(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);
  b2mul3_im <= resize(delay_section3_im(15 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0', 32);

  sub_cast_16 <= inputconv3_re;
  sub_cast_17 <= resize(a2mul3_re, 40);
  sub_temp_8 <= resize(sub_cast_16, 41) - resize(sub_cast_17, 41);
  a1sum3_re <= sub_temp_8(39 DOWNTO 0);

  sub_cast_18 <= inputconv3_im;
  sub_cast_19 <= resize(a2mul3_im, 40);
  sub_temp_9 <= resize(sub_cast_18, 41) - resize(sub_cast_19, 41);
  a1sum3_im <= sub_temp_9(39 DOWNTO 0);

  b1multypeconvert3_re <= resize(b1mul3_re, 40);
  b1multypeconvert3_im <= resize(b1mul3_im, 40);

  add_cast_16 <= b1multypeconvert3_re;
  add_cast_17 <= resize(b2mul3_re, 40);
  add_temp_8 <= resize(add_cast_16, 41) + resize(add_cast_17, 41);
  b1sum3_re <= add_temp_8(39 DOWNTO 0);

  add_cast_18 <= b1multypeconvert3_im;
  add_cast_19 <= resize(b2mul3_im, 40);
  add_temp_9 <= resize(add_cast_18, 41) + resize(add_cast_19, 41);
  b1sum3_im <= add_temp_9(39 DOWNTO 0);

  output_typeconvert_re <= resize(shift_right(b1sum3_re(33 DOWNTO 0) + ( "0" & (b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14) & NOT b1sum3_re(14))), 14), 20);
  output_typeconvert_im <= resize(shift_right(b1sum3_im(33 DOWNTO 0) + ( "0" & (b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14) & NOT b1sum3_im(14))), 14), 20);

  Output_Register_process : PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      output_register_re <= (OTHERS => '0');
      output_register_im <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN
      IF clk_enable = '1' THEN
        output_register_re <= output_typeconvert_re;
        output_register_im <= output_typeconvert_im;
      END IF;
    END IF; 
  END PROCESS Output_Register_process;

  -- Assignment Statements
  filter_out_re <= std_logic_vector(output_register_re);
  filter_out_im <= std_logic_vector(output_register_im);
END rtl;
