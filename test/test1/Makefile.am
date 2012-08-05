
BUILD_dos16r=1
BUILD_dos32p=1
BUILD_win16r=1
BUILD_win16p=1
BUILD_win16b=1
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
			$(MAKE) --no-print-directory -$(MAKEFLAGS) all-targets target_subdir=$$i;\
		fi;\
	done

clean:
	+@for i in "" $(BUILD_targets); do\
		if [ x"$$i" != x ]; then \
			$(MAKE) --no-print-directory -$(MAKEFLAGS) clean-targets target_subdir=$$i;\
		fi;\
	done

disk:
	dd if=/dev/zero of=test.dsk bs=512 count=2880
	mkfs.vfat test.dsk
	mcopy -i test.dsk ../../build/test/test1/win16r/20_086l/exe/test1.exe ::r20_086l.exe
	mcopy -i test.dsk ../../build/test/test1/win16r/20_086c/exe/test1.exe ::r20_086c.exe
	mcopy -i test.dsk ../../build/test/test1/win16r/30_086l/exe/test1.exe ::r30_086l.exe
	mcopy -i test.dsk ../../build/test/test1/win16r/30_086c/exe/test1.exe ::r30_086c.exe
	mcopy -i test.dsk ../../build/test/test1/win16r/31_086l/exe/test1.exe ::r31_086l.exe
	mcopy -i test.dsk ../../build/test/test1/win16r/31_086c/exe/test1.exe ::r31_086c.exe
	mcopy -i test.dsk ../../build/test/test1/win16p/30_386l/exe/test1.exe ::p30_386l.exe
	mcopy -i test.dsk ../../build/test/test1/win16p/30_386c/exe/test1.exe ::p30_386c.exe
	mcopy -i test.dsk ../../build/test/test1/win16p/31_386l/exe/test1.exe ::p31_386l.exe
	mcopy -i test.dsk ../../build/test/test1/win16p/31_386c/exe/test1.exe ::p31_386c.exe
	mcopy -i test.dsk ../../build/test/test1/win16b/20_386l/exe/test1.exe ::b20_386l.exe
	mcopy -i test.dsk ../../build/test/test1/win16b/20_386c/exe/test1.exe ::b20_386c.exe
	mcopy -i test.dsk ../../build/test/test1/win16b/30_386l/exe/test1.exe ::b30_386l.exe
	mcopy -i test.dsk ../../build/test/test1/win16b/30_386c/exe/test1.exe ::b30_386c.exe
	mcopy -i test.dsk ../../build/test/test1/win16b/31_386l/exe/test1.exe ::b31_386l.exe
	mcopy -i test.dsk ../../build/test/test1/win16b/31_386c/exe/test1.exe ::b31_386c.exe

