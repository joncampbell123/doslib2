
BUILD_dos16r=1
BUILD_dos32p=1

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
	rm -fv *.dsk

disk:
	dd if=/dev/zero of=test.dsk bs=512 count=2880
	mkfs.vfat test.dsk
	mcopy -i test.dsk ../../build/dos/empty/dos16r/086l/exe/empty1.exe ::d16_086l.exe
	mcopy -i test.dsk ../../build/dos/empty/dos16r/086c/exe/empty1.exe ::d16_086c.exe
	mcopy -i test.dsk ../../build/dos/empty/dos32p/386f/exe/empty1.exe ::d32_386f.exe
	mcopy -i test.dsk ../../dos4gw.dat ::dos4gw.exe
	echo -- -----------------
	dd if=/dev/zero of=test360.dsk bs=512 count=720
	mkfs.vfat -r $$((0xE00/32)) test360.dsk
	mcopy -i test360.dsk ../../build/dos/empty/dos16r/086l/exe/empty1.exe ::d16_086l.exe
	mcopy -i test360.dsk ../../build/dos/empty/dos16r/086c/exe/empty1.exe ::d16_086c.exe
	mcopy -i test360.dsk ../../build/dos/empty/dos32p/386f/exe/empty1.exe ::d32_386f.exe
	mcopy -i test360.dsk ../../dos4gw.dat ::dos4gw.exe
	echo -- -----------------
	xz -c -d pcdos11bt.ref.xz >test320.dsk
	./replace-bootsector-mkvfat.pl test320.dsk 0xFF 8 2 40 0xE00 2
	mcopy -i test320.dsk ../../build/dos/empty/dos16r/086l/exe/empty1.exe ::d16_086l.exe
	mcopy -i test320.dsk ../../build/dos/empty/dos16r/086c/exe/empty1.exe ::d16_086c.exe
	mcopy -i test320.dsk ../../build/dos/empty/dos32p/386f/exe/empty1.exe ::d32_386f.exe
	./replace-bootsector-other.pl test320.dsk pcdos11bt.ref.xz

