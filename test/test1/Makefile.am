
BUILD_dos16r=1
#BUILD_dos32p=1

-include ../../config.mak
-include Makefile.wcc

debugme:
	@echo Enabled CPU: $(BUILD_enabled_cpus)
	@echo Enabled MM: $(BUILD_enabled_mm)
	@echo Targets: $(BUILD_targets)
	@echo suffixes "$(suffixes)"
	@echo $(_d16r_t)
	@echo $(_d16r_c)
	@echo $(_d16r_m)
	@echo $(_d16r_d)
	@echo $(_d16r_o)
	@echo $(_d16r_x)

all:
	@for i in "" $(BUILD_targets); do\
		if [ x"$$i" != x ]; then \
			$(MAKE) --no-print-directory -$(MAKEFLAGS) all-targets target_subdir=$$i;\
		fi;\
	done

clean:
	@for i in "" $(BUILD_targets); do\
		if [ x"$$i" != x ]; then \
			$(MAKE) --no-print-directory -$(MAKEFLAGS) clean-targets target_subdir=$$i;\
		fi;\
	done

