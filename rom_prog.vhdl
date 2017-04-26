------------------------------------------------------------------------------
----                                                                      ----
----  In Circuit ROM Programmer                                           ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  This module implements a WISHBONE slave peripheral that can be used ----
---- to program the program memory of a CPU.   The WISHBONE master must   ----
---- communicate with the host. One option is to use the EPP to WISHBONE  ----
---- bridge.@p                                                            ----
----  The core have three registers: RPADDRL and RPADDRH are R/W and they ----
---- are a memory pointer. RPDATA is R/W. The first read or write         ----
---- operates on the low nibble and the second on the higher. After the   ----
---- second access an address increment is performed and we start with    ----
---- the lower nibble again. When you write a word the value will be      ----
---- stored in the next address, but when you read you get the content of ----
---- the current address.@p                                               ----
----  In the current implementation RPDATA+1 is a shadow of RPDATA.@p     ----
----  This core can introduce 1 wait state when the address is modified   ----
---- and a WISHBONE access is performed in the next clock cycle. This     ----
---- applies to the autoincrement. This is needed in order to let the     ----
---- memory latch the new address.@p                                      ----
----  Note that the code is a little bit complex to allow various memory  ----
---- sizes.@p                                                             ----
----                                                                      ----
----  To Do:                                                              ----
----  -                                                                   ----
----                                                                      ----
----  Author:                                                             ----
----    - Salvador E. Tropea, salvador en inti gob ar                     ----
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
---- Design unit:      ROMProgrammer(RTL)                                 ----
---- File name:        rom_prog.vhdl                                      ----
---- Note:             None                                               ----
---- Limitations:      None                                               ----
---- Errors:           None known                                         ----
---- Library:          picrisc                                            ----
---- Dependencies:     IEEE.std_logic_1164                                ----
----                   IEEE.numeric_std                                   ----
----                   mems.Constants                                     ----
---- Target FPGA:      Spartan II (XC2S100-5-PQ208)                       ----
---- Language:         VHDL                                               ----
---- Wishbone:         None                                               ----
---- Synthesis tools:  Xilinx Release 8.2.02i - xst I.33                  ----
---- Simulation tools: GHDL [Sokcho edition] (0.2x)                       ----
---- Text editor:      SETEdit 0.5.x                                      ----
---- Testbench:        testbench/rom_prog_tb.vhdl                         ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Wishbone Datasheet                                                   ----
----                                                                      ----
----  1 Revision level                      B.3                           ----
----  2 Type of interface                   SLAVE                         ----
----  3 Defined signal names                RST_I => wb_rst_i             ----
----                                        CLK_I => wb_clk_i             ----
----                                        ADR_I => wb_adr_i             ----
----                                        DAT_I => wb_dat_i             ----
----                                        DAT_O => wb_dat_o             ----
----                                        WE_I  => wb_we_i              ----
----                                        ACK_O => wb_ack_o             ----
----  4 ERR_I                               Unsupported                   ----
----  5 RTY_I                               Unsupported                   ----
----  6 TAGs                                None                          ----
----  7 Port size                           8-bit (*)                     ----
----  8 Port granularity                    8-bit                         ----
----  9 Maximum operand size                8-bit                         ----
---- 10 Data transfer ordering              N/A                           ----
---- 11 Data transfer sequencing            Undefined                     ----
---- 12 Constraints on the CLK_I signal     None                          ----
----                                                                      ----
---- (*) Only 2 bits used                                                 ----
----                                                                      ----
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library mems;
use mems.Constants.all;

entity ROMProgrammer is
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
end entity ROMProgrammer;

architecture RTL of ROMProgrammer is
   constant PADDER  : std_logic_vector(15-WORD_W downto 0):=(others => '0');
   signal addr      : unsigned(PC_W-1 downto 0):=(others => '1');
   signal data      : std_logic_vector(WORD_W-1 downto 0);
   signal lh_sel    : std_logic:='0';
   signal do_wait   : std_logic:='0';
begin
   wb_ack_o <= wb_stb_i and not(do_wait);

   registers:
   process (wb_clk_i)
      variable addr_h : integer;
   begin
      if rising_edge(wb_clk_i) then
         do_wait <= '0';
         wr_o <= '0';
         if wb_rst_i='1' then
            addr <= (others => '1');
            lh_sel <= '0';
         else
            if wb_stb_i='1' and do_wait='0' then
               if wb_we_i='1' then
                  if wb_adr_i=RP_ADDR_L then
                     if PC_W>8 then
                        addr_h:=8;
                     else
                        addr_h:=PC_W;
                     end if;
                     addr(addr_h-1 downto 0) <= unsigned(wb_dat_i(addr_h-1 downto 0));
                     lh_sel <= '0';
                     do_wait <= '1';
                  elsif wb_adr_i=RP_ADDR_H then
                     if PC_W>8 then
                        addr_h:=PC_W-1;
                        addr(addr_h downto 8) <= unsigned(wb_dat_i(addr_h-8 downto 0));
                     end if;
                     do_wait <= '1';
                  else -- RP_DATA
                     if lh_sel='0' then
                        lh_sel <= '1';
                        data(7 downto 0) <= wb_dat_i;
                     else
                        lh_sel <= '0';
                        data(WORD_W-1 downto 8) <= wb_dat_i(WORD_W-1-8 downto 0);
                        wr_o <= '1';
                        addr <= addr+1;
                        do_wait <= '1';
                     end if;
                  end if;
               elsif wb_adr_i/=RP_ADDR_L and wb_adr_i/=RP_ADDR_H then
                  if lh_sel='0' then
                     lh_sel <= '1';
                  else
                     lh_sel <= '0';
                     addr <= addr+1;
                     do_wait <= '1';
                  end if;
               end if;
            end if;
         end if;
      end if;
   end process registers;

   pc_w_b8:
   if PC_W>8 generate
      wb_dat_o <= std_logic_vector(addr(7 downto 0))
                    when wb_adr_i=RP_ADDR_L else
                  std_logic_vector(resize(addr(PC_W-1 downto 8),8))
                    when wb_adr_i=RP_ADDR_H else
                  prgbus_i(7 downto 0)
                    when lh_sel='0' else
                  PADDER & prgbus_i(WORD_W-1 downto 8);
   end generate pc_w_b8;

   pc_w_le8:
   if PC_W<=8 generate
      wb_dat_o <= std_logic_vector(resize(addr(PC_W-1 downto 0),8))
                    when wb_adr_i=RP_ADDR_L else
                  x"00"
                    when wb_adr_i=RP_ADDR_H else
                  prgbus_i(7 downto 0)
                    when lh_sel='0' else
                  PADDER & prgbus_i(WORD_W-1 downto 8);
   end generate pc_w_le8;

   prgcnt_o <= addr(PC_W-1 downto 0);
   prgbus_o <= data;
end architecture RTL; -- Entity: ROMProgrammer

