------------------------------------------------------------------------------
----                                                                      ----
----  Test bench for the ROMLoader.                                       ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  This testbench loads a .hex file (jt.hex) and verifies if the       ----
----  content matchs (3 memory positions are tested).                     ----
----                                                                      ----
----  To Do:                                                              ----
----  -                                                                   ----
----                                                                      ----
----  Author:                                                             ----
----    - Salvador E. Tropea, salvador en inti gov ar                     ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Copyright (c) 2006 Salvador E. Tropea <salvador en inti gov ar>      ----
---- Copyright (c) 2006 Instituto Nacional de Tecnolog�a Industrial       ----
----                                                                      ----
---- Distributed under the GPL v2 or newer license                        ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Design unit:      Rom_Test (Simulator)                               ----
---- File name:        rom_loader.vhdl                                    ----
---- Note:             None                                               ----
---- Limitations:      None known                                         ----
---- Errors:           None known                                         ----
---- Library:          mems                                               ----
---- Dependencies:     IEEE.std_logic_1164                                ----
----                   IEEE.numeric_std                                   ----
----                   C.stdio_h                                          ----
----                   mems.Devices                                       ----
---- Target FPGA:      None                                               ----
---- Language:         VHDL                                               ----
---- Wishbone:         N/A                                                ----
---- Synthesis tools:  None                                               ----
---- Simulation tools: GHDL [Sokcho edition] (0.2x)                       ----
---- Text editor:      SETEdit 0.5.x                                      ----
----                                                                      ----
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library C;
use C.stdio_h.all;
library mems;
use mems.Devices.all;
library utils;
use utils.StdIO.all;

entity Rom_Test is
end entity Rom_Test;

architecture Simulator of Rom_Test is
   -- Clock=25 MHz
   constant CLKPERIOD : time:=40 ns;

   signal addr     : std_logic_vector(9 downto 0):=(others => '0');
   signal data     : std_logic_vector(13 downto 0);
   signal load     : std_logic:='0';
   signal loaded   : std_logic;
   signal rst      : std_logic;
   signal ck       : std_logic;
   signal end_test : std_logic;
begin
   -- Clock generation
   p_clks:
   process
      variable veces : integer:=0;
   begin
      ck <= '0';
      wait for CLKPERIOD/2;
      ck <= '1';
      wait for CLKPERIOD/2;
      if veces=3 then
         outwrite("Loading ROM");
         load <= '1';
         wait until loaded='1';
         outwrite("Finished loading ROM");
         load <= '0';
      end if;
      if end_test='1' then
         outwrite("* End of test");
         wait;
      end if;
      veces:=veces+1;
   end process p_clks;
   
   -- Reset pulse
   p_reset:
   process
   begin
      rst <= '1';
      wait until rising_edge(ck);
      rst <= '0' after 40 ns;
      wait;
   end process p_reset;

   rom: ROMLoader
      generic map(
         ADDR_W => 10, DATA_W => 14, SIZE => 340)
      port map(
         addr_i => addr, data_o => data, ck_i => ck, rst_i => rst,
         start_load_i => load, end_load_o => loaded, the_file_i => "jt.hex");


   verify:
   process
   begin
      outwrite("* Testing ROM loader");
      wait until loaded='1';
      wait until rising_edge(ck);
      -- Check some values
      -- Address 0
      addr <= (others => '0');
      wait until falling_edge(ck);
      -- 0x2842
      if not(data="10100001000010") then
         printf("Address 0 missmatch 0x%x\n",data);
         report "" severity failure;
      end if;
      -- Address 0x151
      addr <= "0101010001";
      wait until falling_edge(ck);
      -- 0x3400
      if not(data="11010000000000") then
         printf("Address 0x151 missmatch 0x%x\n",data);
         report "" severity failure;
      end if;
      -- Address 0x100
      addr <= "0100000000";
      wait until falling_edge(ck);
      -- 0x3083
      if not(data="11000010000011") then
         printf("Address 0x100 missmatch 0x%x\n",data);
         report "" severity failure;
      end if;
      end_test <= '1';
      wait;
   end process verify;
end architecture Simulator; -- Entity: Rom_Test


