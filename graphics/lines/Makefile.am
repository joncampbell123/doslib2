
BUILD_dos16r=1
BUILD_dos32p=1
#BUILD_win16r=1
#BUILD_win16p=1
#BUILD_win16b=1
#BUILD_win386=1
#BUILD_win32s=1
#BUILD_win32=1
#BUILD_linux_host=1

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
#	mcopy -i test.dsk ../../build/test/test1/win16r/20_086l/exe/test1.exe ::r20_086l.exe

