-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: ii_crm
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 13.3
--*
--*     @short Clock and Reset management
--*
--* Description:
--*
--*   This file is the Digital Clock and Reset Management core. It generates
--*   a set of 3 output clocks and 3 resets. One of these clocks has a constant
--*   frequency of 200MHz, whereas the frequency of the two other clocks is
--*   specified in the (SYS_CLK_FREQ and MEM_CLK_FREQ) generics.
--*
--*   The reset outputs fall in different categories as specified below.
--*
--*   @port por_arst          : input, Asynchronous active high power on reset
--*   @port brd_arst          : input, Asynchronous active high board reset
--*   @port clk200_p          : input, 200MHz clock differential pair (side-P)
--*   @port clk200_n          : input, 200MHz clock differential pair (side-N)
--*   @port ref_clk200        :output, 200MHz reference clock
--*   @port sys_clk           :output, system clock
--*   @port mem_clk_div2      :output, memory clock divided by 2
--*   @port clks_locked       :output, MMCMs locked
--*   @port app_rst           : input, Application reset request
--*   @port run               : input, Enable data flow
--*   @port mem_rst           :output, Synchronous active high memory reset
--*                                    at mem_clk_div2 domain. (asserted only
--*                                    at power on before all clocks lock)
--*   @port wb_rst            :output, Wishbone system reset (asserted at power
--*                                    on before all clocks lock and upon board
--*                                    reset)
--*   @port frontend_rst      :output, Synchronous active high reset (asserted
--*                                    at power on before all clocks lock,
--*                                    during board reset and on software reset)
--*   @port backend_rst       :output, Synchronous active high reset (asserted
--*                                    at power on before all clocks lock,
--*                                    during board reset, on software reset,
--*                                    and while run is low)
--*
--*     @author Innovative Integration
--*     @version 1.0
--*     @date Created 6/2/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ii_crm is
  generic (
    SYS_CLK_FREQ         : integer := 250; -- system clk freq in MHz
    MEM_CLK_FREQ         : integer := 333  -- memory clk freq in MHz
  );
  port (
    por_arst             : in  std_logic;
    brd_arst             : in  std_logic;
    clk200_p             : in  std_logic;
    clk200_n             : in  std_logic;
    ref_clk200           : out std_logic;
    sys_clk              : out std_logic;
    mem_clk_div2         : out std_logic;
    clks_locked          : out std_logic;
    app_rst              : in  std_logic;
    run                  : in  std_logic;
    mem_rst              : out std_logic;
    wb_rst               : out std_logic;
    frontend_rst         : out std_logic;
    backend_rst          : out std_logic
  );
end ii_crm;


architecture arch of ii_crm is

  constant CLKIN_PERIOD       : integer := 5000;
  constant SYS_CLK_PERIOD     : integer := integer(1000000.0/real(SYS_CLK_FREQ));
  constant MEM_CLK_DIV2_PERIOD: integer := integer(2000000.0/real(MEM_CLK_FREQ));

  component ii_mmcm
    generic (
      CLKIN_PERIOD         : integer := 5000; -- in ps
      CLKOUT_PERIOD        : integer := 3000  -- in ps
    );
    port (
      rst_in               : in  std_logic;
      clk_in               : in  std_logic;
      clk_out              : out std_logic;
      locked_out           : out std_logic
    );
  end component;

  signal clk200_ibufg         : std_logic;
  signal sys_clk_int          : std_logic;
  signal locked_sys           : std_logic;
  signal mem_clk_div2_int     : std_logic;
  signal locked_mem           : std_logic;
  signal por_rst_tmp          : std_logic;
  signal por_rst_sreg         : std_logic_vector(25 downto 0);
  signal por_rst              : std_logic;
  signal sys_rst_tmp          : std_logic;
  signal sys_rst_sreg         : std_logic_vector(3 downto 0);
  signal sys_rst              : std_logic;
  signal frontend_rst_1b      : std_logic;
  signal backend_rst_1b       : std_logic;
  signal mem_rst_sreg         : std_logic_vector(3 downto 0);
  signal mem_rst_1b           : std_logic;

