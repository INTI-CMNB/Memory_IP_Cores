------------------------------------------------------------------------------
----                                                                      ----
----  FIFO Memory                                                         ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  FIFO memory with empty, full and avalible outputs.                  ----
----                                                                      ----
----  To Do:                                                              ----
----   -                                                                  ----
----                                                                      ----
----  Author:                                                             ----
----    - Juan Pablo D. Borgna, jpdborgna@yahoo.com.ar                    ----
----    - Salvador E. Tropea, salvador en inti gov ar                     ----
----    - Rodrigo A. Melo, rmelo@inti.gov.ar                              ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Copyright (c) 2006-2008 Salvador E. Tropea <salvador en inti gov ar> ----
---- Copyright (c) 2007 Rodrigo A. Melo <rmelo@inti.gov.ar>               ----
---- Copyright (c) 2005 Juan Pablo D. Borgna <jpdborgna@yahoo.com.ar>     ----
---- Copyright (c) 2005-2008 Instituto Nacional de Tecnología Industrial  ----
----                                                                      ----
---- Distributed under the GPL v2 or newer license                        ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Design unit:      FIFO(RTL)        (Entity and architecture)         ----
---- File name:        fifo.vhdl                                          ----
---- Note:             If you read when no data is available or write     ----
----                   when the FIFO is full the result is undefined.     ----
----                   Data is available in the next clock for  reads,    ----
----                   this is how BRAMs work (1 clock addr latch)        ----
---- Limitations:      None known                                         ----
---- Errors:           None known                                         ----
---- Library:          None                                               ----
---- Dependencies:     IEEE.std_logic_1164                                ----
----                   IEEE.numeric_std                                   ----
----                   mems.Devices                                       ----
---- Target FPGA:      Spartan II (XC2S100-5-PQ208)                       ----
---- Language:         VHDL                                               ----
---- Wishbone:         None                                               ----
---- Synthesis tools:  Xilinx Release 6.2.03i - xst G.31a                 ----
----                   Xilinx Release 8.2.02i - xst I.33                  ----
----                   Xilinx Release 9.2.03i - xst J.39                  ----
---- Simulation tools: GHDL [Sokcho edition] (0.1x-0.2x)                  ----
---- Text editor:      SETEdit 0.5.x                                      ----
----                                                                      ----
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library mems;
use mems.Devices.all;

entity FIFO is
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
end entity FIFO;

architecture RTL of FIFO is
   constant ADDR_LIMIT : unsigned(ADDR_W-1 downto 0):=to_unsigned(DEPTH-1,ADDR_W);
   signal addr_re : unsigned(ADDR_W-1 downto 0):=(others => '0');
   signal addr_wr : unsigned(ADDR_W-1 downto 0):=(others => '0');
   signal diff    : natural range 0 to DEPTH:=0;
   signal full    : std_logic:='0';
   signal avail   : std_logic;
   signal avail_ff: std_logic;

begin

   --use a dual port Block Ram
   fifo_mem: DualPortBRAM
      generic map(
         ADDR_W => ADDR_W, DATA_W => DATA_W, SIZE => DEPTH)
      port map(
         clk_i => clk_i, we_i => we_i, add1_i => std_logic_vector(addr_wr),
         add2_i => std_logic_vector(addr_re), di_i => datai_i,
         do2_o => datao_o);

   --use delay for avail signal rising edge
   avail_ff_proc:
   process (clk_i, rst_i)
   begin
      if rst_i='1' then
         avail_ff <= '0';
      elsif rising_edge(clk_i) then
         if diff/=0 then
            avail_ff <= '1';
         else
            avail_ff <= '0';
         end if;
      end if;
   end process avail_ff_proc;
   avail <= '1' when diff/=0 else '0';
   
   --avail signal output
   avail_o <= avail and avail_ff;

   full  <= '1' when diff=DEPTH else '0';
   used_o <= to_unsigned(diff,ADDR_W+1); -- [0;DEPTH] => +1

   FIFO_work:
   process (clk_i, rst_i)
      variable adjust : boolean:=false;
   begin
      if 2**ADDR_W/=DEPTH then
         -- Note: This is needed because XST isn't good enough
         adjust:=true;
      end if;
      if rst_i='1' then
         addr_wr <= (others => '0');
         addr_re <= (others => '0');
         diff    <= 0;
      elsif rising_edge(clk_i) then
         if we_i='1' then   -- Write to the FIFO.
            if adjust and addr_wr=ADDR_LIMIT then
               addr_wr <= (others => '0');
            else
               addr_wr <= addr_wr+1;
            end if;
            diff <= diff+1;
         end if;
         if re_i='1' then   -- Read to the FIFO.
            if adjust and addr_re=ADDR_LIMIT then
               addr_re <= (others => '0');
            else
               addr_re <= addr_re+1;
            end if;
            diff <= diff-1;
         end if;
         -- Concurrent read and write, we increment and decrement, so we
         -- let diff unchanged.
         if CONCURRENT and re_i='1' and we_i='1' then
            diff <= diff;
         end if;
      end if;
   end process FIFO_work;

   empty_o <= not avail;
   full_o  <= full;
end architecture RTL; -- Entity: FIFO



