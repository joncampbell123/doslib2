
BUILD_dos16r=1
BUILD_dos16r_mm=compact small medium large huge

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
	+@for i in "" $(BUILD_targets); do\
		if [ x"$$i" != x ]; then \
			$(MAKE) --no-print-directory -$(MAKEFLAGS) clean-targets target_subdir=$$i || break;\
		fi;\
	done

disk:
	dd if=/dev/zero of=test.dsk bs=512 count=2880
	mkfs.vfat -r 240 test.dsk
	for i in ../../build/dos/lib/dos16r/086c/exe/*.dll; do mcopy -i test.dsk $$i ::; done

