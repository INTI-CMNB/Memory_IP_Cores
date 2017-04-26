------------------------------------------------------------------------------
----                                                                      ----
----  FIFO Memory Testbench                                               ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  Testbench for FIFO.                                                 ----
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
---- Copyright (c) 2005 Juan Pablo D. Borgna <jpdborgna@yahoo.com.ar>     ----
---- Copyright (c) 2006-2008 Salvador E. Tropea <salvador en inti gov ar> ----
---- Copyright (c) 2005-2008 Instituto Nacional de Tecnología Industrial  ----
----                                                                      ----
---- Distributed under the GPL v2 or newer license                        ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Design unit:      FIFO_TB(Bench) (Entity and architecture)           ----
---- File name:        fifo_tb.vhdl                                       ----
---- Note:             None                                               ----
---- Limitations:      None known                                         ----
---- Errors:           None known                                         ----
---- Library:          None                                               ----
---- Dependencies:     IEEE.std_logic_1164                                ----
----                   IEEE.numeric_std                                   ----
----                   mems.devices                                       ----
---- Target FPGA:      None                                               ----
---- Language:         VHDL                                               ----
---- Wishbone:         None                                               ----
---- Synthesis tools:  None                                               ----
---- Simulation tools: GHDL [Sokcho edition] (0.2x)                       ----
---- Text editor:      SETEdit 0.5.x                                      ----
----                                                                      ----
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library mems;
use mems.devices.all;
library utils;
use utils.StdIO.all;

entity FIFO_TB is
end entity FIFO_TB;

