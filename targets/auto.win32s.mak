ifeq ($(ENABLE_win32s),1)
  ifneq ($(BUILD_win32s),)
    ifeq ($(BUILD_win32s_cpus),)
      BUILD_win32s_cpus=3 4 5 6
    endif
    ifneq ($(findstring 0 1 2,$(BUILD_win32s_cpus)),)
      $(error Unsupported CPU for win32s)
    endif

    ifeq ($(BUILD_win32s_mm),)
      BUILD_win32s_mm=flat
    endif
    ifneq ($(findstring compact small medium large huge,$(BUILD_win32s_mm)),)
      $(error Unsupported memory model for win32s)
    endif

    ifeq ($(BUILD_win386_windows),)
      BUILD_win32s_windows=31
    endif
    ifneq ($(findstring 10 20 30,$(BUILD_win386_windows)),)
      $(error Unsupported windows version for win386)
    endif

    ifeq ($(BUILD_win32s_debug),)
      BUILD_win32s_debug=1
    endif

    ifeq ($(BUILD_win32s_extlib),)
      BUILD_win32s_extlib=1
     endif

    ifeq ($(BUILD_win32s_cpuonly),)
      BUILD_win32s_cpuonly=1
    endif

    ifneq ($(ENABLE_debug),1)
      BUILD_win32s_debug=0
    endif

    ifneq ($(ENABLE_cpuonly),1)
      BUILD_win32s_cpuonly=0
    endif

    ifneq ($(ENABLE_extlib),1)
      BUILD_win32s_extlib=0
    endif

    BUILD_win32s_windows_final=$(filter $(BUILD_enabled_windows),$(BUILD_win32s_windows))
    BUILD_win32s_cpus_final=$(filter $(BUILD_enabled_cpus),$(BUILD_win32s_cpus))
    BUILD_win32s_mm_final=$(filter $(BUILD_enabled_mm),$(BUILD_win32s_mm))

    BUILD_win32s_mm_char_final=
    ifneq ($(findstring flat,$(BUILD_win32s_mm_final)),)
      BUILD_win32s_mm_char_final += f
    endif

    # Use the shell. GNU make foreach sucks
    _win32s_dexo="-"
    ifeq ($(BUILD_win32s_debug),1)
      _win32s_dexo="{-,d}"
    endif
    _win32s_cpuo="-"
    ifeq ($(BUILD_win32s_cpuonly),1)
      _win32s_cpuo="{-,o}"
    endif
    _win32s_exto="-"
    ifeq ($(BUILD_win32s_extlib),1)
      _win32s_exto="{-,x}"
    endif

    _win32s_a=$(shell echo $(_win32s_dexo)$(_win32s_cpuo)$(_win32s_exto))
    BUILD_targets += $(foreach wi,$(BUILD_win32s_windows_final),$(foreach ex,$(_win32s_a),$(foreach m,$(BUILD_win32s_mm_char_final),$(foreach c,$(BUILD_win32s_cpus_final),win32s/$(wi)_$(c)86$(m)$(subst -,,$(ex))))))
  endif
endif

