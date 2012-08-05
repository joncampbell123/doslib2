ifeq ($(ENABLE_win16b),1)
  ifneq ($(BUILD_win16b),)
    ifeq ($(BUILD_win16b_cpus),)
      BUILD_win16b_cpus=0 2 3 4 5 6
    endif
    ifneq ($(findstring 1,$(BUILD_win16b_cpus)),)
      $(error Unsupported CPU for win16b)
    endif

    ifeq ($(BUILD_win16b_mm),)
      BUILD_win16b_mm=compact small medium large
    endif
    ifneq ($(findstring flat huge,$(BUILD_win16b_mm)),)
      $(error Unsupported memory model for win16b)
    endif

    ifeq ($(BUILD_win16b_windows),)
      BUILD_win16b_windows=20 30 31
    endif
    ifneq ($(findstring 10 20,$(BUILD_win16b_windows)),)
      $(error Unsupported windows version for win16b)
    endif

    ifeq ($(BUILD_win16b_debug),)
      BUILD_win16b_debug=1
    endif

    ifeq ($(BUILD_win16b_extlib),)
      BUILD_win16b_extlib=1
    endif

    ifeq ($(BUILD_win16b_cpuonly),)
      BUILD_win16b_cpuonly=1
    endif

    ifneq ($(ENABLE_debug),1)
      BUILD_win16b_debug=0
    endif

    ifneq ($(ENABLE_cpuonly),1)
      BUILD_win16b_cpuonly=0
    endif
  
    ifneq ($(ENABLE_extlib),1)
      BUILD_win16b_extlib=0
    endif

    BUILD_win16b_windows_final=$(filter $(BUILD_enabled_windows),$(BUILD_win16b_windows))
    BUILD_win16b_cpus_final=$(filter $(BUILD_enabled_cpus),$(BUILD_win16b_cpus))
    BUILD_win16b_mm_final=$(filter $(BUILD_enabled_mm),$(BUILD_win16b_mm))

    BUILD_win16b_mm_char_final=
    ifneq ($(findstring compact,$(BUILD_win16b_mm_final)),)
      BUILD_win16b_mm_char_final += c
    endif
    ifneq ($(findstring small,$(BUILD_win16b_mm_final)),)
      BUILD_win16b_mm_char_final += s
    endif
    ifneq ($(findstring medium,$(BUILD_win16b_mm_final)),)
      BUILD_win16b_mm_char_final += m
    endif
    ifneq ($(findstring large,$(BUILD_win16b_mm_final)),)
      BUILD_win16b_mm_char_final += l
    endif
    ifneq ($(findstring huge,$(BUILD_win16b_mm_final)),)
      BUILD_win16b_mm_char_final += h
    endif
    ifneq ($(findstring flat,$(BUILD_win16b_mm_final)),)
      BUILD_win16b_mm_char_final += f
    endif

    # Use the shell. GNU make foreach sucks
    _win16b_dexo="-"
    ifeq ($(BUILD_win16b_debug),1)
      _win16b_dexo="{-,d}"
    endif
    _win16b_cpuo="-"
    ifeq ($(BUILD_win16b_cpuonly),1)
      _win16b_cpuo="{-,o}"
    endif
    _win16b_exto="-"
    ifeq ($(BUILD_win16b_extlib),1)
      _win16b_exto="{-,x}"
    endif

    _win16b_a=$(shell echo $(_win16b_dexo)$(_win16b_cpuo)$(_win16b_exto))
    BUILD_targets += $(foreach wi,$(BUILD_win16b_windows_final),$(foreach ex,$(_win16b_a),$(foreach m,$(BUILD_win16b_mm_char_final),$(foreach c,$(BUILD_win16b_cpus_final),win16b/$(wi)_$(c)86$(m)$(subst -,,$(ex))))))
  endif
endif

