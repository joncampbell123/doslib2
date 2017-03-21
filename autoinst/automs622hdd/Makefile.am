
-include ../../config.mak
-include Makefile.wcc

noinst_PROGRAMS = expand

LIBMSPACK = ../../ext/libmspack/libmspack/./.libs/libmspack.a

expand_SOURCES = expand.c
expand_CFLAGS = -I../../ext/libmspack/libmspack/mspack
expand_LDFLAGS = $(LIBMSPACK)
expand_DEPENDENCIES = $(LIBMSPACK)

# I like how their configure script throws a bitchfit about missing doc/Makefile.in when
# I don't really care about the documentation. Restore it.
$(LIBMSPACK):
	cd ../../ext/libmspack && (git clean; git reset --hard)
	cd ../../ext/libmspack/libmspack && autoreconf -vif
	cd ../../ext/libmspack/libmspack && ./configure --enable-static --disable-shared
	cd ../../ext/libmspack/libmspack && make

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
	rm -fv expand
	rm -Rfv dos.tmp

disk:

