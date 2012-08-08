ifeq ($(ENABLE_dos16r),1)
  ifneq ($(BUILD_dos16r),)
    ifeq ($(BUILD_dos16r_cpus),)
      BUILD_dos16r_cpus=0 2 3 4 5 6
    endif
    ifneq ($(findstring 1,$(BUILD_dos16r_cpus)),)
      $(error Unsupported CPU for dos16r)
    endif

    ifeq ($(BUILD_dos16r_mm),)
      BUILD_dos16r_mm=compact small medium large
    endif
    ifneq ($(findstring huge flat,$(BUILD_dos16r_mm)),)
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

