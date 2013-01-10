
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

disk-pcdos10:
	xz -c -d pcdos1bt.ref.xz >test160.dsk
	./replace-bootsector-mkvfat.pl test160.dsk 0xFE 8 1 40 0x800 1
	for i in `cat pcdos1bt.disk1`; do echo $$i; mcopy -i test160.dsk ../../build/dos/asmexam/dos16r/086c/exe/$$i ::; done
	./replace-bootsector-other.pl test160.dsk pcdos1bt.ref.xz
#----- disk2
	xz -c -d pcdos1bt.ref.xz >test160d2.dsk
	./replace-bootsector-mkvfat.pl test160d2.dsk 0xFE 8 1 40 0x800 1
	for i in `cat pcdos1bt.disk2`; do echo $$i; mcopy -i test160d2.dsk ../../build/dos/asmexam/dos16r/086c/exe/$$i ::; done
	./replace-bootsector-other.pl test160d2.dsk pcdos1bt.ref.xz

disk-pcdos11:
	xz -c -d pcdos11bt.ref.xz >test320_11.dsk
	./replace-bootsector-mkvfat.pl test320_11.dsk 0xFF 8 2 40 0xE00 2
	for i in `cat pcdos11bt.disk1`; do echo $$i; mcopy -i test320_11.dsk ../../build/dos/asmexam/dos16r/086c/exe/$$i ::; done
	./replace-bootsector-other.pl test320_11.dsk pcdos11bt.ref.xz

disk720:
	dd if=/dev/zero of=test720.dsk bs=512 count=1440
	mkfs.vfat -r 240 test720.dsk # NOTE! For the disk image to actually work with MS-DOS the root directory count must be <= 240
	for i in ../../build/dos/asmexam/dos16r/086c/exe/*.com; do mcopy -i test720.dsk $$i ::; done

disk360:
	dd if=/dev/zero of=test360.dsk bs=512 count=720
	mkfs.vfat -r $$((0xE00/32)) test360.dsk
	for i in `cat disk360.disk1`; do echo $$i; mcopy -i test360.dsk ../../build/dos/asmexam/dos16r/086c/exe/$$i ::; done
#------ disk2
	dd if=/dev/zero of=test360d2.dsk bs=512 count=720
	mkfs.vfat -r $$((0xE00/32)) test360d2.dsk
	for i in `cat disk360.disk2`; do echo $$i; mcopy -i test360d2.dsk ../../build/dos/asmexam/dos16r/086c/exe/$$i ::; done

disk:
	dd if=/dev/zero of=test.dsk bs=512 count=2880
	mkfs.vfat -r 240 test.dsk
	for i in ../../build/dos/asmexam/dos16r/086c/exe/*.com; do mcopy -i test.dsk $$i ::; done
	mcopy -i test.dsk ../../cwsdpmi0.dat ::cwsdpmi0.exe
	mcopy -i test.dsk ../../cwsdpmi.dat ::cwsdpmi.exe
	mcopy -i test.dsk ../../hdpmi16.dat ::hdpmi16.exe
	mcopy -i test.dsk ../../hdpmi32.dat ::hdpmi32.exe

disk-all: disk disk-pcdos10 disk-pcdos11 disk720 disk360

