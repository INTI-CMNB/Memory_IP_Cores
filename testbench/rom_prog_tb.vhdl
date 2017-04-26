------------------------------------------------------------------------------
----                                                                      ----
----  In Circuit ROM Programmer [Testbench]                               ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  This testbench connects the ROMProgrammer module to a 4 words       ----
---- memory and then tests the write, read and address increment.         ----
----                                                                      ----
----  To Do:                                                              ----
----  -                                                                   ----
----                                                                      ----
----  Author:                                                             ----
----    - Salvador E. Tropea, salvador en inti gov ar                     ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Copyright (c) 2007-2009 Salvador E. Tropea <salvador en inti gov ar> ----
---- Copyright (c) 2007-2009 Instituto Nacional de Tecnología Industrial  ----
----                                                                      ----
---- Distributed under the GPL v2 or newer license                        ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Design unit:      ROM_Prog_TB(Simulator)                             ----
---- File name:        rom_prog_tb.vhdl                                   ----
---- Note:             None                                               ----
---- Limitations:      None                                               ----
---- Errors:           None known                                         ----
---- Library:          None                                               ----
---- Dependencies:     IEEE.std_logic_1164                                ----
----                   IEEE.numeric_std                                   ----
----                   std.textio                                         ----
----                   mems.Devices                                       ----
----                   mems.Constants                                     ----
----                   wb_handler.WishboneTB                              ----
---- Target FPGA:      N/A                                                ----
---- Language:         VHDL                                               ----
---- Wishbone:         None                                               ----
---- Synthesis tools:  N/A                                                ----
---- Simulation tools: GHDL [Sokcho edition] (0.2x)                       ----
---- Text editor:      SETEdit 0.5.x                                      ----
----                                                                      ----
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library std;
use std.textio.all;
library wb_handler;
use wb_handler.WishboneTB.all;
library mems;
use mems.Devices.all;
use mems.Constants.all;
library utils;
use utils.StdLib.all;
use utils.StdIO.all;

entity ROM_Prog_TB is
end entity ROM_Prog_TB;

architecture Simulator of ROM_Prog_TB is
   -- Clock=25 MHz
   constant FREQUENCY    : positive:=25e6;
   constant PC_W         : integer:=2;
   constant SIZE         : integer:=2**PC_W-1;
   constant WORD_W       : positive:=14;
   constant PADDER       : std_logic_vector(15-WORD_W downto 0):=(others => '0');

   signal wbi         : wb_bus_i_type;
   signal wbo         : wb_bus_o_type;
   -- WISHBONE
   signal wb_rst      : std_logic:='1';
   signal wb_clk      : std_logic;--:='0';
   signal wb_adr      : std_logic_vector(7 downto 0);
   signal adr_o1      : std_logic_vector(1 downto 0);
   signal wb_dati     : std_logic_vector(7 downto 0):=(others => 'Z');
   signal wb_dato     : std_logic_vector(7 downto 0);
   signal wb_we       : std_logic;
   signal wb_stb      : std_logic;
   signal wb_cyc      : std_logic;
   signal wb_ack      : std_logic:='0';

   signal end_test    : std_logic:='0';

   signal wr          : std_logic;
   signal addr        : unsigned(PC_W-1 downto 0);
   signal data_to_r   : std_logic_vector(WORD_W-1 downto 0);
   signal data_from_r : std_logic_vector(WORD_W-1 downto 0);

   type rom_type is array (0 to SIZE) of std_logic_vector(WORD_W-1 downto 0);
   constant ROMv : rom_type:=
   (
    ('1','1','0','0','0','0','1','1','1','1','1','1','1','1'), -- 0x000 = 0x30FF
    ('0','1','0','1','1','0','1','0','0','0','0','0','1','1'), -- 0x001 = 0x1683
    ('0','0','0','0','0','0','1','0','0','0','0','1','0','1'), -- 0x002 = 0x0085
    ('0','0','0','0','0','1','0','0','0','0','0','0','1','1')  -- 0x003 = 0x0103
   );
