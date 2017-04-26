------------------------------------------------------------------------------
----                                                                      ----
----  Memories package: BRAMs, FIFO and ROMLoader.                        ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  Description of various RAM memories. They should be optimized       ----
----  for various FPGA.                                                   ----
----  Package file.                                                       ----
----                                                                      ----
----  To Do:                                                              ----
----   -                                                                  ----
----                                                                      ----
----  Author:                                                             ----
----    - Juan Pablo D. Borgna, jpdborgna@yahoo.com.ar                    ----
----    - Salvador E. Tropea, salvador en inti gov ar                     ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Copyright (c) 2006-2009 Salvador E. Tropea <salvador en inti gov ar> ----
---- Copyright (c) 2005 Juan Pablo D. Borgna <jpdborgna@yahoo.com.ar>     ----
---- Copyright (c) 2005-2009 Instituto Nacional de Tecnología Industrial  ----
----                                                                      ----
---- Distributed under the GPL v2 or newer license                        ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Design unit:      Devices (Package)                                  ----
---- File name:        mems_pkg.vhdl                                      ----
---- Note:             None                                               ----
---- Limitations:      None known                                         ----
---- Errors:           None known                                         ----
---- Library:          None                                               ----
---- Dependencies:     IEEE.std_logic_1164                                ----
----                   IEEE.numeric_std                                   ----
---- Target FPGA:      None                                               ----
---- Language:         VHDL                                               ----
---- Wishbone:         ROMProgrammer is SLAVE (rev B.3)                   ----
---- Synthesis tools:  Xilinx Release 6.2.03i - xst G.31a                 ----
----                   Xilinx Release 8.2.02i - xst I.33                  ----
----                   Xilinx Release 9.2.03i - xst J.39                  ----
---- Simulation tools: GHDL [Sokcho edition] (0.1x)                       ----
---- Text editor:      SETEdit 0.5.x                                      ----
----                                                                      ----
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package Devices is

   @component:mems.vhdl@

   @component:fifo.vhdl@

   @component:fifo_rb.vhdl@

   @component:fifo_dual.vhdl@

   @component:rom_loader.vhdl@

   @component:rom_prog.vhdl@

end package Devices;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package Constants is
   -- EXPORT CONSTANTS
   -- ROM Programmer
   constant RPADDRL    : std_logic_vector(7 downto 0):="00000000";
   constant RPADDRH    : std_logic_vector(7 downto 0):="00000001";
   constant RPDATA     : std_logic_vector(7 downto 0):="00000010";
   -- END EXPORT CONSTANTS

   constant RPSZ       : natural:=2-1;
   constant RP_ADDR_L  : std_logic_vector(RPSZ downto 0):=
                         RPADDRL(RPSZ downto 0);
   constant RP_ADDR_H  : std_logic_vector(RPSZ downto 0):=
                         RPADDRH(RPSZ downto 0);
   constant RP_DATA    : std_logic_vector(RPSZ downto 0):=
                         RPDATA(RPSZ downto 0);
end package Constants;
