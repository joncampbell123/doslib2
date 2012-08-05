
rel_srcdir=$(subst $(abs_top_srcdir)/,,$(abs_srcdir))
ifneq ($(target_subdir),)
abs_exe_dir=$(abs_top_builddir)/build/$(rel_srcdir)/$(target_subdir)/exe
abs_obj_dir=$(abs_top_builddir)/build/$(rel_srcdir)/$(target_subdir)/obj
abs_lib_dir=$(abs_top_builddir)/build/$(rel_srcdir)/$(target_subdir)/lib

$(abs_exe_dir):
	@mkdir -p $@

$(abs_lib_dir):
	@mkdir -p $@

$(abs_obj_dir):
	@mkdir -p $@
endif

# what CPUs were asked to be built?
BUILD_enabled_cpus=
ifeq ($(ENABLE_cpu_8086),1)
 BUILD_enabled_cpus += 0
endif
ifeq ($(ENABLE_cpu_286),1)
 BUILD_enabled_cpus += 2
endif
ifeq ($(ENABLE_cpu_386),1)
 BUILD_enabled_cpus += 3
endif
ifeq ($(ENABLE_cpu_486),1)
 BUILD_enabled_cpus += 4
endif
ifeq ($(ENABLE_cpu_586),1)
 BUILD_enabled_cpus += 5
endif
ifeq ($(ENABLE_cpu_686),1)
 BUILD_enabled_cpus += 6
endif

# what memory models?
BUILD_enabled_mm=
ifeq ($(ENABLE_mm_compact),1)
 BUILD_enabled_mm += compact
endif
ifeq ($(ENABLE_mm_small),1)
 BUILD_enabled_mm += small
endif
ifeq ($(ENABLE_mm_medium),1)
 BUILD_enabled_mm += medium
endif
ifeq ($(ENABLE_mm_large),1)
 BUILD_enabled_mm += large
endif
ifeq ($(ENABLE_mm_huge),1)
 BUILD_enabled_mm += huge
endif
ifeq ($(ENABLE_mm_flat),1)
 BUILD_enabled_mm += flat
endif

# what Windows versions (TODO: Add 10 20 95 98 me nt by configure options)
BUILD_enabled_windows=30 31

# list target subdirs
BUILD_targets=

# dos16r
ifeq ($(ENABLE_dos16r),1)
  ifneq ($(BUILD_dos16r),)
    ifeq ($(BUILD_dos16r_cpus),)
      BUILD_dos16r_cpus=0 2 3 4 5 6
    endif
    ifneq ($(findstring 1,$(BUILD_dos16r_cpus)),)
      $(error Unsupported CPU for dos16r)
    endif

    ifeq ($(BUILD_dos16r_mm),)
      BUILD_dos16r_mm=compact small medium large huge
    endif
    ifneq ($(findstring flat,$(BUILD_dos16r_mm)),)
      $(error Unsupported memory model for dos16r)
    endif

    ifeq ($(BUILD_dos16r_debug),)
      BUILD_dos16r_debug=1
    endif

    ifeq ($(BUILD_dos16r_extlib),)
      BUILD_dos16r_extlib=1
    endif

    ifeq ($(BUILD_dos16r_cpuonly),)
      BUILD_dos16r_cpuonly=1
    endif

    ifneq ($(ENABLE_debug),1)
      BUILD_dos16r_debug=0
    endif

    ifneq ($(ENABLE_cpuonly),1)
      BUILD_dos16r_cpuonly=0
    endif
  
    ifneq ($(ENABLE_extlib),1)
      BUILD_dos16r_extlib=0
    endif

    BUILD_dos16r_cpus_final=$(filter $(BUILD_enabled_cpus),$(BUILD_dos16r_cpus))
    BUILD_dos16r_mm_final=$(filter $(BUILD_enabled_mm),$(BUILD_dos16r_mm))

    BUILD_dos16r_mm_char_final=
    ifneq ($(findstring compact,$(BUILD_dos16r_mm_final)),)
      BUILD_dos16r_mm_char_final += c
    endif
    ifneq ($(findstring small,$(BUILD_dos16r_mm_final)),)
      BUILD_dos16r_mm_char_final += s
    endif
    ifneq ($(findstring medium,$(BUILD_dos16r_mm_final)),)
      BUILD_dos16r_mm_char_final += m
    endif
    ifneq ($(findstring large,$(BUILD_dos16r_mm_final)),)
      BUILD_dos16r_mm_char_final += l
    endif
    ifneq ($(findstring huge,$(BUILD_dos16r_mm_final)),)
      BUILD_dos16r_mm_char_final += h
    endif
    ifneq ($(findstring flat,$(BUILD_dos16r_mm_final)),)
      BUILD_dos16r_mm_char_final += f
    endif

    # Use the shell. GNU make foreach sucks
    _dos16r_dexo="-"
    ifeq ($(BUILD_dos16r_debug),1)
      _dos16r_dexo="{-,d}"
    endif
    _dos16r_cpuo="-"
    ifeq ($(BUILD_dos16r_cpuonly),1)
      _dos16r_cpuo="{-,o}"
    endif
    _dos16r_exto="-"
    ifeq ($(BUILD_dos16r_extlib),1)
      _dos16r_exto="{-,x}"
    endif

    _dos16r_a=$(shell echo $(_dos16r_dexo)$(_dos16r_cpuo)$(_dos16r_exto))
    BUILD_targets += $(foreach ex,$(_dos16r_a),$(foreach m,$(BUILD_dos16r_mm_char_final),$(foreach c,$(BUILD_dos16r_cpus_final),dos16r/$(c)86$(m)$(subst -,,$(ex)))))
  endif
