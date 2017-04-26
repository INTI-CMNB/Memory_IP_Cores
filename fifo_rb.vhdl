------------------------------------------------------------------------------
----                                                                      ----
----  FIFO Memory with rollback                                           ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  FIFO memory with empty, full and avalible outputs. This version     ----
----  adds rollback features. Transactions are temporally executed until  ----
----  a commit or rollback is signaled. Then they are consolidated or     ----
----  discarded. Two versions are provided, one with read rollback and    ----
----  the other with write rollback. Their use is complex and needs more  ----
----  testing.                                                            ----
----                                                                      ----
----  To Do:                                                              ----
----   -                                                                  ----
----                                                                      ----
----  Author:                                                             ----
----    - Salvador E. Tropea, salvador en inti gov ar                     ----
----    - Juan Pablo D. Borgna, jpdborgna@yahoo.com.ar                    ----
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
---- Design unit:      FIFO_RRB(RTL) (Entity and architecture)            ----
----                   FIFO_WRB(RTL)                                      ----
---- File name:        fifo_rb.vhdl                                       ----
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

entity FIFO_RRB is
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
end entity FIFO_RRB;

architecture RTL of FIFO_RRB is
   constant ADDR_LIMIT : unsigned(ADDR_W-1 downto 0):=to_unsigned(DEPTH-1,ADDR_W);
   signal addr_rd  : unsigned(ADDR_W-1 downto 0):=(others => '0');
   signal addr_rdo : unsigned(ADDR_W-1 downto 0):=(others => '0'); -- Old read address
   signal addr_wr  : unsigned(ADDR_W-1 downto 0):=(others => '0');
   signal diff     : natural range 0 to DEPTH:=0;
   signal rdiff    : natural range 0 to DEPTH:=0; -- Temporal read difference
begin
   -- Use a dual port Block Ram
   fifo_mem: DualPortBRAM
      generic map(
         ADDR_W => ADDR_W, DATA_W => DATA_W, SIZE => DEPTH)
      port map(
         clk_i => clk_i, we_i => we_i, add1_i => std_logic_vector(addr_wr),
         add2_i => std_logic_vector(addr_rd), di_i => datai_i,
         do2_o => datao_o);

   -- Read side signaling
   avail_o <= '1' when rdiff/=0 else '0';
   used_o  <= to_unsigned(rdiff,ADDR_W+1); -- [0;DEPTH] => +1
   -- Write side signaling
   full_o  <= '1' when diff=DEPTH else '0';

   FIFO_work:
   process (clk_i)
      variable adjust    : boolean:=false;
      variable v_diff    : natural range 0 to DEPTH:=0;
      variable v_rdiff   : natural range 0 to DEPTH:=0;
      variable v_addr_rd : unsigned(ADDR_W-1 downto 0):=(others => '0');
   begin
      if 2**ADDR_W/=DEPTH then
         -- Note: This is needed because XST isn't good enough
         adjust:=true;
      end if;
      if rising_edge(clk_i) then
         if rst_i='1' then
            addr_wr  <= (others => '0');
            addr_rd  <= (others => '0');
            addr_rdo <= (others => '0');
            diff     <= 0;
            rdiff    <= 0;
         else
            -- To allow concurrence we use variables here
            v_diff:=diff;
            v_rdiff:=rdiff;
            v_addr_rd:=addr_rd;
            -- Write to the FIFO.
            if we_i='1' then
               if adjust and addr_wr=ADDR_LIMIT then
                  addr_wr <= (others => '0');
               else
                  addr_wr <= addr_wr+1;
               end if;
               v_diff:=v_diff+1;
               v_rdiff:=v_rdiff+1;
            end if;
            -- Read from the FIFO.
            if re_i='1' then
               if adjust and v_addr_rd=ADDR_LIMIT then
                  v_addr_rd:=(others => '0');
               else
                  v_addr_rd:=v_addr_rd+1;
               end if;
               v_rdiff:=v_rdiff-1;
            end if;
            -- Commit
            if commit_i='1' then
               v_diff:=v_rdiff;
               addr_rdo <= v_addr_rd;
            -- Rollback
            elsif rollback_i='1' then
               v_rdiff:=diff;
               v_addr_rd:=addr_rdo;
            end if;
            diff    <= v_diff;
            rdiff   <= v_rdiff;
            addr_rd <= v_addr_rd;
         end if;
      end if;
   end process FIFO_work;

end architecture RTL; -- Entity: FIFO_RRB

-- Código sin variables
--             -- Write to the FIFO.
--             if we_i='1' then
--                if adjust and addr_wr=ADDR_LIMIT then
--                   addr_wr <= (others => '0');
--                else
--                   addr_wr <= addr_wr+1;
--                end if;
--                diff <= diff+1;
--                rdiff <= rdiff+1;
--             end if;
--             -- Read from the FIFO.
--             if re_i='1' then
--                if adjust and v_addr_rd=ADDR_LIMIT then
--                   addr_rd <= (others => '0');
--                else
--                   addr_rd <= addr_rd+1;
--                end if;
--                rdiff <= rdiff-1;
--             end if;
--             -- Concurrent read and write
--             if re_i='1' and we_i='1' then
--                rdiff <= rdiff;
--             end if;
--             -- Commit
--             if commit_i='1' then
--                if we_i='1' then
--                   -- rdiff is incrementing during this cycle
--                   diff <= rdiff+1;
--                else -- no concurrent write
--                   diff <= rdiff;
--                end if;
--                -- Note: concurrent read is forbiden
--                addr_rdo <= addr_rd;
--             -- Rollback
--             elsif rollback_i='1' then
--                if we_i='1' then
--                   -- rdiff is incrementing during this cycle
--                   rdiff <= diff+1;
--                else -- no concurrent write
--                   rdiff <= diff;
--                end if;
--                -- Note: concurrent read is forbiden
--                addr_rd <= addr_rdo;
--             end if;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library mems;
use mems.Devices.all;

