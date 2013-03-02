
BUILD_dos16r=1
BUILD_dos16r_mm=compact

-include ../../../config.mak
-include Makefile.wcc

debugme:
	@echo Enabled CPU: $(BUILD_enabled_cpus)
	@echo Enabled MM: $(BUILD_enabled_mm)
	@echo Targets: $(BUILD_targets)
	@echo suffixes "$(suffixes)"

all:
	+@for i in "" $(BUILD_targets); do\
		if [ x"$$i" != x ]; then \
			$(MAKE) --no-print-directory -$(MAKEFLAGS) all-targets target_subdir=$$i || break;\
		fi;\
	done

clean:
	@rm -f *~
	@rm -v *.dsk
	+@for i in "" $(BUILD_targets); do\
		if [ x"$$i" != x ]; then \
			$(MAKE) --no-print-directory -$(MAKEFLAGS) clean-targets target_subdir=$$i || break;\
		fi;\
	done

disk:
	dd if=/dev/zero of=test.dsk bs=512 count=2880
	mkfs.vfat test.dsk
	for i in *.txt; do mcopy -i test.dsk $$i ::; done
	for i in ../../../build/bios/asmexam/rombios/dos16r/086c/exe/*.com; do mcopy -i test.dsk $$i ::; done
	dd if=/dev/zero of=test720.dsk bs=512 count=1440
	mkfs.vfat test720.dsk
	for i in *.txt; do mcopy -i test720.dsk $$i ::; done
	for i in ../../../build/bios/asmexam/rombios/dos16r/086c/exe/*.com; do mcopy -i test720.dsk $$i ::; done
	dd if=/dev/zero of=test360.dsk bs=512 count=720
	mkfs.vfat test360.dsk
	for i in *.txt; do mcopy -i test360.dsk $$i ::; done
	for i in ../../../build/bios/asmexam/rombios/dos16r/086c/exe/*.com; do mcopy -i test360.dsk $$i ::; done
	dd if=/dev/zero of=test320.dsk bs=512 count=640
	mkfs.vfat test320.dsk
	for i in *.txt; do mcopy -i test320.dsk $$i ::; done
	for i in ../../../build/bios/asmexam/rombios/dos16r/086c/exe/*.com; do mcopy -i test320.dsk $$i ::; done

disk-all: disk

