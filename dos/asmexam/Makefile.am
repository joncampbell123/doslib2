
BUILD_dos16r=1
BUILD_dos16r_mm=compact

-include ../../config.mak
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
	+@for i in "" $(BUILD_targets); do\
		if [ x"$$i" != x ]; then \
			$(MAKE) --no-print-directory -$(MAKEFLAGS) clean-targets target_subdir=$$i || break;\
		fi;\
	done

disk:
	dd if=/dev/zero of=test.dsk bs=512 count=2880
	mkfs.vfat test.dsk
	for i in ../../build/dos/asmexam/dos16r/086c/exe/*.com; do mcopy -i test.dsk $$i ::; done
	dd if=/dev/zero of=test720.dsk bs=512 count=1440
	mkfs.vfat -r 256 test720.dsk
	for i in ../../build/dos/asmexam/dos16r/086c/exe/*.com; do mcopy -i test720.dsk $$i ::; done
	xz -c -d pcdos1bt.ref.xz >test160.dsk
	./replace-bootsector-mkvfat.pl test160.dsk 0xFE 8 1 40 0x800 1
	for i in ../../build/dos/asmexam/dos16r/086c/exe/*.com; do mcopy -i test160.dsk $$i ::; done

