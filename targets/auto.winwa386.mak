ifeq ($(ENABLE_win386),1)
  ifneq ($(BUILD_win386),)
    ifeq ($(BUILD_win386_cpus),)
      BUILD_win386_cpus=3 4 5 6
    endif
    ifneq ($(findstring 0 1 2,$(BUILD_win386_cpus)),)
      $(error Unsupported CPU for win386)
    endif

    ifeq ($(BUILD_win386_mm),)
      BUILD_win386_mm=flat
    endif
    ifneq ($(findstring compact small medium large huge,$(BUILD_win386_mm)),)
      $(error Unsupported memory model for win386)
    endif

    ifeq ($(BUILD_win386_windows),)
      BUILD_win386_windows=30 31
    endif
    ifneq ($(findstring 10 20,$(BUILD_win386_windows)),)
      $(error Unsupported windows version for win386)
    endif

    ifeq ($(BUILD_win386_debug),)
      BUILD_win386_debug=1
    endif

    ifeq ($(BUILD_win386_extlib),)
      BUILD_win386_extlib=1
     endif

    ifeq ($(BUILD_win386_cpuonly),)
      BUILD_win386_cpuonly=1
    endif

    ifneq ($(ENABLE_debug),1)
      BUILD_win386_debug=0
    endif

    ifneq ($(ENABLE_cpuonly),1)
      BUILD_win386_cpuonly=0
    endif

    ifneq ($(ENABLE_extlib),1)
      BUILD_win386_extlib=0
    endif

    BUILD_win386_windows_final=$(filter $(BUILD_enabled_windows),$(BUILD_win386_windows))
    BUILD_win386_cpus_final=$(filter $(BUILD_enabled_cpus),$(BUILD_win386_cpus))
    BUILD_win386_mm_final=$(filter $(BUILD_enabled_mm),$(BUILD_win386_mm))

    BUILD_win386_mm_char_final=
    ifneq ($(findstring flat,$(BUILD_win386_mm_final)),)
      BUILD_win386_mm_char_final += f
    endif

    # Use the shell. GNU make foreach sucks
    _win386_dexo="-"
    ifeq ($(BUILD_win386_debug),1)
      _win386_dexo="{-,d}"
    endif
    _win386_cpuo="-"
    ifeq ($(BUILD_win386_cpuonly),1)
      _win386_cpuo="{-,o}"
    endif
    _win386_exto="-"
    ifeq ($(BUILD_win386_extlib),1)
      _win386_exto="{-,x}"
    endif

    _win386_a=$(shell echo $(_win386_dexo)$(_win386_cpuo)$(_win386_exto))
    BUILD_targets += $(foreach wi,$(BUILD_win386_windows_final),$(foreach ex,$(_win386_a),$(foreach m,$(BUILD_win386_mm_char_final),$(foreach c,$(BUILD_win386_cpus_final),winwa386/$(wi)_$(c)86$(m)$(subst -,,$(ex))))))
  endif
endif