begin

  ------------------------------------------------------------------------------
  -- Input clock buffer
  ------------------------------------------------------------------------------
  clk200_ibufgds_inst : IBUFGDS
  port map (
    i  => clk200_p,
    ib => clk200_n,
    o  => clk200_ibufg
  );

  clk200_bufg_inst : BUFG
  port map (
    o => ref_clk200,
    i => clk200_ibufg
  );

  ------------------------------------------------------------------------------
  -- System clock MMCM
  ------------------------------------------------------------------------------
  inst_sys_clk : ii_mmcm
  generic map (
    CLKIN_PERIOD      => CLKIN_PERIOD,
    CLKOUT_PERIOD     => SYS_CLK_PERIOD
  )
  port map (
    rst_in            => por_arst,
    clk_in            => clk200_ibufg,
    clk_out           => sys_clk_int,
    locked_out        => locked_sys
  );

  sys_clk <= sys_clk_int;

  ------------------------------------------------------------------------------
  -- Memory clock MMCM
  ------------------------------------------------------------------------------
  inst_mem_clk : ii_mmcm
  generic map (
    CLKIN_PERIOD      => CLKIN_PERIOD,
    CLKOUT_PERIOD     => MEM_CLK_DIV2_PERIOD
  )
  port map (
    rst_in            => por_arst,
    clk_in            => clk200_ibufg,
    clk_out           => mem_clk_div2_int,
    locked_out        => locked_mem
  );

  mem_clk_div2 <= mem_clk_div2_int;

  ------------------------------------------------------------------------------
  -- Reset logic
  ------------------------------------------------------------------------------
  por_rst_tmp <= por_arst or not locked_sys or not locked_mem;

  process (por_rst_tmp, sys_clk_int)
  begin
    if (por_rst_tmp = '1') then
      por_rst_sreg <= (others => '1');
      clks_locked  <= '0';
    elsif (rising_edge(sys_clk_int)) then
      por_rst_sreg <= por_rst_sreg(por_rst_sreg'high-1 downto 0) & '0';
      clks_locked  <= not por_rst;
    end if;
  end process;

  por_rst <= por_rst_sreg(por_rst_sreg'high);

  sys_rst_tmp <= por_rst or brd_arst;

  -- Delay line on main reset
  process (sys_rst_tmp, sys_clk_int)
  begin
    if (sys_rst_tmp = '1') then
      sys_rst_sreg <= (others => '1');
    elsif (rising_edge(sys_clk_int)) then
      sys_rst_sreg <= sys_rst_sreg(sys_rst_sreg'high-1 downto 0) & '0';
    end if;
  end process;

  sys_rst         <= sys_rst_sreg(sys_rst_sreg'high);
  frontend_rst_1b <= sys_rst or app_rst;
  backend_rst_1b  <= sys_rst or app_rst or not run;

  -- Delay line on memory reset
  process (por_rst, mem_clk_div2_int)
  begin
    if (por_rst = '1') then
      mem_rst_sreg <= (others => '1');
    elsif (rising_edge(mem_clk_div2_int)) then
      mem_rst_sreg <= mem_rst_sreg(mem_rst_sreg'high-1 downto 0) & '0';
    end if;
  end process;

  mem_rst_1b <= mem_rst_sreg(mem_rst_sreg'high);

  -- Instantiate primitives to allow these flops to be attached
  -- to multicycle path constraint in UCF.
  u_ff_wb_rst_o : FDPE
  generic map (
    INIT => '1'
  )
  port map (
    Q   => wb_rst,
    C   => sys_clk_int,
    CE  => '1',
    PRE => sys_rst,
    D   => sys_rst
  );

  u_ff_frontend_rst : FDPE
  generic map (
    INIT => '1'
  )
  port map (
    Q   => frontend_rst,
    C   => sys_clk_int,
    CE  => '1',
    PRE => sys_rst,
    D   => frontend_rst_1b
  );

  u_ff_backend_rst : FDPE
  generic map (
    INIT => '1'
  )
  port map (
    Q   => backend_rst,
    C   => sys_clk_int,
    CE  => '1',
    PRE => sys_rst,
    D   => backend_rst_1b
  );

  u_ff_mem_rst : FDPE
  generic map (
    INIT => '1'
  )
  port map (
    Q   => mem_rst,
    C   => mem_clk_div2_int,
    CE  => '1',
    PRE => por_rst,
    D   => mem_rst_1b
  );

end arch;