architecture Bench of FIFO_TB is
   constant DATA_W     : natural:=8;
   constant ADDR_W     : natural:=2;
   constant DELAY_AVAIL: boolean:=true;
   constant CLKPERIOD  : time:=20 ns;
   constant DONT_CARE  : std_logic_vector(DATA_W-1 downto 0):=(others => '-');

   procedure CheckStatus(signal full : in std_logic; vfull : in std_logic;
                         signal avail : in std_logic; vavail : in std_logic;
                         signal used : in unsigned(ADDR_W downto 0);
                         vused : in natural) is
   begin
      assert full=vfull   report "Bad full status "&std_logic'image(full)&
         " vs "&std_logic'image(vfull)  severity failure;
      assert avail=vavail report "Bad avail status "&std_logic'image(avail)&
         " vs "&std_logic'image(vavail) severity failure;
      assert used=vused   report "Bad used status" severity failure;
   end procedure CheckStatus;

   procedure CheckData(signal data  : in std_logic_vector(DATA_W-1 downto 0);
                       v    : in std_logic_vector(DATA_W-1 downto 0)) is
   begin
      assert v=DONT_CARE or data=v  report "Bad data "&integer'image(to_integer(unsigned(data)))&
         " vs "&integer'image(to_integer(unsigned(v))) severity failure;
   end procedure CheckData;

   procedure Push(signal clock : in std_logic;
                  signal data  : out std_logic_vector(DATA_W-1 downto 0);
                  v    : in std_logic_vector(DATA_W-1 downto 0);
                  signal full : in std_logic; vfull : in std_logic;
                  signal avail : in std_logic; vavail : in std_logic;
                  signal used : in unsigned(ADDR_W downto 0);
                  vused : in natural) is
   begin
      data <= v;
      wait until rising_edge(clock);
      wait for CLKPERIOD/4;
      data <= x"00";
      wait for 1 fs;
      CheckStatus(full,vfull,avail,vavail,used,vused);
   end procedure Push;

   procedure Pop(signal clock : in std_logic;
                 signal data  : in std_logic_vector(DATA_W-1 downto 0);
                 v    : in std_logic_vector(DATA_W-1 downto 0);
                 signal full : in std_logic; vfull : in std_logic;
                 signal avail : in std_logic; vavail : in std_logic;
                 signal used : in unsigned(ADDR_W downto 0);
                 vused : in natural) is
   begin
      wait until rising_edge(clock);
      wait for CLKPERIOD/4;
      CheckData(data,v);
      CheckStatus(full,vfull,avail,vavail,used,vused);
   end procedure Pop;

   signal clock : std_logic;
   signal reset : std_logic;
   signal we    : std_logic;
   signal re    : std_logic;
   signal datai : std_logic_vector(DATA_W-1 downto 0):=(others => '0');
   signal datao : std_logic_vector(DATA_W-1 downto 0):=(others => '0');
   signal full  : std_logic;
   signal empty : std_logic;
   signal avail : std_logic;
   -- Read rollback FIFO
   signal we_rrb    : std_logic:='0';
   signal re_rrb    : std_logic:='0';
   signal datao_rrb : std_logic_vector(DATA_W-1 downto 0);
   signal full_rrb  : std_logic;
   signal avail_rrb : std_logic;
   signal ci_rrb    : std_logic:='0';
   signal rb_rrb    : std_logic:='0';
   signal used_rrb  : unsigned(ADDR_W downto 0);
   -- Write rollback FIFO
   signal we_wrb    : std_logic:='0';
   signal re_wrb    : std_logic:='0';
   signal datao_wrb : std_logic_vector(DATA_W-1 downto 0);
   signal full_wrb  : std_logic;
   signal avail_wrb : std_logic;
   signal ci_wrb    : std_logic:='0';
   signal rb_wrb    : std_logic:='0';
   signal used_wrb  : unsigned(ADDR_W downto 0);
   -- Dual FIFO
   signal o_we      : std_logic:='0'; -- Out Write enable
   signal o_datai   : std_logic_vector(DATA_W-1 downto 0); -- Out Input Data
   signal o_commit  : std_logic:='0'; -- Out Commit writes
   signal o_flush   : std_logic:='0'; -- Out Flush writes
   signal o_bavail  : std_logic; -- Out FIFO can receive new packet
   signal o_re      : std_logic:='0'; -- Read enable
   signal o_datao   : std_logic_vector(DATA_W-1 downto 0); -- Out Output Data
   signal o_avail   : std_logic; -- Out FIFO have data
   signal i_we      : std_logic:='0'; -- In Write enable
   signal i_datai   : std_logic_vector(DATA_W-1 downto 0); -- In Input Data
   signal i_full    : std_logic; -- In FIFO is full
   signal i_ready   : std_logic:='0'; -- In data ready to send
   signal i_re      : std_logic:='0'; -- In Read enable
   signal i_datao   : std_logic_vector(DATA_W-1 downto 0); -- In Output Data
   signal i_bavail  : std_logic; -- In FIFO have data to send
   signal i_commit  : std_logic:='0'; -- In Commit reads
   signal i_flush   : std_logic:='0'; -- In Flush reads
   signal i_used    : unsigned(ADDR_W downto 0); -- Ammount of In data available
   -- Testbench
   signal stop_clock : std_logic:='0';
