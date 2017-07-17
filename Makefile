PROJECT_FILE=device.qsf
SOURCES=$(shell awk '/^set_global_assignment -name VERILOG_FILE/ {print $$NF}' $(PROJECT_FILE))
TOPLEVEL=$(shell awk '/^set_global_assignment -name TOP_LEVEL_ENTITY/ {print $$NF}' $(PROJECT_FILE))

PATH:=$(PATH):$(HOME)/intelFPGA_lite/16.1/quartus/bin/

all: do_all stats

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

lpc_tb: tb.v $(SOURCES)
	iverilog -o $@ $^

lpc_tb2: tb2.v $(SOURCES)
	iverilog -o $@ $^

run: lpc_tb2
	vvp -n $<

stats: output_files/$(TOPLEVEL).pof
	@grep 'Total logic elements' output_files/$(TOPLEVEL).fit.rpt

clean:
	rm -rf db output_files incremental_db
