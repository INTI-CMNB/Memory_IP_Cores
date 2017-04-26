------------------------------------------------------------------------------
----                                                                      ----
----  Memories.                                                           ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  Description of various RAM memories. They should be optimized       ----
----  for various FPGA.                                                   ----
----                                                                      ----
----  To Do:                                                              ----
----   -                                                                  ----
----                                                                      ----
----  Author:                                                             ----
----    - Juan Pablo D. Borgna, jpdborgna@yahoo.com.ar                    ----
----    - Salvador E. Tropea, salvador@inti.gob.ar                        ----
----    - Rodrigo A. Melo, rmelo@inti.gob.ar                              ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Copyright (c) 2010 Rodrigo A. Melo <rmelo@inti.gob.ar>               ----
---- Copyright (c) 2006 Salvador E. Tropea <salvador@inti.gob.ar>         ----
---- Copyright (c) 2005 Juan Pablo D. Borgna <jpdborgna@yahoo.com.ar>     ----
---- Copyright (c) 2005-2010 Instituto Nacional de Tecnología Industrial  ----
----                                                                      ----
---- Distributed under the GPL v2 or newer license                        ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Design unit:      SinglePortBRAM(Xilinx)   (Entity and architecture) ----
---- Design unit:      DualPortBRAM(Xilinx)     (Entity and architecture) ----
---- Design unit:      FullDualPortBRAM(Xilinx) (Entity and architecture) ----
---- File name:        mems.vhdl                                          ----
---- Note:             None                                               ----
---- Limitations:      None known                                         ----
---- Errors:           None known                                         ----
---- Library:          None                                               ----
---- Dependencies:     IEEE.std_logic_1164                                ----
----                   IEEE.numeric_std                                   ----
---- Target FPGA:      Spartan II (XC2S100-5-PQ208)                       ----
---- Language:         VHDL                                               ----
---- Wishbone:         None                                               ----
---- Synthesis tools:  Xilinx Release 6.2.03i - xst G.31a                 ----
---- Simulation tools: GHDL [Sokcho edition] (0.1x)                       ----
---- Text editor:      SETEdit 0.5.x                                      ----
----                                                                      ----
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SinglePortBRAM is
   generic(
      ADDR_W   : natural;
      DATA_W   : natural;
      SIZE     : natural;
      FALL_EDGE: boolean:=false);
   port(
      clk_i : in  std_logic;
      we_i  : in  std_logic;
      addr_i: in  std_logic_vector(ADDR_W-1 downto 0);
      di_i  : in  std_logic_vector(DATA_W-1 downto 0);
      do_o  : out std_logic_vector(DATA_W-1 downto 0));
end entity SinglePortBRAM;

architecture Xilinx of SinglePortBRAM is
    type   ram_type is array(SIZE-1 downto 0) of std_logic_vector (DATA_W-1 downto 0);
    signal ram   : ram_type;
    signal read_a: std_logic_vector(ADDR_W-1 downto 0):=(others => '0');
begin

   use_rising_edge:
   if not FALL_EDGE generate
      the_ram:
      process (clk_i)
      begin
         if rising_edge(clk_i) then
            if we_i='1' then
               ram(to_integer(unsigned(addr_i))) <= di_i;
            end if;
            read_a <= addr_i;
         end if;
      end process the_ram;
   end generate use_rising_edge;

   use_falling_edge:
   if FALL_EDGE generate
      the_ram:
      process (clk_i)
      begin
         if falling_edge(clk_i) then
            if we_i='1' then
               ram(to_integer(unsigned(addr_i))) <= di_i;
            end if;
            read_a <= addr_i;
         end if;
      end process the_ram;
   end generate use_falling_edge;

   do_o <= ram(to_integer(unsigned(read_a)));

end architecture Xilinx; -- Entity: SinglePortBRAM
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DualPortBRAM is
   generic(
      ADDR_W   : natural;
      DATA_W   : natural;
      SIZE     : natural;
      FALL_EDGE: boolean:=false);
   port(
      clk_i : in  std_logic;
      we_i  : in  std_logic;
      add1_i: in  std_logic_vector(ADDR_W-1 downto 0);
      add2_i: in  std_logic_vector(ADDR_W-1 downto 0);
      di_i  : in  std_logic_vector(DATA_W-1 downto 0);
      do1_o : out std_logic_vector(DATA_W-1 downto 0);
      do2_o : out std_logic_vector(DATA_W-1 downto 0));
end entity DualPortBRAM;

architecture Xilinx of DualPortBRAM is
    type   ram_type is array(SIZE-1 downto 0) of std_logic_vector (DATA_W-1 downto 0);
    signal ram    : ram_type;
    signal read_a1: std_logic_vector(ADDR_W-1 downto 0):=(others => '0');
    signal read_a2: std_logic_vector(ADDR_W-1 downto 0):=(others => '0');
    --synopsys translate off
    signal do2_r  : std_logic_vector(DATA_W-1 downto 0):=(others => '0');
    --synopsys translate on