endif

# dos32p
ifeq ($(ENABLE_dos32p),1)
  ifneq ($(BUILD_dos32p),)
    ifeq ($(BUILD_dos32p_cpus),)
      BUILD_dos32p_cpus=3 4 5 6
    endif
    ifneq ($(findstring 0 1 2,$(BUILD_dos32p_cpus)),)
      $(error Unsupported CPU for dos32p)
    endif

    ifeq ($(BUILD_dos32p_mm),)
      BUILD_dos32p_mm=flat
    endif
    ifneq ($(findstring compact small medium large huge,$(BUILD_dos32p_mm)),)
      $(error Unsupported memory model for dos32p)
    endif

    ifeq ($(BUILD_dos32p_debug),)
      BUILD_dos32p_debug=1
    endif

    ifeq ($(BUILD_dos32p_extlib),)
      BUILD_dos32p_extlib=1
     endif

    ifeq ($(BUILD_dos32p_cpuonly),)
      BUILD_dos32p_cpuonly=1
    endif

    ifneq ($(ENABLE_debug),1)
      BUILD_dos32p_debug=0
    endif

    ifneq ($(ENABLE_cpuonly),1)
      BUILD_dos32p_cpuonly=0
    endif

    ifneq ($(ENABLE_extlib),1)
      BUILD_dos32p_extlib=0
    endif

    BUILD_dos32p_cpus_final=$(filter $(BUILD_enabled_cpus),$(BUILD_dos32p_cpus))
    BUILD_dos32p_mm_final=$(filter $(BUILD_enabled_mm),$(BUILD_dos32p_mm))

    BUILD_dos32p_mm_char_final=
    ifneq ($(findstring flat,$(BUILD_dos32p_mm_final)),)
      BUILD_dos32p_mm_char_final += f
    endif

    # Use the shell. GNU make foreach sucks
    _dos32p_dexo="-"
    ifeq ($(BUILD_dos32p_debug),1)
      _dos32p_dexo="{-,d}"
    endif
    _dos32p_cpuo="-"
    ifeq ($(BUILD_dos32p_cpuonly),1)
      _dos32p_cpuo="{-,o}"
    endif
    _dos32p_exto="-"
    ifeq ($(BUILD_dos32p_extlib),1)
      _dos32p_exto="{-,x}"
    endif

    _dos32p_a=$(shell echo $(_dos32p_dexo)$(_dos32p_cpuo)$(_dos32p_exto))
    BUILD_targets += $(foreach ex,$(_dos32p_a),$(foreach m,$(BUILD_dos32p_mm_char_final),$(foreach c,$(BUILD_dos32p_cpus_final),dos32p/$(c)86$(m)$(subst -,,$(ex)))))
  endif
