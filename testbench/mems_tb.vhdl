------------------------------------------------------------------------------
----                                                                      ----
----  BRAM Memory Test                                                    ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  A simple test to see waveform.                                      ----
----                                                                      ----
----                                                                      ----
----  To Do:                                                              ----
----   -                                                                  ----
----                                                                      ----
----  Author:                                                             ----
----    - Rodrigo A. Melo, rmelo@inti.gob.ar                              ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Copyright (c) 2010 Rodrigo A. Melo <rmelo@inti.gob.ar>               ----
---- Copyright (c) 2010 Instituto Nacional de Tecnología Industrial       ----
----                                                                      ----
---- Distributed under the GPL v2 or newer license                        ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Design unit:      mac_tb (Testbench)                                 ----
---- File name:        mac_tb.vhdl                                        ----
---- Note:             None                                               ----
---- Limitations:      None known                                         ----
---- Errors:           None known                                         ----
---- Library:          None                                               ----
---- Dependencies:     IEEE.std_logic_1164                                ----
----                   MEMS.DEVICES                                       ----
----                   UTILS.STDLIB                                       ----
----                   UTILS.STDIO                                        ----
---- Target FPGA:      N/A                                                ----
---- Language:         VHDL                                               ----
---- Wishbone:         N/A                                                ----
---- Synthesis tools:  N/A                                                ----
---- Simulation tools: GHDL [Sokcho edition] (0.2x)                       ----
---- Text editor:      SETEdit 0.5.x                                      ----
----                                                                      ----
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
library mems;
use mems.devices.all;
library utils;
use utils.StdLib.all;
use utils.StdIO.all;

entity MEMS_TB is
end entity MEMS_TB;

architecture TestBench of MEMS_TB is

   constant ADDR_W: natural:=3;
   constant DATA_W: natural:=8;
   constant SIZE  : natural:=5;

   signal clk  : std_logic;
   signal clk2 : std_logic;
   signal rst  : std_logic;
   signal stop : std_logic;

   signal we1  : std_logic;
   signal we2  : std_logic;
   signal add1 : std_logic_vector(ADDR_W-1 downto 0):=(others => '0');
   signal add2 : std_logic_vector(ADDR_W-1 downto 0):=(others => '0');
   signal di1  : std_logic_vector(DATA_W-1 downto 0);
   signal di2  : std_logic_vector(DATA_W-1 downto 0);

   signal sdo1 : std_logic_vector(DATA_W-1 downto 0);
   signal ddo1 : std_logic_vector(DATA_W-1 downto 0);
   signal ddo2 : std_logic_vector(DATA_W-1 downto 0);
   signal fdo1 : std_logic_vector(DATA_W-1 downto 0);
   signal fdo2 : std_logic_vector(DATA_W-1 downto 0);

begin

   clock : SimpleClock
      generic map(FREQUENCY => 2)
      port map(
         clk_o => clk, rst_o => rst, stop_i => stop);

   clock2 : SimpleClock
      generic map(FREQUENCY => 3)
      port map(
         clk_o => clk2, rst_o => open, stop_i => stop);
         

   SingleBRAM: SinglePortBRAM
      generic map(ADDR_W => ADDR_W, DATA_W => DATA_W, SIZE => SIZE)
      port map(
         clk_i => clk,
         we_i  => we1, addr_i => add1, di_i => di1, do_o => sdo1);

   DualBRAM: DualPortBRAM
      generic map(ADDR_W => ADDR_W, DATA_W => DATA_W, SIZE => SIZE)
      port map(
         clk_i => clk,
         we_i => we1, add1_i => add1, add2_i => add2,
         di_i => di1, do1_o  => ddo1, do2_o  => ddo2);

   FullBRAM: FullDualPortBRAM
      generic map(ADDR_W => ADDR_W, DATA_W => DATA_W, SIZE => SIZE)
      port map(
         clk1_i => clk, clk2_i => clk2,
         we1_i => we1, we2_i => we2, add1_i => add1, add2_i => add2,
         di1_i => di1, di2_i => di2, do1_o  => fdo1, do2_o  => fdo2);

   test:
   process
   begin
   wait until rising_edge(clk) and rst = '0';
   OutWrite("* Playing with signals");
   we1  <= '1';
   add1 <= "001";
   di1  <= x"CA";
   wait until rising_edge(clk);
   add1 <= "010";
   di1  <= x"FE";
   wait until rising_edge(clk);   
   we1  <= '0';
   add1 <= "000";
   wait until rising_edge(clk);
   wait until rising_edge(clk);
   add2 <= "001";
   wait until rising_edge(clk);
   add2 <= "010";
   wait until rising_edge(clk);
   add2 <= "011";
   wait until rising_edge(clk);
   OutWrite("* End");
   stop <= '1';
   wait;
   end process test;

end architecture TestBench; -- Entity: MEMS_TB