begin
   the_clk : SimpleClock
      generic map(
         FREQUENCY => FREQUENCY)
      port map(
         clk_o  => wb_clk, rst_o => wb_rst, stop_i => end_test);
   
   -- Connect the records to the individual signals
   wbi.clk  <= wb_clk;
   wbi.rst  <= wb_rst;
   wbi.dato <= wb_dato;
   wbi.ack  <= wb_ack;

   wb_stb   <= wbo.stb;
   wb_we    <= wbo.we;
   wb_adr   <= wbo.adr;
   wb_dati  <= wbo.dati;

   -- Program "ROM"
   ROM : SinglePortBRAM
      generic map(
         ADDR_W => PC_W, DATA_W => WORD_W, SIZE => 2**PC_W)
      port map(
         clk_i => wb_clk, we_i => wr, addr_i => std_logic_vector(addr),
         di_i => data_to_r, do_o => data_from_r);

   -- ROM Programmer (Wishbone slave)
   adr_o1 <= wb_adr(1 downto 0);
   programmer : ROMProgrammer
      generic map(
         PC_W => PC_W, WORD_W => WORD_W)
      port map(-- Wishbone
         wb_rst_i => wb_rst,  wb_clk_i => wb_clk,  wb_adr_i => adr_o1,
         wb_dat_o => wb_dato, wb_dat_i => wb_dati, wb_we_i  => wb_we,
         wb_stb_i => wb_stb,  wb_ack_o => wb_ack,
         -- ROM side
         prgcnt_o => addr, prgbus_o => data_to_r, prgbus_i => data_from_r,
         wr_o => wr);

   sequence:
   process
     variable l : line;
     variable d : std_logic_vector(WORD_W-1 downto 0);
   begin
      wait until wb_rst='0';

      outwrite("* Checking start-up");
      WBRead(RPADDRL,wbi,wbo);
      assert wb_dato=x"03" report "Wrong reset" severity failure;
      WBRead(RPADDRH,wbi,wbo);
      assert wb_dato=x"00" report "Wrong reset" severity failure;

      outwrite("+ Testing address registers");
      WBWrite(RPADDRL,x"55",wbi,wbo);
      WBWrite(RPADDRH,x"AA",wbi,wbo);
      WBRead(RPADDRL,wbi,wbo);
      assert wb_dato=x"01" report "Address low" severity failure;
      WBRead(RPADDRH,wbi,wbo);
      assert wb_dato=x"00" report "Address high" severity failure;
      WBWrite(RPADDRL,x"03",wbi,wbo);

      outwrite("+ Filling the memory");
      for i in ROMv'range loop
          d:=ROMv(i);
          WBWrite(RPDATA,d(7 downto 0),wbi,wbo);
          WBWrite(RPDATA,PADDER & d(WORD_W-1 downto 8),wbi,wbo);
      end loop;

      outwrite("+ Verifying the increment");
      WBRead(RPADDRL,wbi,wbo);
      assert wb_dato=x"03" report "Wrong increment" severity failure;
      WBRead(RPADDRH,wbi,wbo);
      assert wb_dato=x"00" report "Wrong increment" severity failure;

      outwrite("+ Verifying the content");
      WBWrite(RPADDRL,x"00",wbi,wbo);
      for i in ROMv'range loop
          WBRead(RPDATA,wbi,wbo);
          d(7 downto 0):=wb_dato;
          WBRead(RPDATA,wbi,wbo);
          d(WORD_W-1 downto 8):=wb_dato(WORD_W-1-8 downto 0);
          assert d=ROMv(i) report "Content missmatch d="&
             integer'image(to_integer(unsigned(d))) severity failure;
      end loop;

      outwrite("+ Verifying the increment");
      WBRead(RPADDRL,wbi,wbo);
      assert wb_dato=x"00" report "Wrong increment" severity failure;
      WBRead(RPADDRH,wbi,wbo);
      assert wb_dato=x"00" report "Wrong increment" severity failure;

      outwrite("* End of test, success");
      end_test <= '1';
      wait;
   end process sequence;

end architecture Simulator; -- Entity: ROM_Prog_TB

