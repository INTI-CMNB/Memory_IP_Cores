OBJDIR=Work
VERSION=1.3.0
WORK=mems
PKG=$(WORK)-$(VERSION)
GHDL=ghdl
GHDL_FLAGS=-P../wb_handler/Work/ -P../wb_counter/Work -P../c_vhdl/c-obj/ \
	-P../utils/Work --work=$(WORK) --workdir=$(OBJDIR)
GTKWAVE=gtkwave
WBGEN=wishbone.pl
MEMS_TBEXE=mems_tb
FIFO_TBEXE=fifo_tb
ROML_TBEXE=rom_loader_tb

vpath %.o $(OBJDIR)

all: $(OBJDIR) $(OBJDIR)/$(FIFO_TBEXE) $(OBJDIR)/$(ROML_TBEXE) $(OBJDIR)/jt.hex \
	$(OBJDIR)/rom_prog_tb mems.h

$(OBJDIR)/%.o: %.vhdl
	$(GHDL) -a $(GHDL_FLAGS) $<
#	bakalint.pl -i $< -r $(OBJDIR)/replace.txt #-d $(OBJDIR)/$@

$(OBJDIR)/%.o: testbench/%.vhdl
	$(GHDL) -a $(GHDL_FLAGS) $<

$(OBJDIR):
	mkdir $(OBJDIR)

clean:
	-rm -r $(OBJDIR)

$(OBJDIR)/mems.o: mems.vhdl $(OBJDIR)/mems_pkg.vhdl
$(OBJDIR)/mems_tb.o: testbench/mems_tb.vhdl mems.vhdl $(OBJDIR)/mems_pkg.vhdl
$(OBJDIR)/fifo.o: fifo.vhdl $(OBJDIR)/mems_pkg.vhdl
$(OBJDIR)/fifo_rb.o: fifo_rb.vhdl $(OBJDIR)/mems_pkg.vhdl
$(OBJDIR)/fifo_dual.o: fifo_dual.vhdl $(OBJDIR)/mems_pkg.vhdl
$(OBJDIR)/fifo_tb.o: testbench/fifo_tb.vhdl mems.vhdl fifo.vhdl $(OBJDIR)/mems_pkg.vhdl
$(OBJDIR)/rom_loader.o: rom_loader.vhdl hex_loader_pkg.vhdl $(OBJDIR)/mems_pkg.vhdl
$(OBJDIR)/rom_loader_tb.o: testbench/rom_loader_tb.vhdl hex_loader_pkg.vhdl $(OBJDIR)/mems_pkg.vhdl
$(OBJDIR)/rom_prog.o: rom_prog.vhdl $(OBJDIR)/mems_pkg.vhdl
$(OBJDIR)/rom_prog_tb.o: testbench/rom_prog_tb.vhdl $(OBJDIR)/rom_prog.o

$(OBJDIR)/mems_pkg.o: $(OBJDIR)/mems_pkg.vhdl
	ghdl -a $(GHDL_FLAGS) $<

$(OBJDIR)/mems_pkg.vhdl: mems_pkg.vhdl mems.vhdl fifo.vhdl rom_loader.vhdl fifo_rb.vhdl \
	fifo_dual.vhdl rom_prog.vhdl
	vhdlspp.pl $< $@

$(OBJDIR)/$(MEMS_TBEXE): $(OBJDIR)/mems_pkg.o $(OBJDIR)/mems.o $(OBJDIR)/mems_tb.o
	$(GHDL) -e $(GHDL_FLAGS) -o $@ $(@F)

$(OBJDIR)/$(FIFO_TBEXE): $(OBJDIR)/mems_pkg.o $(OBJDIR)/mems.o $(OBJDIR)/fifo.o \
	$(OBJDIR)/fifo_rb.o $(OBJDIR)/fifo_dual.o $(OBJDIR)/fifo_tb.o
	$(GHDL) -e $(GHDL_FLAGS) -o $@ $(@F)

$(OBJDIR)/$(ROML_TBEXE): $(OBJDIR)/hex_loader_pkg.o $(OBJDIR)/rom_loader.o $(OBJDIR)/rom_loader_tb.o
	$(GHDL) -e $(GHDL_FLAGS) -o $@ rom_test

$(OBJDIR)/rom_prog_tb: $(OBJDIR)/rom_prog_tb.o
	$(GHDL) -e $(GHDL_FLAGS) -o $@ $(@F)

$(OBJDIR)/jt.hex: testbench/jt.hex
	cp testbench/jt.hex $(OBJDIR)/jt.hex

mems.h: mems_pkg.vhdl
	xtracth.pl $<

test_mems: $(OBJDIR)/$(MEMS_TBEXE)
	$< --vcd=$<.vcd

test_fifo: $(OBJDIR)/$(FIFO_TBEXE)
	$< --vcd=$<.vcd

test_roml: $(OBJDIR)/$(ROML_TBEXE)
	cd Work; ../$< --vcd=../$<.vcd

test_rom_prog: $(OBJDIR)/rom_prog_tb
	$<

test: all test_rom_prog test_fifo test_roml

syn_fifo:
	$(MAKE) -C FPGA/FIFO

syn_fifo_rb:
	$(MAKE) -C FPGA/FIFO_RB

synth: syn_fifo syn_fifo_rb

tarball:
	cd .. ; perl gentarball.pl mems $(WORK) $(VERSION)

