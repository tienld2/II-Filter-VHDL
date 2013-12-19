--------------------------------------------------------------------------------
--    This file is owned and controlled by Xilinx and must be used solely     --
--    for design, simulation, implementation and creation of design files     --
--    limited to Xilinx devices or technologies. Use with non-Xilinx          --
--    devices or technologies is expressly prohibited and immediately         --
--    terminates your license.                                                --
--                                                                            --
--    XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" SOLELY    --
--    FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY    --
--    PROVIDING THIS DESIGN, CODE, OR INFORMATION AS ONE POSSIBLE             --
--    IMPLEMENTATION OF THIS FEATURE, APPLICATION OR STANDARD, XILINX IS      --
--    MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY      --
--    CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY       --
--    RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY       --
--    DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE   --
--    IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR          --
--    REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF         --
--    INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A   --
--    PARTICULAR PURPOSE.                                                     --
--                                                                            --
--    Xilinx products are not intended for use in life support appliances,    --
--    devices, or systems.  Use in such applications are expressly            --
--    prohibited.                                                             --
--                                                                            --
--    (c) Copyright 1995-2013 Xilinx, Inc.                                    --
--    All rights reserved.                                                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- You must compile the wrapper file polyDecimator.vhd when simulating
-- the core, polyDecimator. When compiling the wrapper file, be sure to
-- reference the XilinxCoreLib VHDL simulation library. For detailed
-- instructions, please refer to the "CORE Generator Help".

-- The synthesis directives "translate_off/translate_on" specified
-- below are supported by Xilinx, Mentor Graphics and Synplicity
-- synthesis tools. Ensure they are correct for your synthesis tool(s).

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- synthesis translate_off
LIBRARY XilinxCoreLib;
-- synthesis translate_on
ENTITY polyDecimator IS
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_config_tvalid : IN STD_LOGIC;
    s_axis_config_tready : OUT STD_LOGIC;
    s_axis_config_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axis_reload_tvalid : IN STD_LOGIC;
    s_axis_reload_tready : OUT STD_LOGIC;
    s_axis_reload_tlast : IN STD_LOGIC;
    s_axis_reload_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
    event_s_reload_tlast_missing : OUT STD_LOGIC;
    event_s_reload_tlast_unexpected : OUT STD_LOGIC
  );
END polyDecimator;

ARCHITECTURE polyDecimator_a OF polyDecimator IS
-- synthesis translate_off
COMPONENT wrapped_polyDecimator
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_config_tvalid : IN STD_LOGIC;
    s_axis_config_tready : OUT STD_LOGIC;
    s_axis_config_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axis_reload_tvalid : IN STD_LOGIC;
    s_axis_reload_tready : OUT STD_LOGIC;
    s_axis_reload_tlast : IN STD_LOGIC;
    s_axis_reload_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
    event_s_reload_tlast_missing : OUT STD_LOGIC;
    event_s_reload_tlast_unexpected : OUT STD_LOGIC
  );
END COMPONENT;

-- Configuration specification
  FOR ALL : wrapped_polyDecimator USE ENTITY XilinxCoreLib.fir_compiler_v6_3(behavioral)
    GENERIC MAP (
      c_accum_op_path_widths => "38",
      c_accum_path_widths => "38",
      c_channel_pattern => "fixed",
      c_coef_file => "polyDecimator.mif",
      c_coef_file_lines => 40,
      c_coef_mem_packing => 0,
      c_coef_memtype => 2,
      c_coef_path_sign => "0",
      c_coef_path_src => "0",
      c_coef_path_widths => "16",
      c_coef_reload => 1,
      c_coef_width => 16,
      c_col_config => "5",
      c_col_mode => 1,
      c_col_pipe_len => 4,
      c_component_name => "polyDecimator",
      c_config_packet_size => 0,
      c_config_sync_mode => 0,
      c_config_tdata_width => 8,
      c_data_has_tlast => 0,
      c_data_mem_packing => 0,
      c_data_memtype => 0,
      c_data_path_sign => "0",
      c_data_path_src => "0",
      c_data_path_widths => "16",
      c_data_width => 16,
      c_datapath_memtype => 2,
      c_decim_rate => 4,
      c_ext_mult_cnfg => "none",
      c_filter_type => 1,
      c_filts_packed => 0,
      c_has_aclken => 0,
      c_has_aresetn => 0,
      c_has_config_channel => 1,
      c_input_rate => 1,
      c_interp_rate => 1,
      c_ipbuff_memtype => 0,
      c_latency => 16,
      c_m_data_has_tready => 0,
      c_m_data_has_tuser => 0,
      c_m_data_tdata_width => 24,
      c_m_data_tuser_width => 1,
      c_mem_arrangement => 3,
      c_num_channels => 1,
      c_num_filts => 1,
      c_num_madds => 5,
      c_num_reload_slots => 1,
      c_num_taps => 36,
      c_opbuff_memtype => 0,
      c_opt_madds => "none",
      c_optimization => 0,
      c_output_path_widths => "20",
      c_output_rate => 4,
      c_output_width => 20,
      c_oversampling_rate => 1,
      c_reload_tdata_width => 16,
      c_round_mode => 1,
      c_s_data_has_fifo => 1,
      c_s_data_has_tuser => 0,
      c_s_data_tdata_width => 16,
      c_s_data_tuser_width => 1,
      c_symmetry => 1,
      c_xdevicefamily => "spartan6",
      c_zero_packing_factor => 1
    );
-- synthesis translate_on
BEGIN
-- synthesis translate_off
U0 : wrapped_polyDecimator
  PORT MAP (
    aclk => aclk,
    s_axis_data_tvalid => s_axis_data_tvalid,
    s_axis_data_tready => s_axis_data_tready,
    s_axis_data_tdata => s_axis_data_tdata,
    s_axis_config_tvalid => s_axis_config_tvalid,
    s_axis_config_tready => s_axis_config_tready,
    s_axis_config_tdata => s_axis_config_tdata,
    s_axis_reload_tvalid => s_axis_reload_tvalid,
    s_axis_reload_tready => s_axis_reload_tready,
    s_axis_reload_tlast => s_axis_reload_tlast,
    s_axis_reload_tdata => s_axis_reload_tdata,
    m_axis_data_tvalid => m_axis_data_tvalid,
    m_axis_data_tdata => m_axis_data_tdata,
    event_s_reload_tlast_missing => event_s_reload_tlast_missing,
    event_s_reload_tlast_unexpected => event_s_reload_tlast_unexpected
  );
-- synthesis translate_on

END polyDecimator_a;
