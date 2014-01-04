ifneq ($(BUILD_linux_host),)
  ifneq ($(linux_host_mach),)
    ifeq ($(BUILD_linux_host_debug),)
      BUILD_linux_host_debug=1
    endif

    ifeq ($(BUILD_linux_host_extlib),)
      BUILD_linux_host_extlib=1
    endif

    ifeq ($(BUILD_linux_host_cpuonly),)
      BUILD_linux_host_cpuonly=1
    endif

    ifneq ($(ENABLE_debug),1)
      BUILD_linux_host_debug=0
    endif

    ifneq ($(ENABLE_cpuonly),1)
      BUILD_linux_host_cpuonly=0
    endif
  
    ifneq ($(ENABLE_extlib),1)
      BUILD_linux_host_extlib=0
    endif

    BUILD_targets += linux/$(linux_host_mach)
  endif
endif

