------------------------------------------------------------------------------
----                                                                      ----
----  Intel HEX format file loader                                        ----
----                                                                      ----
----  This file is part FPGA Libre project http://fpgalibre.sf.net/       ----
----                                                                      ----
----  Description:                                                        ----
----  This package contains routines used to load 2D arrays contents from ----
----  an Intel hexadecimal file. The package also includes routines       ----
----  needed to manipulate 2D arrays and a data type for this.            ----
----                                                                      ----
----  To Do:                                                              ----
----  -                                                                   ----
----                                                                      ----
----  Author:                                                             ----
----    - Salvador E. Tropea, salvador en inti gov ar                     ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Copyright (c) 2004-2006 Salvador E. Tropea <salvador en inti gov ar> ----
---- Copyright (c) 2004-2006 Instituto Nacional de Tecnología Industrial  ----
----                                                                      ----
---- Distributed under the GPL v2 or newer license                        ----
----                                                                      ----
----   Portions of this code were "inspired" on a file without copyright  ----
---- and with the following notice (LPM implementation):                  ----
----   "This VHDL file was developed by Altera Corporation.  It may be    ----
---- freely copied and/or distributed at no cost.  Any persons using this ----
---- file for any purpose do so at their own risk, and are responsible for----
---- the results of such use.  Altera Corporation does not guarantee that ----
---- this file is complete, correct, or fit for any particular purpose.   ----
---- NO WARRANTY OF ANY KIND IS EXPRESSED OR IMPLIED.  This notice must   ----
---- accompany any copy of this file."                                    ----
----                                                                      ----
------------------------------------------------------------------------------
----                                                                      ----
---- Design unit:      HexLoader (Package)                                ----
---- File name:        hex_loader_pkg.vhdl                                ----
---- Note:             None                                               ----
---- Limitations:      None known                                         ----
---- Errors:           None known                                         ----
---- Library:          mems                                               ----
---- Dependencies:     IEEE.std_logic_1164                                ----
----                   IEEE.numeric_std                                   ----
----                   std.textio                                         ----
---- Target FPGA:      None                                               ----
---- Language:         VHDL                                               ----
---- Wishbone:         N/A                                                ----
---- Synthesis tools:  None                                               ----
---- Simulation tools: GHDL [Sokcho edition] (0.2x)                       ----
---- Text editor:      SETEdit 0.5.x                                      ----
----                                                                      ----
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library std;
use std.textio.all;

package HexLoader is
  -- *** 2D array manipulation ***
  -- 2D array
  type std_logic_2d is array (natural range <>, natural range <>) of std_logic;

  -- Initialize a 2D array to 0.
  procedure clear_2d(dest: out std_logic_2d);

  -- Transfer an element from a 2D array to a vector.
  procedure set_2d_element(dest: out std_logic_2d; ind: in integer;
                           from: in std_logic_vector);
                           
  -- Transfer an element from a vector to a 2D array.
  procedure get_2d_element(dest: out std_logic_vector; from: in std_logic_2d;
                           ind: in integer);
                           
  -- *** Loader ***
  -- This function contains the code to read a .hex file
  impure function read_hex_file(cells: in integer; w: in integer;
                                filen: in string; inc_bytes: in boolean;
                                little_endian: in boolean)
         return std_logic_2d;
end HexLoader;

