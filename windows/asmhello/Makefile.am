
#BUILD_dos16r=1
#BUILD_dos32p=1
BUILD_win16r=1
BUILD_win16p=1
BUILD_win16b=1
#BUILD_win386=1
#BUILD_win32s=1
#BUILD_win32=1
#BUILD_linux_host=1
BUILD_win16r_windows=10 20 30 31
BUILD_win16b_windows=20 30 31 95 98 me nt
BUILD_win16p_windows=20 30 31 95 98 me nt
BUILD_win16r_mm=small

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
	mcopy -i test.dsk ../../build/windows/asmhello/win16r/10_086s/exe/hello.exe ::r10_086s.exe
	mcopy -i test.dsk ../../build/windows/asmhello/win16r/20_086s/exe/hello.exe ::r20_086s.exe
	mcopy -i test.dsk ../../build/windows/asmhello/win16r/30_086s/exe/hello.exe ::r30_086s.exe

