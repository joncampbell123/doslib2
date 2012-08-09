ifeq ($(ENABLE_win16r),1)
  ifneq ($(BUILD_win16r),)
    ifeq ($(BUILD_win16r_cpus),)
      BUILD_win16r_cpus=0 2 3 4 5 6
    endif
    ifneq ($(findstring 1,$(BUILD_win16r_cpus)),)
      $(error Unsupported CPU for win16r)
    endif

    ifeq ($(BUILD_win16r_mm),)
      BUILD_win16r_mm=compact small medium large
    endif
    ifneq ($(findstring flat huge,$(BUILD_win16r_mm)),)
      $(error Unsupported memory model for win16r)
    endif

    ifeq ($(BUILD_win16r_windows),) # NTS: Most code does not yet run under Windows 2.0 and earlier    10 20 
      BUILD_win16r_windows=30 31
    endif
    ifneq ($(findstring 95,$(BUILD_win16r_windows)),)
      $(error Unsupported windows version for win16r)
    endif

    ifeq ($(BUILD_win16r_debug),)
      BUILD_win16r_debug=1
    endif

    ifeq ($(BUILD_win16r_extlib),)
      BUILD_win16r_extlib=1
    endif

    ifeq ($(BUILD_win16r_cpuonly),)
      BUILD_win16r_cpuonly=1
    endif

    ifneq ($(ENABLE_debug),1)
      BUILD_win16r_debug=0
    endif

    ifneq ($(ENABLE_cpuonly),1)
      BUILD_win16r_cpuonly=0
    endif
  
    ifneq ($(ENABLE_extlib),1)
      BUILD_win16r_extlib=0
    endif

    BUILD_win16r_windows_final=$(filter $(BUILD_enabled_windows),$(BUILD_win16r_windows))
    BUILD_win16r_cpus_final=$(filter $(BUILD_enabled_cpus),$(BUILD_win16r_cpus))
    BUILD_win16r_mm_final=$(filter $(BUILD_enabled_mm),$(BUILD_win16r_mm))

    BUILD_win16r_mm_char_final=
    ifneq ($(findstring compact,$(BUILD_win16r_mm_final)),)
      BUILD_win16r_mm_char_final += c
    endif
    ifneq ($(findstring small,$(BUILD_win16r_mm_final)),)
      BUILD_win16r_mm_char_final += s
    endif
    ifneq ($(findstring medium,$(BUILD_win16r_mm_final)),)
      BUILD_win16r_mm_char_final += m
    endif
    ifneq ($(findstring large,$(BUILD_win16r_mm_final)),)
      BUILD_win16r_mm_char_final += l
    endif
    ifneq ($(findstring huge,$(BUILD_win16r_mm_final)),)
      BUILD_win16r_mm_char_final += h
    endif
    ifneq ($(findstring flat,$(BUILD_win16r_mm_final)),)
      BUILD_win16r_mm_char_final += f
    endif

    # Use the shell. GNU make foreach sucks
    _win16r_dexo="-"
    ifeq ($(BUILD_win16r_debug),1)
      _win16r_dexo="{-,d}"
    endif
    _win16r_cpuo="-"
    ifeq ($(BUILD_win16r_cpuonly),1)
      _win16r_cpuo="{-,o}"
    endif
    _win16r_exto="-"
    ifeq ($(BUILD_win16r_extlib),1)
      _win16r_exto="{-,x}"
    endif

    _win16r_a=$(shell echo $(_win16r_dexo)$(_win16r_cpuo)$(_win16r_exto))
    BUILD_targets += $(foreach wi,$(BUILD_win16r_windows_final),$(foreach ex,$(_win16r_a),$(foreach m,$(BUILD_win16r_mm_char_final),$(foreach c,$(BUILD_win16r_cpus_final),win16r/$(wi)_$(c)86$(m)$(subst -,,$(ex))))))
  endif
endif

