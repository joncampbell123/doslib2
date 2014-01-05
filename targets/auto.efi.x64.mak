ifneq ($(BUILD_efi_x64),)
  efi_x64_mach=$(shell uname -m)

  ifeq ($(efi_x64_mach),x86_64)
    ifeq ($(BUILD_efi_x64_debug),)
      BUILD_efi_x64_debug=1
    endif

    ifeq ($(BUILD_efi_x64_extlib),)
      BUILD_efi_x64_extlib=1
    endif

    ifeq ($(BUILD_efi_x64_cpuonly),)
      BUILD_efi_x64_cpuonly=1
    endif

    ifneq ($(ENABLE_debug),1)
      BUILD_efi_x64_debug=0
    endif

    ifneq ($(ENABLE_cpuonly),1)
      BUILD_efi_x64_cpuonly=0
    endif
  
    ifneq ($(ENABLE_extlib),1)
      BUILD_efi_x64_extlib=0
    endif

    BUILD_targets += efi/x64
  endif
endif

