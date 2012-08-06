ifeq ($(ENABLE_win32),1)
  ifneq ($(BUILD_win32),)
    ifeq ($(BUILD_win32_cpus),)
      BUILD_win32_cpus=3 4 5 6
    endif
    ifneq ($(findstring 0 1 2,$(BUILD_win32_cpus)),)
      $(error Unsupported CPU for win32)
    endif

    ifeq ($(BUILD_win32_mm),)
      BUILD_win32_mm=flat
    endif
    ifneq ($(findstring compact small medium large huge,$(BUILD_win32_mm)),)
      $(error Unsupported memory model for win32)
    endif

    ifeq ($(BUILD_win32_windows),)
      BUILD_win32_windows=95 nt
    endif
    ifneq ($(findstring 10 20 30 31,$(BUILD_win32_windows)),)
      $(error Unsupported windows version for win32)
    endif

    ifeq ($(BUILD_win32_debug),)
      BUILD_win32_debug=1
    endif

    ifeq ($(BUILD_win32_extlib),)
      BUILD_win32_extlib=1
     endif

    ifeq ($(BUILD_win32_cpuonly),)
      BUILD_win32_cpuonly=1
    endif

    ifneq ($(ENABLE_debug),1)
      BUILD_win32_debug=0
    endif

    ifneq ($(ENABLE_cpuonly),1)
      BUILD_win32_cpuonly=0
    endif

    ifneq ($(ENABLE_extlib),1)
      BUILD_win32_extlib=0
    endif

    BUILD_win32_windows_final=$(filter $(BUILD_enabled_windows),$(BUILD_win32_windows))
    BUILD_win32_cpus_final=$(filter $(BUILD_enabled_cpus),$(BUILD_win32_cpus))
    BUILD_win32_mm_final=$(filter $(BUILD_enabled_mm),$(BUILD_win32_mm))

    BUILD_win32_mm_char_final=
    ifneq ($(findstring flat,$(BUILD_win32_mm_final)),)
      BUILD_win32_mm_char_final += f
    endif

    # Use the shell. GNU make foreach sucks
    _win32_dexo="-"
    ifeq ($(BUILD_win32_debug),1)
      _win32_dexo="{-,d}"
    endif
    _win32_cpuo="-"
    ifeq ($(BUILD_win32_cpuonly),1)
      _win32_cpuo="{-,o}"
    endif
    _win32_exto="-"
    ifeq ($(BUILD_win32_extlib),1)
      _win32_exto="{-,x}"
    endif

    _win32_a=$(shell echo $(_win32_dexo)$(_win32_cpuo)$(_win32_exto))
    BUILD_targets += $(foreach wi,$(BUILD_win32_windows_final),$(foreach ex,$(_win32_a),$(foreach m,$(BUILD_win32_mm_char_final),$(foreach c,$(BUILD_win32_cpus_final),win32/$(wi)_$(c)86$(m)$(subst -,,$(ex))))))
  endif
endif