begin
   clock_gen:
   process
   begin
      clock<='0';
      wait for CLKPERIOD/2;
      clock<='1';
      wait for CLKPERIOD/2;
      if stop_clock='1' then
         wait;
      end if;
   end process clock_gen;

   reset_p:
   process
   begin
      reset<='1';
      wait for 2*CLKPERIOD;
      reset<='0';
      wait;
   end process reset_p;

   fifo1: FIFO
      generic map(
         ADDR_W => ADDR_W, DATA_W => DATA_W, DEPTH => 4, CONCURRENT => true)
      port map(
         clk_i => clock, rst_i=>reset, we_i=>we, re_i=>re, datai_i=>datai,
         datao_o=>datao, full_o=>full, avail_o=>avail, empty_o=>empty);

   fifo2: FIFO_RRB
      generic map(
         ADDR_W => ADDR_W, DATA_W => DATA_W, DEPTH => 4)
      port map(
         clk_i => clock, rst_i => reset, we_i => we_rrb, re_i => re_rrb,
         datai_i => datai, datao_o => datao_rrb, full_o => full_rrb,
         avail_o => avail_rrb, commit_i => ci_rrb, rollback_i => rb_rrb,
         used_o => used_rrb);

   fifo3: FIFO_WRB
      generic map(
         ADDR_W => ADDR_W, DATA_W => DATA_W, DEPTH => 4)
      port map(
         clk_i => clock, rst_i => reset, we_i => we_wrb, re_i => re_wrb,
         datai_i => datai, datao_o => datao_wrb, full_o => full_wrb,
         avail_o => avail_wrb, commit_i => ci_wrb, rollback_i => rb_wrb,
         used_o => used_wrb);

   dfifo: FIFO_Dual
      generic map(
         ADDR_W => ADDR_W, DATA_W => DATA_W)
      port map(
         clk_i => clock, rst_i => reset, o_we_i => o_we, o_data_i => o_datai,
         o_commit_i => o_commit, o_flush_i => o_flush, o_bavail_o => o_bavail,
         o_re_i => o_re, o_data_o => o_datao, o_avail_o => o_avail,
         i_we_i => i_we, i_data_i => i_datai, i_full_o => i_full,
         i_ready_i => i_ready, i_re_i => i_re, i_data_o => i_datao,
         i_bavail_o => i_bavail, i_commit_i => i_commit, i_flush_i => i_flush,
         i_used_o => i_used);

   do_bench:
   process
   begin
      outwrite("* Testing FIFOs");
      we<='0';
      re<='0';
      wait until reset='0';

      outwrite("* Testing simple FIFO");
      --check initial condition
      wait for 1 fs;
      assert empty='1' report "Bad initial empty status" severity failure;
      assert full='0'  report "Bad initial full status" severity failure;
      assert avail='0' report "Bad initial avail status" severity failure;

      wait until falling_edge(clock);
      we<='1';

      datai<="11110001";
      wait until rising_edge(clock);--graba 1
      outwrite("Push 1");
      --after one push conditions change
      wait for 1 fs;
      assert empty='0' report "Bad empty status" severity failure;
      assert full='0'  report "Bad full status" severity failure;
      assert avail='0' report "Bad avail status" severity failure;

      datai<="11110010";
      wait until rising_edge(clock);--graba 2
      outwrite("Push 2");
      --new conditions
      wait for 1 fs;
      assert empty='0' report "Bad empty status" severity failure;
      assert full='0'  report "Bad full status" severity failure;
      assert avail='1' report "Bad avail status" severity failure;

      re <= '1';
      datai <= "11110011";
      wait until rising_edge(clock);--graba 3
      outwrite("Push 3 + Pop 1");
      --new conditions
      wait for 1 fs;
      assert datao="11110001" report "No se leyo lo que debia" severity failure;
      assert empty='0' report "Bad empty status" severity failure;
      assert full='0'  report "Bad full status" severity failure;
      assert avail='1' report "Bad avail status" severity failure;

      --keep writing
      re<='0';
      we<='1';
      datai<="11110100";
      wait until rising_edge(clock);--graba 4
      outwrite("Push 4");
      --new conditions
      assert empty='0' report "Bad empty status" severity failure;
      assert full='0'  report "Bad full status" severity failure;
      assert avail='1' report "Bad avail status" severity failure;


      datai<="11110101";
      wait until rising_edge(clock);--graba 5
      outwrite("Push 5");
      --fifo full
      wait for 1 fs;
      assert empty='0' report "Bad empty status" severity failure;
      assert full='1'  report "Bad full status" severity failure;
      assert avail='1' report "Bad avail status" severity failure;

      we<='0';
      re<='1';
      wait until rising_edge(clock);--lee 2
      wait for 1 fs;
      outwrite("Pop 2");
      assert datao="11110010" report "No se leyo lo que debia" severity failure;
      --new conditions
      assert empty='0' report "Bad empty status" severity failure;
      assert full='0'  report "Bad full status" severity failure;
      assert avail='1' report "Bad avail status" severity failure;

      wait until rising_edge(clock);--lee 3
      wait for 1 fs;
      outwrite("Pop 3");
      assert datao="11110011" report "No se leyo lo que debia" severity failure;
      --new conditions
      assert empty='0' report "Bad empty status" severity failure;
      assert full='0'  report "Bad full status" severity failure;
      assert avail='1' report "Bad avail status" severity failure;

      wait until rising_edge(clock);--lee 4
      wait for 1 fs;
      outwrite("Pop 4");
      assert datao="11110100" report "No se leyo lo que debia" severity failure;
      --new conditions
      assert empty='0' report "Bad empty status" severity failure;
      assert full='0'  report "Bad full status" severity failure;
      assert avail='1' report "Bad avail status" severity failure;

      wait until rising_edge(clock);--lee 5
      wait for 1 fs;
      outwrite("Pop 5");
      assert datao="11110101" report "No se leyo lo que debia" severity failure;
      --new conditions
      assert empty='1' report "Bad empty status" severity failure;
      assert full='0'  report "Bad full status" severity failure;
      assert avail='0' report "Bad avail status" severity failure;

      re<='0';

      wait for 2*CLKPERIOD;

      -------------------------------------
      -- Test for the Read Rollback FIFO --
      -------------------------------------
      outwrite("* Testing Read Rollback FIFO");
      assert full_rrb='0'  report "Bad initial full status" severity failure;
      assert avail_rrb='0' report "Bad initial avail status" severity failure;
      assert used_rrb=0    report "Bad initial used status" severity failure;

      we_rrb <= '1';
      outwrite("Push 1: 0xA5");
      Push(clock,datai,x"A5",full_rrb,'0',avail_rrb,'1',used_rrb,1);
      outwrite("Push 2: 0x5A");
      Push(clock,datai,x"5A",full_rrb,'0',avail_rrb,'1',used_rrb,2);
      outwrite("Push 3: 0x11");
      Push(clock,datai,x"11",full_rrb,'0',avail_rrb,'1',used_rrb,3);
      outwrite("Push 4: 0x22");
      Push(clock,datai,x"22",full_rrb,'1',avail_rrb,'1',used_rrb,4);
      we_rrb <= '0';
      re_rrb <= '1';
      outwrite("Pop 1: 0xA5");
      Pop(clock,datao_rrb,x"A5",full_rrb,'1',avail_rrb,'1',used_rrb,3);
      outwrite("Pop 2: 0x5A");
      Pop(clock,datao_rrb,x"5A",full_rrb,'1',avail_rrb,'1',used_rrb,2);
      ci_rrb <= '1';
      re_rrb <= '0';
      outwrite("Commiting");
      Pop(clock,datao_rrb,DONT_CARE,full_rrb,'0',avail_rrb,'1',used_rrb,2);
      ci_rrb <= '0';
      re_rrb <= '1';
      outwrite("Pop 3: 0x11");
      Pop(clock,datao_rrb,x"11",full_rrb,'0',avail_rrb,'1',used_rrb,1);
      outwrite("Pop 4: 0x22");
      Pop(clock,datao_rrb,x"22",full_rrb,'0',avail_rrb,'0',used_rrb,0);
      rb_rrb <= '1';
      re_rrb <= '0';
      outwrite("Rollback");
      Pop(clock,datao_rrb,DONT_CARE,full_rrb,'0',avail_rrb,'1',used_rrb,2);
      rb_rrb <= '0';
      re_rrb <= '1';
      outwrite("Pop 3: 0x11");
      Pop(clock,datao_rrb,x"11",full_rrb,'0',avail_rrb,'1',used_rrb,1);
      outwrite("Pop 4: 0x22");
      Pop(clock,datao_rrb,x"22",full_rrb,'0',avail_rrb,'0',used_rrb,0);
      ci_rrb <= '1';
      re_rrb <= '0';
      outwrite("Commiting");
      Pop(clock,datao_rrb,DONT_CARE,full_rrb,'0',avail_rrb,'0',used_rrb,0);
      ci_rrb <= '0';
      we_rrb <= '1';
      outwrite("Push 1: 0xA5");
      Push(clock,datai,x"A5",full_rrb,'0',avail_rrb,'1',used_rrb,1);
      outwrite("Push 2: 0x5A");
      Push(clock,datai,x"5A",full_rrb,'0',avail_rrb,'1',used_rrb,2);
      we_rrb <= '0';
      re_rrb <= '1';
      outwrite("Pop 1: 0xA5");
      Pop(clock,datao_rrb,x"A5",full_rrb,'0',avail_rrb,'1',used_rrb,1);
      we_rrb <= '1';
      re_rrb <= '0';
      outwrite("Push 3: 0xBB");
      Push(clock,datai,x"BB",full_rrb,'0',avail_rrb,'1',used_rrb,2);
      rb_rrb <= '1';
      we_rrb <= '0';
      outwrite("Rollback");
      Pop(clock,datao_rrb,DONT_CARE,full_rrb,'0',avail_rrb,'1',used_rrb,3);
      rb_rrb <= '0';
      re_rrb <= '1';
      outwrite("Pop 1: 0xA5");
      Pop(clock,datao_rrb,x"A5",full_rrb,'0',avail_rrb,'1',used_rrb,2);
      outwrite("Pop 2: 0x5A");
      Pop(clock,datao_rrb,x"5A",full_rrb,'0',avail_rrb,'1',used_rrb,1);
      outwrite("Pop 3: 0xBB");
      Pop(clock,datao_rrb,x"BB",full_rrb,'0',avail_rrb,'0',used_rrb,0);
      ci_rrb <= '1';
      re_rrb <= '0';
      outwrite("Commiting");
      Pop(clock,datao_rrb,DONT_CARE,full_rrb,'0',avail_rrb,'0',used_rrb,0);

      -------------------------------------
      -- Test for the Read Rollback FIFO --
      -------------------------------------
      outwrite("* Testing Write Rollback FIFO");
      assert full_wrb='0'  report "Bad initial full status" severity failure;
      assert avail_wrb='0' report "Bad initial avail status" severity failure;
      assert used_wrb=0    report "Bad initial used status" severity failure;

      we_wrb <= '1';
      outwrite("Push 1: 0xA5");
      Push(clock,datai,x"A5",full_wrb,'0',avail_wrb,'0',used_wrb,1);
      outwrite("Push 2: 0x5A");
      Push(clock,datai,x"5A",full_wrb,'0',avail_wrb,'0',used_wrb,2);
      outwrite("Push 3: 0x11");
      Push(clock,datai,x"11",full_wrb,'0',avail_wrb,'0',used_wrb,3);
      outwrite("Push 4: 0x22");
      Push(clock,datai,x"22",full_wrb,'1',avail_wrb,'0',used_wrb,4);
      ci_wrb <= '1';
      we_wrb <= '0';
      outwrite("Commiting");
      Push(clock,datai,DONT_CARE,full_wrb,'1',avail_wrb,'1',used_wrb,4);
      ci_wrb <= '0';
      re_wrb <= '1';
      outwrite("Pop 1: 0xA5");
      Pop(clock,datao_wrb,x"A5",full_wrb,'0',avail_wrb,'1',used_wrb,3);
      -- Concurrent test
      we_wrb <= '1';
      outwrite("Pop 2: 0x5A + Push 3: 0x33");
      datai <= x"33";
      wait until rising_edge(clock);
      wait for CLKPERIOD/4;
      datai <= x"00";
      wait for 1 fs;
      CheckData(datao_wrb,x"5A");
      CheckStatus(full_wrb,'0',avail_wrb,'1',used_wrb,3);
      --
      re_wrb <= '0';
      outwrite("Push 4: 0x44");
      Push(clock,datai,x"44",full_wrb,'1',avail_wrb,'1',used_wrb,4);
      rb_wrb <= '1';
      we_wrb <= '0';
      outwrite("Rollback");
      Push(clock,datai,DONT_CARE,full_wrb,'0',avail_wrb,'1',used_wrb,2);
      rb_wrb <= '0';
      we_wrb <= '1';
      outwrite("Push 3: 0x55");
      Push(clock,datai,x"55",full_wrb,'0',avail_wrb,'1',used_wrb,3);
      re_wrb <= '1';
      we_wrb <= '0';
      outwrite("Pop 1: 0x11");
      Pop(clock,datao_wrb,x"11",full_wrb,'0',avail_wrb,'1',used_wrb,2);
      outwrite("Pop 2: 0x22");
      Pop(clock,datao_wrb,x"22",full_wrb,'0',avail_wrb,'0',used_wrb,1);
      re_wrb <= '0';
      we_wrb <= '1';
      outwrite("Push 4: 0x66");
      Push(clock,datai,x"66",full_wrb,'0',avail_wrb,'0',used_wrb,2);
      ci_wrb <= '1';
      we_wrb <= '0';
      outwrite("Commiting");
      Push(clock,datai,DONT_CARE,full_wrb,'0',avail_wrb,'1',used_wrb,2);
      re_wrb <= '1';
      ci_wrb <= '0';
      outwrite("Pop 1: 0x55");
      Pop(clock,datao_wrb,x"55",full_wrb,'0',avail_wrb,'1',used_wrb,1);
      outwrite("Pop 2: 0x66");
      Pop(clock,datao_wrb,x"66",full_wrb,'0',avail_wrb,'0',used_wrb,0);
      re_wrb <= '0';

      ---------------------------------
      -- Test for the Read Dual FIFO --
      ---------------------------------
      outwrite("* Testing Dual FIFO");
      assert o_bavail='1'  report "Bad initial o_bavail" severity failure;
      assert i_bavail='0'  report "Bad initial i_bavail" severity failure;
      assert o_avail='0'   report "Bad initial o_avail"  severity failure;
      assert i_full='0'    report "Bad initial i_full"   severity failure;

      o_we <= '1';
      outwrite("OUT Push 1: 0x55");
      o_datai <= x"55";
      wait until rising_edge(clock);
      outwrite("OUT Push 2: 0xAA");
      o_datai <= x"AA";
      wait until rising_edge(clock);
      outwrite("OUT Push 3: 0xCC");
      o_datai <= x"CC";
      wait until rising_edge(clock);
      outwrite("OUT Push 4: 0xDD");
      o_datai <= x"DD";
      wait until rising_edge(clock);
      wait for 1 fs;
      o_we <= '0';
      o_commit <= '1';
      outwrite("Consolidating");
      assert o_avail='0'   report "Bad o_avail"  severity failure;
      wait until rising_edge(clock);
      o_commit <= '0';
      wait for 1 fs;
      assert o_avail='1'   report "Bad o_avail"  severity failure;
      o_re <= '1';
      outwrite("OUT Pop 1: 0x55");
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"55" report "Bad value" severity failure;
      outwrite("OUT Pop 2: 0xAA + IN Push 1 0x11");
      i_we <= '1';
      i_datai <= x"11";
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"AA" report "Bad value" severity failure;
      outwrite("OUT Pop 3: 0xCC + IN Push 2 0x22");
      i_datai <= x"22";
      wait until rising_edge(clock);
      i_we <= '0';
      wait for 1 fs;
      assert o_datao=x"CC" report "Bad value" severity failure;
      outwrite("OUT Pop 4: 0xDD");
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"DD" report "Bad value" severity failure;
      o_re <= '0';
      outwrite("Consolidating");
      assert i_bavail='0' report "Bad i_bavail" severity failure;
      i_ready <= '1';
      wait until rising_edge(clock);
      i_ready <= '0';
      wait for 1 fs;
      assert i_bavail='1' report "Bad i_bavail" severity failure;
      assert i_used=2     report "Bad i_used" severity failure;
      i_re <= '1';
      outwrite("IN Pop 1: 0x11");
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"11" report "Bad value" severity failure;
      outwrite("IN Pop 2: 0x22");
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"22" report "Bad value" severity failure;
      i_re <= '0';
      outwrite("Consolidating");
      i_commit <= '1';
      wait until rising_edge(clock);
      i_commit <= '0';
      wait for 1 fs;
      assert i_bavail='0' report "Bad i_bavail" severity failure;
      assert o_bavail='1' report "Bad o_bavail" severity failure;
      outwrite("Full cycle ok!");

      -- With retries
      o_we <= '1';
      outwrite("OUT Push 1: 0x44");
      o_datai <= x"44";
      wait until rising_edge(clock);
      outwrite("OUT Push 2: 0x66");
      o_datai <= x"66";
      wait until rising_edge(clock);
      o_we <= '0';
      outwrite("Flushing");
      o_flush <= '1';
      wait until rising_edge(clock);
      o_flush <= '0';
      o_we <= '1';
      outwrite("OUT Push 1: 0x55");
      o_datai <= x"55";
      wait until rising_edge(clock);
      outwrite("OUT Push 2: 0xAA");
      o_datai <= x"AA";
      wait until rising_edge(clock);
      outwrite("OUT Push 3: 0xCC");
      o_datai <= x"CC";
      wait until rising_edge(clock);
      outwrite("OUT Push 4: 0xDD");
      o_datai <= x"DD";
      wait until rising_edge(clock);
      wait for 1 fs;
      o_we <= '0';
      o_commit <= '1';
      outwrite("Consolidating");
      assert o_avail='0'   report "Bad o_avail"  severity failure;
      wait until rising_edge(clock);
      o_commit <= '0';
      wait for 1 fs;
      assert o_avail='1'   report "Bad o_avail"  severity failure;
      o_re <= '1';
      outwrite("OUT Pop 1: 0x55");
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"55" report "Bad value" severity failure;
      outwrite("OUT Pop 2: 0xAA + IN Push 1 0x11");
      i_we <= '1';
      i_datai <= x"11";
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"AA" report "Bad value" severity failure;
      outwrite("OUT Pop 3: 0xCC + IN Push 2 0x22");
      i_datai <= x"22";
      wait until rising_edge(clock);
      i_we <= '0';
      wait for 1 fs;
      assert o_datao=x"CC" report "Bad value" severity failure;
      outwrite("OUT Pop 4: 0xDD");
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"DD" report "Bad value" severity failure;
      o_re <= '0';
      outwrite("Consolidating");
      assert i_bavail='0' report "Bad i_bavail" severity failure;
      i_ready <= '1';
      wait until rising_edge(clock);
      i_ready <= '0';
      wait for 1 fs;
      assert i_bavail='1' report "Bad i_bavail" severity failure;
      assert i_used=2     report "Bad i_used" severity failure;
      i_re <= '1';
      outwrite("IN Pop 1: 0x11");
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"11" report "Bad value" severity failure;
      outwrite("IN Pop 2: 0x22");
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"22" report "Bad value" severity failure;
      i_re <= '0';
      outwrite("Flushing");
      i_flush <= '1';
      wait until rising_edge(clock);
      i_flush <= '0';
      wait for 1 fs;
      assert i_bavail='1' report "Bad i_bavail" severity failure;
      assert i_used=2     report "Bad i_used" severity failure;
      i_re <= '1';
      outwrite("IN Pop 1: 0x11");
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"11" report "Bad value" severity failure;
      outwrite("IN Pop 2: 0x22");
      wait until rising_edge(clock);
      wait for 1 fs;
      assert o_datao=x"22" report "Bad value" severity failure;
      outwrite("Consolidating");
      i_commit <= '1';
      wait until rising_edge(clock);
      wait for 1 fs;
      assert i_bavail='0' report "Bad i_bavail" severity failure;
      assert o_bavail='1' report "Bad o_bavail" severity failure;
      outwrite("Full cycle ok!");

      outwrite("* End of simulation");
      stop_clock <= '1';
      wait;

   end process do_bench;

end architecture Bench; -- Entity: FIFO_TB
