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

   component SinglePortBRAM is
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
   end component SinglePortBRAM;

   component DualPortBRAM is
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
   end component DualPortBRAM;

   component FullDualPortBRAM is
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
   end component FullDualPortBRAM;

   component FIFO is
         generic(
            ADDR_W       : natural:=5;     -- Address width
            DATA_W       : natural:=8;     -- Data width
            DEPTH        : natural:=32;    -- Size (<=2**ADDR_W)
            CONCURRENT   : boolean:=true); -- Support concurrent read and writes
         port(
            clk_i   : in  std_logic; -- Clock
            rst_i   : in  std_logic; -- Reset
            we_i    : in  std_logic; -- Write enable
            re_i    : in  std_logic; -- Read enable
            datai_i : in  std_logic_vector(DATA_W-1 downto 0); -- Input Data
            datao_o : out std_logic_vector(DATA_W-1 downto 0); -- Output Data
            full_o  : out std_logic; -- FIFO is full
            avail_o : out std_logic; -- FIFO have data
            empty_o : out std_logic; -- FIFO is empty
            used_o  : out unsigned(ADDR_W downto 0)); -- Ammount used
   end component FIFO;

   component FIFO_RRB is
         generic(
            ADDR_W     : natural:=9;
            DATA_W     : natural:=8;
            DEPTH      : natural:=512);
         port(
            clk_i      : in  std_logic; -- Clock
            rst_i      : in  std_logic; -- Reset
            -- Write side
            we_i       : in  std_logic; -- Write enable
            datai_i    : in  std_logic_vector(DATA_W-1 downto 0); -- Input Data
            full_o     : out std_logic; -- FIFO is full
            -- Read side
            re_i       : in  std_logic; -- Read enable
            datao_o    : out std_logic_vector(DATA_W-1 downto 0); -- Output Data
            avail_o    : out std_logic; -- FIFO have data
            commit_i   : in  std_logic; -- Commit reads
            rollback_i : in  std_logic; -- Rollback reads
            used_o     : out unsigned(ADDR_W downto 0)); -- Ammount used
   end component FIFO_RRB;

   component FIFO_WRB is
         generic(
            ADDR_W     : natural:=9;
            DATA_W     : natural:=8;
            DEPTH      : natural:=512);
         port(
            clk_i      : in  std_logic; -- Clock
            rst_i      : in  std_logic; -- Reset
            -- Write side
            we_i       : in  std_logic; -- Write enable
            datai_i    : in  std_logic_vector(DATA_W-1 downto 0); -- Input Data
            full_o     : out std_logic; -- FIFO is full
            commit_i   : in  std_logic; -- Commit writes
            rollback_i : in  std_logic; -- Rollback writes
            used_o     : out unsigned(ADDR_W downto 0); -- Ammount used
            -- Read side
            re_i       : in  std_logic; -- Read enable
            datao_o    : out std_logic_vector(DATA_W-1 downto 0); -- Output Data
            avail_o    : out std_logic); -- FIFO have data
   end component FIFO_WRB;

   component FIFO_Dual is
      generic(
            ADDR_W     : natural:=8;
            DATA_W     : natural:=8);
      port(
            clk_i      : in  std_logic; -- Clock
            rst_i      : in  std_logic; -- Reset
            -- Out FIFO (host -> device)
            -- Write side (w/rollback)
            o_we_i     : in  std_logic; -- Out Write enable
            o_data_i   : in  std_logic_vector(DATA_W-1 downto 0); -- Out Input Data
            o_commit_i : in  std_logic; -- Out Commit writes
            o_flush_i  : in  std_logic; -- Out Flush writes
            o_bavail_o : out std_logic; -- Out FIFO can receive new packet
            -- Read side
            o_re_i     : in  std_logic; -- Read enable
            o_data_o   : out std_logic_vector(DATA_W-1 downto 0); -- Out Output Data
            o_avail_o  : out std_logic; -- Out FIFO have data
            -- Debug
            --cnt_wr_o   : out unsigned(3 downto 0);
            --cnt_rd_o   : out unsigned(3 downto 0);
            -- In FIFO (device -> host)
            -- Write side
            i_we_i     : in  std_logic; -- In Write enable
            i_data_i   : in  std_logic_vector(DATA_W-1 downto 0); -- In Input Data
            i_full_o   : out std_logic; -- In FIFO is full
            i_ready_i  : in  std_logic; -- In data ready to send
            -- Read side
            i_re_i     : in  std_logic; -- In Read enable
            i_data_o   : out std_logic_vector(DATA_W-1 downto 0); -- In Output Data
            i_bavail_o : out std_logic; -- In FIFO have data to send
            i_commit_i : in  std_logic; -- In Commit reads
            i_flush_i  : in  std_logic; -- In Flush reads
            i_used_o   : out unsigned(ADDR_W downto 0) -- Ammount of In data available
           );
   end component FIFO_Dual;

   component ROMLoader is
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
   end component ROMLoader;

   component ROMProgrammer is
      generic(
         PC_W    : integer range 0 to 16:=13;  -- Address width
         WORD_W  : positive:=14;               -- Word size
         DATA_W  : positive:=8);               -- WISHBONE data width
      port(
         -- Wishbone slave signals
         wb_rst_i   : in    std_logic; -- Reset
         wb_clk_i   : in    std_logic; -- Clock
         wb_adr_i   : in    std_logic_vector(1 downto 0); -- I/O Address
         wb_dat_o   : out   std_logic_vector(DATA_W-1 downto 0); -- Data Bus output
         wb_dat_i   : in    std_logic_vector(DATA_W-1 downto 0); -- Data Bus input
         wb_stb_i   : in    std_logic; -- Strobe input
         wb_we_i    : in    std_logic; -- Write Enable input
         wb_ack_o   : out   std_logic; -- Acknowledge output
         -- ROM side
         prgcnt_o   : out   unsigned(PC_W-1 downto 0); -- Address (Program Counter)
         prgbus_o   : out   std_logic_vector(WORD_W-1 downto 0); -- Instruction to write
         prgbus_i   : in    std_logic_vector(WORD_W-1 downto 0); -- Instruction read
         wr_o       : out   std_logic); -- Write to memory
   end component ROMProgrammer;

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
