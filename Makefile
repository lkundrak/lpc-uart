#### General

all: do_all stats

clean:
	rm -rf db output_files incremental_db test.vcd tb $(TOPLEVEL).blif $(TOPLEVEL).asc $(TOPLEVEL).bin

#### Quertus

PATH:=$(PATH):$(HOME)/intelFPGA_lite/16.1/quartus/bin/
PROJECT_FILE=device.qsf
SOURCES=$(shell awk '/^set_global_assignment -name VERILOG_FILE/ {print $$NF}' $(PROJECT_FILE))
TOPLEVEL=$(shell awk '/^set_global_assignment -name TOP_LEVEL_ENTITY/ {print $$NF}' $(PROJECT_FILE))

do_all: output_files/$(TOPLEVEL).pof

db/$(TOPLEVEL).map.qmsg: $(TOPLEVEL).qsf $(SOURCES)
	quartus_map --read_settings_files=on --write_settings_files=off $(TOPLEVEL) -c $(TOPLEVEL)

db/$(TOPLEVEL).fit.qmsg: db/$(TOPLEVEL).map.qmsg
	quartus_fit --read_settings_files=off --write_settings_files=off $(TOPLEVEL) -c $(TOPLEVEL)

db/$(TOPLEVEL).asm.qmsg: db/$(TOPLEVEL).fit.qmsg
	quartus_asm --read_settings_files=off --write_settings_files=off $(TOPLEVEL) -c $(TOPLEVEL)

output_files/$(TOPLEVEL).pof: db/$(TOPLEVEL).asm.qmsg

program: do_program stats

do_program: output_files/$(TOPLEVEL).pof $(TOPLEVEL).cdf
	quartus_pgm -c USB-Blaster $(TOPLEVEL).cdf

stats: output_files/$(TOPLEVEL).pof
	@grep 'Total logic elements' output_files/$(TOPLEVEL).fit.rpt

#### IceStorm

$(TOPLEVEL).blif: uart_rx.v uart_tx.v lpc.v $(TOPLEVEL).v

%.blif: %.v
	yosys -q -p "synth_ice40 -blif $@" $^

%.asc: %.blif
	arachne-pnr -d 1k -p $(basename $<).pcf $< -o $@

%.bin: %.asc
	icepack $< $@

iceprog: $(TOPLEVEL).bin
	iceprog $<

icetime: $(TOPLEVEL).asc
	icetime -tmd hx1k $<

#### Icarus

tb: tb.v $(SOURCES)
	iverilog -o $@ $^

test: tb
	vvp -n $<

test.vcd: test
