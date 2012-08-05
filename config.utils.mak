
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

    dexo=""
    ifeq ($(BUILD_dos16r_debug),1)
      dexo="" d
    endif
    cpuo=""
    ifeq ($(BUILD_dos16r_cpuonly),1)
      cpuo="" o
    endif
    exto=""
    ifeq ($(BUILD_dos16r_extlib),1)
      exto="" x
    endif

    a=$(foreach x,$(dexo),$(x))
    b=$(foreach x,$(cpuo),$(a)$(x))
    c=$(foreach x,$(exto),$(b)$(x))
    BUILD_targets += $(foreach ex,$(c),$(foreach m,$(BUILD_dos16r_mm_char_final),$(foreach c,$(BUILD_dos16r_cpus_final),dos16r/$(c)86$(m)$(ex))))
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
    ifneq ($(findstring compact,$(BUILD_dos32p_mm_final)),)
      BUILD_dos32p_mm_char_final += c
    endif
    ifneq ($(findstring small,$(BUILD_dos32p_mm_final)),)
      BUILD_dos32p_mm_char_final += s
    endif
    ifneq ($(findstring medium,$(BUILD_dos32p_mm_final)),)
      BUILD_dos32p_mm_char_final += m
    endif
    ifneq ($(findstring large,$(BUILD_dos32p_mm_final)),)
      BUILD_dos32p_mm_char_final += l
    endif
    ifneq ($(findstring huge,$(BUILD_dos32p_mm_final)),)
      BUILD_dos32p_mm_char_final += h
    endif
    ifneq ($(findstring flat,$(BUILD_dos32p_mm_final)),)
      BUILD_dos32p_mm_char_final += f
    endif

    dexo=""
    ifeq ($(BUILD_dos32p_debug),1)
      dexo="" d
    endif
    cpuo=""
    ifeq ($(BUILD_dos32p_cpuonly),1)
      cpuo="" o
    endif
    exto=""
    ifeq ($(BUILD_dos32p_extlib),1)
      exto="" x
    endif

    a=$(foreach x,$(dexo),$(x))
    b=$(foreach x,$(cpuo),$(a)$(x))
    c=$(foreach x,$(exto),$(b)$(x))
    BUILD_targets += $(foreach ex,$(c),$(foreach m,$(BUILD_dos32p_mm_char_final),$(foreach c,$(BUILD_dos32p_cpus_final),dos32p/$(c)86$(m)$(ex))))
  endif
endif

ifneq ($(target_subdir),)
# Yes, I'm aware $(target_subdir) usually takes the form dos16r/086c
include $(abs_top_builddir)/targets/config.$(patsubst %/,%,$(dir $(target_subdir))).mak
endif