begin

   use_rising_edge:
   if not FALL_EDGE generate
      -- memory process
      the_ram:
      process (clk_i)
      begin
         if rising_edge(clk_i) then
            if we_i='1' then
               ram(to_integer(unsigned(add1_i))) <= di_i;
            end if;
            read_a1 <= add1_i;
            read_a2 <= add2_i;
         end if;
      end process the_ram;
      -- output latch WRITE_FIRST mode behavior
      --synopsys translate off
      do2_latch_pro:
      process (clk_i)
      begin
         if rising_edge(clk_i) then
            if we_i='1' and add1_i=add2_i then
               do2_r <= (others => 'X');
            else
               do2_r <= ram(to_integer(unsigned(add2_i))); -- use add2_i!
            end if;
         end if;
      end process do2_latch_pro;
      --synopsys translate on
   end generate use_rising_edge;

   use_falling_edge:
   if FALL_EDGE generate
      -- memory process
      the_ram:
      process (clk_i)
      begin
         if falling_edge(clk_i) then
            if we_i='1' then
               ram(to_integer(unsigned(add1_i))) <= di_i;
            end if;
            read_a1 <= add1_i;
            read_a2 <= add2_i;
         end if;
      end process the_ram;
      -- output latch WRITE_FIRST mode behavior
      --synopsys translate off
      do2_latch_pro:
      process (clk_i)
      begin
         if falling_edge(clk_i) then
            if we_i='1' and add1_i=add2_i then
               do2_r <= (others => 'X');
            else
               do2_r <= ram(to_integer(unsigned(add2_i))); -- use add2_i!
            end if;
         end if;
      end process do2_latch_pro;
      --synopsys translate on
   end generate use_falling_edge;

   do1_o <= ram(to_integer(unsigned(read_a1)));
   do2_o <= ram(to_integer(unsigned(read_a2)))
   --synopsys translate off
            when false else do2_r
   --synopsys translate on
   ;

 
end architecture Xilinx; -- Entity: DualPortBRAM
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FullDualPortBRAM is
   generic(
      ADDR_W     : natural;
      DATA_W     : natural;
      SIZE       : natural;
      FALL_EDGE_1: boolean:=false;
      FALL_EDGE_2: boolean:=false);
   port(
      clk1_i : in  std_logic;
      clk2_i : in  std_logic;
      we1_i  : in  std_logic;
      we2_i  : in  std_logic;
      add1_i : in  std_logic_vector(ADDR_W-1 downto 0);
      add2_i : in  std_logic_vector(ADDR_W-1 downto 0);
      di1_i  : in  std_logic_vector(DATA_W-1 downto 0);
      di2_i  : in  std_logic_vector(DATA_W-1 downto 0);
      do1_o  : out std_logic_vector(DATA_W-1 downto 0);
      do2_o  : out std_logic_vector(DATA_W-1 downto 0));
end entity FullDualPortBRAM;

architecture Xilinx of FullDualPortBRAM is
    type ram_type is array(SIZE-1 downto 0) of std_logic_vector (DATA_W-1 downto 0);
    shared variable ram : ram_type;
begin

   use_rising_edge_side1:
   if not FALL_EDGE_1 generate
      side1:
      process (clk1_i)
      begin
         if rising_edge(clk1_i) then
            if we1_i='1' then
               ram(to_integer(unsigned(add1_i))) := di1_i;
            end if;
            do1_o <= ram(to_integer(unsigned(add1_i)));
         end if;
      end process side1;
   end generate use_rising_edge_side1;

   use_falling_edge_side1:
   if FALL_EDGE_1 generate
      side1:
      process (clk1_i)
      begin
         if falling_edge(clk1_i) then
            if we1_i='1' then
               ram(to_integer(unsigned(add1_i))) := di1_i;
            end if;
            do1_o <= ram(to_integer(unsigned(add1_i)));
         end if;
      end process side1;
   end generate use_falling_edge_side1;

   use_rising_edge_side2:
   if not FALL_EDGE_2 generate
      side2:
      process (clk2_i)
      begin
         if rising_edge(clk2_i) then
            if we2_i='1' then
               ram(to_integer(unsigned(add2_i))) := di2_i;
            end if;
            do2_o <= ram(to_integer(unsigned(add2_i)));
         end if;
      end process side2;
   end generate use_rising_edge_side2;

   use_falling_edge_side2:
   if FALL_EDGE_2 generate
      side2:
      process (clk2_i)
      begin
         if falling_edge(clk2_i) then
            if we2_i='1' then
               ram(to_integer(unsigned(add2_i))) := di2_i;
            end if;
            do2_o <= ram(to_integer(unsigned(add2_i)));
         end if;
      end process side2;
   end generate use_falling_edge_side2;

end architecture Xilinx; -- Entity: FullDualPortBRAM