entity FIFO_WRB is
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
end entity FIFO_WRB;

architecture RTL of FIFO_WRB is
   constant ADDR_LIMIT : unsigned(ADDR_W-1 downto 0):=to_unsigned(DEPTH-1,ADDR_W);
   signal addr_rd  : unsigned(ADDR_W-1 downto 0):=(others => '0');
   signal addr_wr  : unsigned(ADDR_W-1 downto 0):=(others => '0');
   signal addr_wro : unsigned(ADDR_W-1 downto 0):=(others => '0'); -- Old write address
   signal diff     : natural range 0 to DEPTH:=0;
   signal wdiff    : natural range 0 to DEPTH:=0; -- Temporal difference
begin
   -- Use a dual port Block Ram
   fifo_mem: DualPortBRAM
      generic map(
         ADDR_W => ADDR_W, DATA_W => DATA_W, SIZE => DEPTH)
      port map(
         clk_i => clk_i, we_i => we_i, add1_i => std_logic_vector(addr_wr),
         add2_i => std_logic_vector(addr_rd), di_i => datai_i,
         do2_o => datao_o);

   -- Read side signaling
   avail_o <= '1' when diff/=0 else '0';
   -- Write side signaling
   full_o  <= '1' when wdiff=DEPTH else '0';
   used_o  <= to_unsigned(wdiff,ADDR_W+1); -- [0;DEPTH] => +1

   FIFO_work:
   process (clk_i)
      variable adjust    : boolean:=false;
      variable v_diff    : natural range 0 to DEPTH:=0;
      variable v_wdiff   : natural range 0 to DEPTH:=0;
      variable v_addr_wr : unsigned(ADDR_W-1 downto 0):=(others => '0');
   begin
      if 2**ADDR_W/=DEPTH then
         -- Note: This is needed because XST isn't good enough
         adjust:=true;
      end if;
      if rising_edge(clk_i) then
         if rst_i='1' then
            addr_wr  <= (others => '0');
            addr_wro <= (others => '0');
            addr_rd  <= (others => '0');
            diff     <= 0;
            wdiff    <= 0;
         else
            -- To allow concurrence we use variables here
            v_diff:=diff;
            v_wdiff:=wdiff;
            v_addr_wr:=addr_wr;
            -- Write to the FIFO.
            if we_i='1' then
               if adjust and addr_wr=ADDR_LIMIT then
                  v_addr_wr:=(others => '0');
               else
                  v_addr_wr:=addr_wr+1;
               end if;
               v_wdiff:=v_wdiff+1;
            end if;
            -- Read from the FIFO.
            if re_i='1' then
               if adjust and addr_rd=ADDR_LIMIT then
                  addr_rd <= (others => '0');
               else
                  addr_rd <= addr_rd+1;
               end if;
               v_diff:=v_diff-1;
               v_wdiff:=v_wdiff-1;
            end if;
            -- Commit
            if commit_i='1' then
               v_diff:=v_wdiff;
               addr_wro <= v_addr_wr;
            -- Rollback
            elsif rollback_i='1' then
               v_wdiff:=v_diff;
               v_addr_wr:=addr_wro;
            end if;
            diff    <= v_diff;
            wdiff   <= v_wdiff;
            addr_wr <= v_addr_wr;
         end if;
      end if;
   end process FIFO_work;

end architecture RTL; -- Entity: FIFO_WRB

-- Código sin variables, más limitado
--             -- Write to the FIFO.
--             if we_i='1' then
--                if adjust and addr_wr=ADDR_LIMIT then
--                   addr_wr <= (others => '0');
--                else
--                   addr_wr <= addr_wr+1;
--                end if;
--                wdiff <= wdiff+1;
--             end if;
--             -- Read from the FIFO.
--             if re_i='1' then
--                if adjust and addr_rd=ADDR_LIMIT then
--                   addr_rd <= (others => '0');
--                else
--                   addr_rd <= addr_rd+1;
--                end if;
--                diff <= diff-1;
--                wdiff <= wdiff-1;
--             end if;
--             -- Concurrent read and write
--             if re_i='1' and we_i='1' then
--                wdiff <= wdiff;
--             end if;
--             -- Commit
--             if commit_i='1' then
--                if re_i='1' then
--                   -- wdiff is decrementing during this cycle
--                   diff <= wdiff-1;
--                else -- no concurrent read
--                   diff <= wdiff;
--                end if;
--                -- Note: concurrent write is forbiden
--                addr_wro <= addr_wr;
--             -- Rollback
--             elsif rollback_i='1' then
--                if re_i='1' then
--                   -- wdiff is decrementing during this cycle
--                   wdiff <= diff-1;
--                else -- no concurrent read
--                   wdiff <= diff;
--                end if;
--                -- Note: concurrent write is forbiden
--                addr_wr <= addr_wro;
--             end if;