endif

# win16p
ifeq ($(ENABLE_win16p),1)
  ifneq ($(BUILD_win16p),)
    ifeq ($(BUILD_win16p_cpus),)
      BUILD_win16p_cpus=2 3 4 5 6
    endif
    ifneq ($(findstring 0 1,$(BUILD_win16p_cpus)),)
      $(error Unsupported CPU for win16p)
    endif

    ifeq ($(BUILD_win16p_mm),)
      BUILD_win16p_mm=compact small medium large
    endif
    ifneq ($(findstring flat huge,$(BUILD_win16p_mm)),)
      $(error Unsupported memory model for win16p)
    endif

    ifeq ($(BUILD_win16p_windows),)
      BUILD_win16p_windows=30 31
    endif
    ifneq ($(findstring 10 20,$(BUILD_win16p_windows)),)
      $(error Unsupported windows version for win16p)
    endif

    ifeq ($(BUILD_win16p_debug),)
      BUILD_win16p_debug=1
    endif

    ifeq ($(BUILD_win16p_extlib),)
      BUILD_win16p_extlib=1
    endif

    ifeq ($(BUILD_win16p_cpuonly),)
      BUILD_win16p_cpuonly=1
    endif

    ifneq ($(ENABLE_debug),1)
      BUILD_win16p_debug=0
    endif

    ifneq ($(ENABLE_cpuonly),1)
      BUILD_win16p_cpuonly=0
    endif
  
    ifneq ($(ENABLE_extlib),1)
      BUILD_win16p_extlib=0
    endif

    BUILD_win16p_windows_final=$(filter $(BUILD_enabled_windows),$(BUILD_win16p_windows))
    BUILD_win16p_cpus_final=$(filter $(BUILD_enabled_cpus),$(BUILD_win16p_cpus))
    BUILD_win16p_mm_final=$(filter $(BUILD_enabled_mm),$(BUILD_win16p_mm))

    BUILD_win16p_mm_char_final=
    ifneq ($(findstring compact,$(BUILD_win16p_mm_final)),)
      BUILD_win16p_mm_char_final += c
    endif
    ifneq ($(findstring small,$(BUILD_win16p_mm_final)),)
      BUILD_win16p_mm_char_final += s
    endif
    ifneq ($(findstring medium,$(BUILD_win16p_mm_final)),)
      BUILD_win16p_mm_char_final += m
    endif
    ifneq ($(findstring large,$(BUILD_win16p_mm_final)),)
      BUILD_win16p_mm_char_final += l
    endif
    ifneq ($(findstring huge,$(BUILD_win16p_mm_final)),)
      BUILD_win16p_mm_char_final += h
    endif
    ifneq ($(findstring flat,$(BUILD_win16p_mm_final)),)
      BUILD_win16p_mm_char_final += f
    endif

    # Use the shell. GNU make foreach sucks
    _win16p_dexo="-"
    ifeq ($(BUILD_win16p_debug),1)
      _win16p_dexo="{-,d}"
    endif
    _win16p_cpuo="-"
    ifeq ($(BUILD_win16p_cpuonly),1)
      _win16p_cpuo="{-,o}"
    endif
    _win16p_exto="-"
    ifeq ($(BUILD_win16p_extlib),1)
      _win16p_exto="{-,x}"
    endif

    _win16p_a=$(shell echo $(_win16p_dexo)$(_win16p_cpuo)$(_win16p_exto))
    BUILD_targets += $(foreach wi,$(BUILD_win16p_windows_final),$(foreach ex,$(_win16p_a),$(foreach m,$(BUILD_win16p_mm_char_final),$(foreach c,$(BUILD_win16p_cpus_final),win16p/$(wi)_$(c)86$(m)$(subst -,,$(ex))))))
  endif
endif


ifneq ($(target_subdir),)
# Yes, I'm aware $(target_subdir) usually takes the form dos16r/086c
include $(abs_top_builddir)/targets/config.$(patsubst %/,%,$(dir $(target_subdir))).mak
endif

