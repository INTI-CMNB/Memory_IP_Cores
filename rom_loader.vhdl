------------------------------------------------------------------------------
----                                                                      ----
----  ROM that can be loaded from a .hex file.                            ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  This file contains a ROM that can be loaded from a .hex file.       ----
----  This is only for testbenches and is quite useful when you need to   ----
----  change the memory content during at run-time.                       ----
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
---- Copyright (c) 2006 Instituto Nacional de Tecnología Industrial       ----
----                                                                      ----
---- Distributed under the GPL v2 or newer license                        ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Design unit:      ROMLoader (Simulator)                              ----
---- File name:        rom_loader.vhdl                                    ----
---- Note:             None                                               ----
---- Limitations:      None known                                         ----
---- Errors:           None known                                         ----
---- Library:          mems                                               ----
---- Dependencies:     IEEE.std_logic_1164                                ----
----                   IEEE.numeric_std                                   ----
----                   Work.HexLoader                                     ----
---- Target FPGA:      None                                               ----
---- Language:         VHDL                                               ----
---- Wishbone:         N/A                                                ----
---- Synthesis tools:  None                                               ----
---- Simulation tools: GHDL [Sokcho edition] (0.2x)                       ----
---- Text editor:      SETEdit 0.5.x                                      ----
----                                                                      ----
------------------------------------------------------------------------------

use Work.HexLoader.all;
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ROMLoader is
   generic(
      ADDR_W : natural;         -- Address bus width
      DATA_W : natural;         -- Data bus width
      SIZE   : natural;         -- Number of elements
      ADD_BYT: boolean:=true;   -- Address in .HEX are counted in bytes
      LIT_END: boolean:=true);  -- .HEX is in little endian format
   port(
      addr_i       : in  std_logic_vector(ADDR_W-1 downto 0);
      data_o       : out std_logic_vector(DATA_W-1 downto 0);
      data_i       : in  std_logic_vector(DATA_W-1 downto 0):=(others => '0');
      we_i         : in  std_logic:='0';
      ck_i         : in  std_logic;
      rst_i        : in  std_logic;
      start_load_i : in  std_logic;
      end_load_o   : out std_logic;
      the_file_i   : in  string);
end entity ROMLoader;

architecture Simulator of ROMLoader is
   signal data_v   : std_logic_vector(DATA_W-1 downto 0):=(others => '0');
begin
   rom:
   process (ck_i,rst_i,start_load_i)
      variable mem_data : std_logic_2d(SIZE-1 downto 0,DATA_W-1 downto 0);
      variable aux_data : std_logic_vector(DATA_W-1 downto 0);
   begin
      end_load_o <= '0';
      if start_load_i='1' then
         data_v <= (others => '0');
         mem_data:=read_hex_file(SIZE,DATA_W,the_file_i,ADD_BYT,LIT_END);
         end_load_o <= '1';
      elsif rst_i='1' then
         data_v <= (others => '0');
      elsif rising_edge(ck_i) then
         get_2d_element(aux_data,mem_data,to_integer(unsigned(addr_i)));
         data_v <= aux_data;
         if we_i='1' then
            set_2d_element(mem_data,to_integer(unsigned(addr_i)),data_i);
         end if;
      end if;
   end process rom;
   data_o <= data_v;
end architecture Simulator; -- Entity: ROMLoader

