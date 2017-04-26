------------------------------------------------------------------------------
----                                                                      ----
----  Dual FIFO Memory with rollback                                      ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  This is a very special case where the FIFO doesn't support          ----
----  concurrence and two FIFOs shares the same BRAM. It was specifically ----
----  designed for the USB to WISHBONE bridge.                            ----
----                                                                      ----
----  To Do:                                                              ----
----   -                                                                  ----
----                                                                      ----
----  Author:                                                             ----
----    - Salvador E. Tropea, salvador en inti gov ar                     ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Copyright (c) 2008 Salvador E. Tropea <salvador en inti gov ar>      ----
----                                                                      ----
---- Distributed under the GPL v2 or newer license                        ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Design unit:      FIFO_Dual(RTL) (Entity and architecture)           ----
---- File name:        fifo_dual.vhdl                                      ----
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
---- Synthesis tools:  Xilinx Release 9.2.03i - xst J.39                  ----
---- Simulation tools: GHDL [Sokcho edition] (0.2x)                       ----
---- Text editor:      SETEdit 0.5.x                                      ----
----                                                                      ----
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library mems;
use mems.Devices.all;

entity FIFO_Dual is
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
end entity FIFO_Dual;

architecture RTL of FIFO_Dual is
   constant HALF_MEM  : unsigned(ADDR_W downto 0):='1'&to_unsigned(0,ADDR_W);
   signal addr_rd   : unsigned(ADDR_W downto 0):=(others => '0');
   signal addr_wr   : unsigned(ADDR_W downto 0):=(others => '0');
   signal o_size    : unsigned(ADDR_W downto 0):=(others => '0');
   signal datai     : std_logic_vector(DATA_W-1 downto 0);
   signal datao     : std_logic_vector(DATA_W-1 downto 0);
   signal we        : std_logic;
   signal have_od   : std_logic; -- Have output data
   type state_type is (do_get, do_process, do_send);
   signal state     : state_type:=do_get;
   signal state_int : integer;
   -- Debug
   --signal cnt_wr_r  : unsigned(3 downto 0);
   --signal cnt_rd_r  : unsigned(3 downto 0);
begin
   -- Use a dual port Block Ram
   fifo_mem: DualPortBRAM
      generic map(
         ADDR_W => ADDR_W+1, DATA_W => DATA_W, SIZE => 2**(ADDR_W+1))
      port map(
         clk_i => clk_i, we_i => we, add1_i => std_logic_vector(addr_wr),
         add2_i => std_logic_vector(addr_rd), di_i => datai,
         do1_o => open, do2_o => datao);
   i_data_o <= datao;
   o_data_o <= datao;

   do_fifo:
   process (clk_i)
   begin
      if rising_edge(clk_i) then
         if rst_i='1' then
            addr_rd  <= HALF_MEM;
            addr_wr  <= HALF_MEM;
            o_size   <= (others => '0');
            state    <= do_get;
            have_od  <= '0';
            --cnt_wr_r <= (others => '0');
            --cnt_rd_r <= (others => '0');
         else
            case state is
                 when do_get =>
                      if o_commit_i='1' and have_od='1' then
                         state    <= do_process;
                         addr_rd  <= HALF_MEM;
                         addr_wr  <= (others => '0');
                         o_size   <= addr_wr-HALF_MEM;
                         --cnt_wr_r <= cnt_wr_r+1;
                      end if;
                      if o_flush_i='1' then
                         addr_wr <= HALF_MEM;
                         have_od <= '0';
                      end if;
                      if o_we_i='1' then
                         addr_wr <= addr_wr+1;
                         have_od <= '1';
                      end if;
                 when do_process =>
                      if i_ready_i='1' then
                         state   <= do_send;
                         addr_rd <= (others => '0');
                         o_size  <= (others => '0');
                         if addr_wr=0 then
                            -- No data in the IN side, skip do_send
                            state   <= do_get;
                            addr_wr <= HALF_MEM;
                            have_od <= '0';
                         end if;
                      end if;
                      if o_re_i='1' then
                         addr_rd <= addr_rd+1;
                         o_size  <= o_size-1;
                      end if;
                      if i_we_i='1' then
                         addr_wr <= addr_wr+1;
                      end if;
                 when do_send =>
                      if i_commit_i='1' then
                         state    <= do_get;
                         addr_wr  <= HALF_MEM;
                         have_od  <= '0';
                         --cnt_rd_r <= cnt_rd_r+1;
                      end if;
                      if i_flush_i='1' then
                         addr_rd <= (others => '0');
                      end if;
                      if i_re_i='1' then
                         addr_rd <= addr_rd+1;
                      end if;
            end case;
         end if;
      end if;
   end process do_fifo;
   -- Debug
   with state select state_int <=
        0 when do_get,
        1 when do_process,
        2 when do_send,
        256 when others;

   -- The OUT FIFO is ready to receive a new packet
   o_bavail_o <= '1' when state=do_get else '0';
   -- The IN FIFO is ready to send a new packet
   i_bavail_o <= '1' when state=do_send else '0';
   -- During the do_send state this is the size of the IN FIFO
   i_used_o   <= addr_wr;
   -- We have data to process when o_size/=0
   o_avail_o  <= '1' when o_size/=0 else '0';
   -- In FIFO is full if we reach HALF_MEM during process
   i_full_o   <= '1' when state=do_process and addr_wr(ADDR_W)='1' else '0';
   -- BRAM WE signal depends on the state
   we <= o_we_i when state=do_get else
         i_we_i when state=do_process else
         '0';
   -- BRAM data input is from "OUT" side during get and "IN" side otherwise
   datai <= o_data_i when state=do_get else i_data_i;
   --cnt_wr_o <= cnt_wr_r;
   --cnt_rd_o <= cnt_rd_r;
end architecture RTL; -- Entity: FIFO_Dual

