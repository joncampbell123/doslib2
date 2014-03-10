
BUILD_dos16r=1
BUILD_dos16r_mm=compact
BUILD_linux_host=1

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

disk720:
	dd if=/dev/zero of=test720.dsk bs=512 count=1440
	mkfs.vfat -r 240 test720.dsk # NOTE! For the disk image to actually work with MS-DOS the root directory count must be <= 240
	for i in ../../build/traplog/dos/dos16r/086c/exe/*.com; do mcopy -i test720.dsk $$i ::; done
	for i in ../../build/traplog/dos/dos16r/086c/exe/*.exe; do mcopy -i test720.dsk $$i ::; done

disk:
	dd if=/dev/zero of=test.dsk bs=512 count=2880
	mkfs.vfat -r 240 test.dsk
	for i in ../../build/traplog/dos/dos16r/086c/exe/*.com; do mcopy -i test.dsk $$i ::; done
	for i in ../../build/traplog/dos/dos16r/086c/exe/*.exe; do mcopy -i test.dsk $$i ::; done

disk-all: disk disk720

