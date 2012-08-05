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

