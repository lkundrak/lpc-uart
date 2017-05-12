PROJECT=lpc
PATH:=$(PATH):$(HOME)/intelFPGA_lite/16.1/quartus/bin/

SOURCES=$(shell awk '/^set_global_assignment -name VERILOG_FILE/ {print $$NF}' $(PROJECT).qsf)

all: output_files/$(PROJECT).pof

db/$(PROJECT).map.qmsg: $(PROJECT).qpf $(PROJECT).qsf $(SOURCES)
	quartus_map --read_settings_files=on --write_settings_files=off $(PROJECT) -c $(PROJECT)

db/$(PROJECT).fit.qmsg: db/$(PROJECT).map.qmsg
	quartus_fit --read_settings_files=off --write_settings_files=off $(PROJECT) -c $(PROJECT)

db/$(PROJECT).asm.qmsg: db/$(PROJECT).fit.qmsg
	quartus_asm --read_settings_files=off --write_settings_files=off $(PROJECT) -c $(PROJECT)

output_files/$(PROJECT).pof: db/$(PROJECT).asm.qmsg

program: output_files/$(PROJECT).pof $(PROJECT).cdf
	quartus_pgm -c USB-Blaster $(PROJECT).cdf

$(PROJECT)_tb: tb.v $(SOURCES)
	iverilog -o $@ $^

run: $(PROJECT)_tb
	vvp -n $<

clean:
	rm -rf db output_files incremental_db
