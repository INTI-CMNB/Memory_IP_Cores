Copyright (c) 2005 Juan Pablo D. Borgna <jpdborgna@yahoo.com.ar>
Copyright (c) 2006 Salvador E. Tropea <salvador en inti gov ar>
Copyright (c) 2005-2006 Instituto Nacional de Tecnología Industrial

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; version 2.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA

Library name: mems

Usage:
library mems;
use mems.Devices.all;

Dependencies: bakalint (Optional)
  For the testbench:
              c.stdio_h (C library for VHDL)
              ghdl

  This is a library with some descriptions of general purpose memories.
  Currently only Xilinx's BRAMs, a FIFO are available and a ROM for
simulations that can be loaded from a .hex.
  The objetive is to have memories with already tested architectures.
Currently all of them map properly to Xilinx devices.


Testbench:
----------

  Two are available:

testbench/fifo_tb.vhdl         Test for the FIFO
testbench/rom_loader_tb.vhdl   Test for the ROM loader.

  The testbench for the ROM needs the file testbench/jt.hex located at the
same directory.
  If you use ghdl you just need to run:

$ make test


Available entities for this library:
------------------------------------

Defined in mems_pkg.vhdl

SinglePortBRAM: Simple RAM.
DualPortBRAM: Dual ported RAM.
FullDualPortBRAM: Dual ported RAM with 2 clocks.
FIFO: FIFO memory.
ROMLoader: A ROM that can be loaded from a .hex file (for simulations).


Sources:
--------

fifo.vhdl            FIFO
hex_loader_pkg.vhdl  .HEX support and 2D array manipulation.
mems.vhdl            SinglePortBRAM , DualPortBRAM and FullDualPortBRAM
rom_loader.vhdl      ROMLoader


Entities connections:
---------------------

SinglePortBRAM:

Generics:
ADDR_W   : natural;    -- Address bus width
DATA_W   : natural;    -- Data bus width
SIZE     : natural;    -- Memory size
FALL_EDGE: boolean;    -- Clock active in falling edge

Ports:
clk_i : in  std_logic; -- Clock
we_i  : in  std_logic; -- Write enable
addr_i: in  std_logic_vector(ADDR_W-1 downto 0); -- Memory address
di_i  : in  std_logic_vector(DATA_W-1 downto 0); -- Data to write
do_o  : out std_logic_vector(DATA_W-1 downto 0); -- Read data

By default, the memory works using the rising edge of the clock.
The address bus is sampled using the clock and do_o is asynchronous.


DualPortBRAM:

Generics:
ADDR_W   : natural;    -- Address bus width
DATA_W   : natural;    -- Data bus width
SIZE     : natural;    -- Memory size
FALL_EDGE: boolean;    -- Clock active in falling edge

Ports:
clk_i : in  std_logic; -- Clock
we_i  : in  std_logic; -- Write enable
add1_i: in  std_logic_vector(ADDR_W-1 downto 0); -- Memory address 1
add2_i: in  std_logic_vector(ADDR_W-1 downto 0); -- Memory address 2
di_i  : in  std_logic_vector(DATA_W-1 downto 0); -- Data to write
do1_o : out std_logic_vector(DATA_W-1 downto 0); -- Read data 1
do2_o : out std_logic_vector(DATA_W-1 downto 0); -- Read data 2


FullDualPortBRAM:

Generics:
ADDR_W     : natural;   -- Address bus width
DATA_W     : natural;   -- Data bus width
SIZE       : natural;   -- Memory size
FALL_EDGE_1: boolean;   -- Clock 1 active in falling edge
FALL_EDGE_2: boolean;   -- Clock 2 active in falling edge

Ports:
clk1_i : in  std_logic; -- Clock 1
clk2_i : in  std_logic; -- Clock 2
we1_i  : in  std_logic; -- Write enable 1
we2_i  : in  std_logic; -- Write enable 2
add1_i : in  std_logic_vector(ADDR_W-1 downto 0); -- Memory address 1
add2_i : in  std_logic_vector(ADDR_W-1 downto 0); -- Memory address 2
di1_i  : in  std_logic_vector(DATA_W-1 downto 0); -- Data to write 1
di2_i  : in  std_logic_vector(DATA_W-1 downto 0); -- Data to write 2
do1_o  : out std_logic_vector(DATA_W-1 downto 0); -- Read data 1
do2_o  : out std_logic_vector(DATA_W-1 downto 0); -- Read data 2


FIFO:

Generics:
ADDR_W: natural;  -- Address bus width
DATA_W: natural;  -- Data bus width
DEPTH : natural;  -- Memory size

Ports:
clk_i   : in  std_logic;
rst_i   : in  std_logic;
we_i    : in  std_logic;
re_i    : in  std_logic;
datai_i : in  std_logic_vector(DATA_W-1 downto 0);
datao_o : out std_logic_vector(DATA_W-1 downto 0);
full_o  : out std_logic;
aval_o  : out std_logic;
empty_o : out std_logic);

Note: Don't write (we_i='1') if the FIFO are full (full_o='1').
      Don't read  (re_i='1') if the FIFO are empty(empty_o='1').
      Both operations are active by level.

Note: DEPTH <= 2**ADDR_W (less than or equal). Risk of sobrewriting data.


ROMLoader:

Generics:
ADDR_W : natural;  -- Address bus width
DATA_W : natural;  -- Data bus width
SIZE   : natural;  -- Memory size
ADD_BYT: boolean:=true;   -- Address in .HEX are counted in bytes
LIT_END: boolean:=true;   -- .HEX is in little endian format

Ports:
addr_i       : in  std_logic_vector(ADDR_W-1 downto 0); -- Address bus
data_o       : out std_logic_vector(DATA_W-1 downto 0); -- Data bus
ck_i         : in  std_logic; -- Clock
rst_i        : in  std_logic; -- Asynchronous reset
start_load_i : in  std_logic; -- Force a .hex load
end_load_o   : out std_logic; -- Indicates we finished the load
the_file_i   : in  string;    -- Name of the .hex file

  data_o remains on 0 while rst_i or start_load_i are '1'.
  To load the ROM you just need to put '1' in start_load_i and then wait
until end_load_o becomes '1'. Finaly you must drive start_load_i to '0'.
  The address bus is sampled using the rising edge of the clock.