package body HexLoader is

  procedure clear_2d(dest: out std_logic_2d) is
     variable i1, i2: integer;
     variable from1, from2: integer;
  begin
     from1:=dest'length(1)-1;
     from2:=dest'length(2)-1;
     for i1 in from1 downto 0 loop
         for i2 in from2 downto 0 loop
             dest(i1,i2):='0';
         end loop;
     end loop;
  end clear_2d;

  procedure set_2d_element(dest: out std_logic_2d; ind: in integer;
                           from: in std_logic_vector) is
     variable tind : integer;
     variable fromf: integer;
  begin
     assert dest'length(2)=from'length
        report "set_2d_element: array sizes doesn't match" severity error;
     fromf:=dest'length(2)-1;
     for tind in fromf downto 0 loop
         dest(ind,tind):=from(tind);
     end loop;
  end set_2d_element;

  procedure get_2d_element(dest: out std_logic_vector; from: in std_logic_2d;
                           ind: in integer) is
     variable tind : integer;
     variable fromv: integer;
  begin
     assert from'length(2)=dest'length
        report "get_2d_element: array sizes doesn't match" severity error;
     fromv:=from'length(2)-1;
     for tind in fromv downto 0 loop
         dest(tind):=from(ind,tind);
     end loop;
  end get_2d_element;

  function hex_str_to_int(str : string) return integer is
     variable len    : integer:=str'length;
     variable ivalue : integer:=0;
     variable digit  : integer;
  begin
     for i in len downto 1 loop
         case str(i) is
              when '0' =>
                   digit:=0;
              when '1' =>
                   digit:=1;
              when '2' =>
                   digit:=2;
              when '3' =>
                   digit:=3;
              when '4' =>
                   digit:=4;
              when '5' =>
                   digit:=5;
              when '6' =>
                   digit:=6;
              when '7' =>
                   digit:=7;
              when '8' =>
                   digit:=8;
              when '9' =>
                   digit:=9;
              when 'A' =>
                   digit:=10;
              when 'a' =>
                   digit:=10;
              when 'B' =>
                   digit:=11;
              when 'b' =>
                   digit:=11;
              when 'C' =>
                   digit:=12;
              when 'c' =>
                   digit:=12;
              when 'D' =>
                   digit:=13;
              when 'd' =>
                   digit:=13;
              when 'E' =>
                   digit:=14;
              when 'e' =>
                   digit:=14;
              when 'F' =>
                   digit:=15;
              when 'f' =>
                   digit:=15;
              when others =>
                   report "Illegal character "& str(i) &
                      "in Intel Hex File! " severity failure;
         end case;
         ivalue:=ivalue*16+digit;
     end loop;
     return ivalue;
  end;


  procedure read_value(buf: inout line; lineno: in integer;
                       check_sum_vec: inout unsigned(7 downto 0);
                       ival: inout integer) is
     variable booval : boolean;
     variable a_val  : string(2 downto 1);
  begin
     read(l=>buf,value=>a_val,good=>booval);
     assert booval report "[line "& integer'image(lineno) &
        "]: unexpected end of file!" severity failure;
     ival:=hex_str_to_int(a_val);
     check_sum_vec:=check_sum_vec+to_unsigned(ival,8);
  end read_value;


  impure function  read_hex_file(cells: in integer; w: in integer;
                                 filen: in string; inc_bytes: in boolean;
                                 little_endian: in boolean)
      return std_logic_2d is
      file mem_data_file : text;
      variable mem_data  : std_logic_2d(cells-1 downto 0, w-1 downto 0);
      variable buf       : line;
      variable booval    : boolean;
      variable i,j,bytes,n,m,
               lineno    : integer:=0;
      variable checksum  : string(2 downto 1);
      variable eat_one   : string(1 downto 1);
      variable ibase     : integer:=0;
      variable tbytes    : integer:=0;
      variable istartadd : integer:=0;
      variable istaddrh  : integer:=0;
      variable irec_type : integer:=0;
      variable idatain   : integer:=0;
      variable inbase    : integer:=0;
      variable iaux      : integer:=0;
      variable check_sum_vec,
               check_sum_vec_tmp: unsigned(7 downto 0);
      variable mem_data_word    : std_logic_vector(w-1 downto 0);
      variable status           : file_open_status;
      variable from             : integer;
  begin
     file_open(status,mem_data_file,filen,read_mode);
     assert status=open_ok report "Can't open "& filen severity failure;

     bytes:=w/8;
     if ((w mod 8)/=0) then
        bytes:=bytes+1;
     end if;

     while not endfile(mem_data_file) loop
        -- Get a new line from the .hex file
        readline(mem_data_file,buf);
        lineno:=lineno+1;
        check_sum_vec:=(others => '0');
        -- Must start with ':'
        if (buf(buf'low)=':') then
           -- Skip the :
           read(buf,eat_one);
           -- Byte count: The count of the character pairs in the data field
           -- (2 bytes)
           read_value(buf,lineno,check_sum_vec,tbytes);
           -- Address: The 2-byte address at which the data field is to be
           -- loaded into memory (4 bytes).
           read_value(buf,lineno,check_sum_vec,iaux);
           istartadd:=256*iaux;
           read_value(buf,lineno,check_sum_vec,iaux);
           istartadd:=istartadd+iaux+istaddrh;
           if inc_bytes then
              -- PIC files uses address as bytes, not words.
              istartadd:=istartadd/bytes;
           end if;
           -- Type (2 bytes)
           read_value(buf,lineno,check_sum_vec,irec_type);
        else
           report "[line "& integer'image(lineno) & "]: missing ':'"
              severity failure;
        end if;
        case irec_type is
             when 0 =>     -- data record
                  i:=0;
                  -- bytes=no. of bytes per cam entry.
                  while (i<tbytes) loop
                     mem_data_word:=(others => '0');
                     if little_endian then
                        m:=7;
                        n:=0;
                        if bytes=1 then
                           m:=w-1;
                        end if;
                     else
                        n:=(bytes-1)*8;
                        m:=w-1;
                     end if;
                     for j in 1 to bytes loop
                         -- read in data a byte (2 hex chars) at a time.
                         read_value(buf,lineno,check_sum_vec,idatain);
                         mem_data_word(m downto n):=std_logic_vector(to_unsigned(idatain,m-n+1));
                         if little_endian then
                            m:=m+8;
                            n:=n+8;
                            if m>w-1 then
                               m:=w-1;
                            end if;
                         else
                            m:=n-1;
                            n:=n-8;
                         end if;
                     end loop;
                     i:=i+bytes;
        
                     from:=mem_data'length(2)-1;
                     for tind in from downto 0 loop
                         mem_data(ibase+istartadd,tind):=mem_data_word(tind);
                     end loop;
        
                     istartadd:=istartadd+1;
                     --report "Address " & integer'image(istartadd) severity note;
                  end loop;

             when 1 =>
                  --report "End of HEX file" severity note;
                  exit;

             when 2 =>
                  ibase:=0;
                  assert tbytes=2 report "[line "& integer'image(lineno) &
                     "]: illegal intel hex format for record type 02!"
                     severity failure;
                  for i in 0 to (tbytes-1) loop
                      read_value(buf,lineno,check_sum_vec,inbase);
                      ibase:=ibase*256+inbase;
                  end loop;
                  ibase:=ibase*16;

             when 4 =>
                  read_value(buf,lineno,check_sum_vec,iaux);
                  istaddrh:=256*65536*iaux;
                  read_value(buf,lineno,check_sum_vec,iaux);
                  istaddrh:=istartadd+65536*iaux;

             when others =>
                  report "[line "& integer'image(lineno) &
                         "]: illegal record type in intel hex file! (" &
                         integer'image(irec_type) & ")"
                     severity failure;
        end case;
        -- Checksum: The least significant byte of the two's complement sum
        -- of the values represented by all the pairs of characters in the
        -- record except the start code and checksum (2 bytes).
        booval:=true;
        read(l=>buf,value=>checksum,good=>booval);
        assert booval
           report "[line "& integer'image(lineno) & "]: checksum is missing!"
           severity failure;
        check_sum_vec:=(not(check_sum_vec))+1;
        check_sum_vec_tmp:=to_unsigned(hex_str_to_int(checksum),8);
        assert check_sum_vec=check_sum_vec_tmp
           report "[line "& integer'image(lineno) & "]: incorrect checksum!"
           severity failure;
     end loop;
     file_close(mem_data_file);
     return mem_data;
  end read_hex_file;

end HexLoader;
