ifneq ($(BUILD_efi_ia32),)
  efi_ia32_mach=$(shell uname -m)

  ifeq ($(efi_ia32_mach),i686)
    ifeq ($(BUILD_efi_ia32_debug),)
      BUILD_efi_ia32_debug=1
    endif

    ifeq ($(BUILD_efi_ia32_extlib),)
      BUILD_efi_ia32_extlib=1
    endif

    ifeq ($(BUILD_efi_ia32_cpuonly),)
      BUILD_efi_ia32_cpuonly=1
    endif

    ifneq ($(ENABLE_debug),1)
      BUILD_efi_ia32_debug=0
    endif

    ifneq ($(ENABLE_cpuonly),1)
      BUILD_efi_ia32_cpuonly=0
    endif
  
    ifneq ($(ENABLE_extlib),1)
      BUILD_efi_ia32_extlib=0
    endif

    BUILD_targets += efi/ia32
  endif
endif

