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

