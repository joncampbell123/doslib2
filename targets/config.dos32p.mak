# DOS 32-bit protected mode target

WCC=env $(WATENV) $(OWCC386)
WCL=env $(WATENV) $(OWCL386)
WLIB=env $(WATENV) $(OWLIB)
WLINK=env $(WATENV) $(OWLINK)
WBIND=env $(WATENV) $(OWBIND)
WSTRIP=env $(WATENV) $(OWSTRIP)
exe_suffix=.exe
obj_suffix=.obj
lib_suffix=.lib

WATENV += "INCLUDE=$(OPENWATCOM)/h"

# make flags
TARGET_MSDOS=1
TARGET_BITS=32
TARGET_PROTMODE=1

# target-dependent
TARGET_EXTLIB=0
TARGET_CPUONLY=0
W_CPULEVEL=3
W_MMODE=l

TARGET_DEBUG=0
W_DEBUG=-d0 -s

# eval the targetdir
_d32p_t=$(subst 86,,$(patsubst dos32p/%,%,$(target_subdir)))

ifeq ($(findstring 3,$(_d32p_t)),3)
  W_CPULEVEL=3
endif
ifeq ($(findstring 4,$(_d32p_t)),4)
  W_CPULEVEL=4
endif
ifeq ($(findstring 5,$(_d32p_t)),5)
  W_CPULEVEL=5
endif
ifeq ($(findstring 6,$(_d32p_t)),6)
  W_CPULEVEL=6
endif

ifeq ($(findstring f,$(_d32p_t)),f)
  W_MMODE=f
endif

ifeq ($(findstring o,$(_d32p_t)),o)
TARGET_CPUONLY=1
endif

ifeq ($(findstring x,$(_d32p_t)),x)
TARGET_EXTLIB=1
endif

ifeq ($(findstring d,$(_d32p_t)),d)
TARGET_DEBUG=1
W_DEBUG=-d3
endif

# compiler flags
_d32p_defs = -dTARGET_MSDOS=1 -dTARGET_BITS=32 -dTARGET_PROTMODE=1 -dTARGET_CPU=$(W_CPULEVEL)
ifeq ($(TARGET_CPUONLY),1)
_d32p_defs += -dTARGET_CPUONLY=1
endif
ifeq ($(TARGET_EXTLIB),1)
_d32p_defs += -dTARGET_EXTLIB=1
endif
ifeq ($(TARGET_DEBUG),1)
_d32p_defs += -dTARGET_DEBUG=1
endif

WLINKFLAGS=
WCCFLAGS=-e=2 -zq -m$(W_MMODE) $(W_DEBUG) -bt=dos -oilrtfm -wx -$(W_CPULEVEL) $(_d32p_defs) -q -fr=nul
WASMFLAGS=-e=2 -zq -m$(W_MMODE) $(W_DEBUG) -bt=dos -wx -$(W_CPULEVEL) $(_d32p_defs) -q
NASMFLAGS=-DTARGET_MSDOS=1 -DTARGET_BITS=32 -DTARGET_PROTMODE=1 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -DDEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL)
WLINK_SYSTEM=dos4g

# DOS *IS* a console OS, flags are the same
WCCFLAGS_CONSOLE=$(WCCFLAGS)
WASMFLAGS_CONSOLE=$(WASMFLAGS)
NASMFLAGS_CONSOLE=$(NASMFLAGS)
WLINKFLAGS_CONSOLE=$(WLINKFLAGS)
WLINK_SYSTEM_CONSOLE=$(WLINK_SYSTEM)

