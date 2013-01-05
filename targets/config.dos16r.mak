# DOS 16-bit real mode target

WCC=env $(WATENV) $(OWCC)
WCL=env $(WATENV) $(OWCL)
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
TARGET_BITS=16
TARGET_REALMODE=1

# target-dependent
TARGET_EXTLIB=0
TARGET_CPUONLY=0
W_CPULEVEL=0
W_MMODE=l

TARGET_DEBUG=0
W_DEBUG=-d0 -s

# eval the targetdir
_d16r_t=$(subst 86,,$(patsubst dos16r/%,%,$(target_subdir)))

ifeq ($(findstring 0,$(_d16r_t)),0)
  W_CPULEVEL=0
endif
ifeq ($(findstring 2,$(_d16r_t)),2)
  W_CPULEVEL=2
endif
ifeq ($(findstring 3,$(_d16r_t)),3)
  W_CPULEVEL=3
endif
ifeq ($(findstring 4,$(_d16r_t)),4)
  W_CPULEVEL=4
endif
ifeq ($(findstring 5,$(_d16r_t)),5)
  W_CPULEVEL=5
endif
ifeq ($(findstring 6,$(_d16r_t)),6)
  W_CPULEVEL=6
endif

ifeq ($(findstring c,$(_d16r_t)),c)
  W_MMODE=c
endif
ifeq ($(findstring s,$(_d16r_t)),s)
  W_MMODE=s
endif
ifeq ($(findstring m,$(_d16r_t)),m)
  W_MMODE=m
endif
ifeq ($(findstring l,$(_d16r_t)),l)
  W_MMODE=l
endif
ifeq ($(findstring h,$(_d16r_t)),h)
  W_MMODE=h
endif
ifeq ($(findstring f,$(_d16r_t)),f)
  W_MMODE=f
endif

ifeq ($(findstring o,$(_d16r_t)),o)
TARGET_CPUONLY=1
endif

ifeq ($(findstring x,$(_d16r_t)),x)
TARGET_EXTLIB=1
endif

ifeq ($(findstring d,$(_d16r_t)),d)
TARGET_DEBUG=1
W_DEBUG=-d3
endif

# compiler flags
_d16r_defs = -dTARGET_MSDOS=1 -dTARGET_BITS=16 -dTARGET_REALMODE=1 -dTARGET_CPU=$(W_CPULEVEL)
ifeq ($(TARGET_CPUONLY),1)
_d16r_defs += -dTARGET_CPUONLY=1
endif
ifeq ($(TARGET_EXTLIB),1)
_d16r_defs += -dTARGET_EXTLIB=1
endif
ifeq ($(TARGET_DEBUG),1)
_d16r_defs += -dTARGET_DEBUG=1
endif

WLINKFLAGS=
WCCFLAGS=-e=2 -zq -m$(W_MMODE) $(W_DEBUG) -bt=dos -oilrtfm -wx -$(W_CPULEVEL) $(_d16r_defs) -q -fr=nul
WASMFLAGS=-e=2 -zq -m$(W_MMODE) $(W_DEBUG) -bt=dos -wx -$(W_CPULEVEL) $(_d16r_defs) -q
NASMFLAGS=-DTARGET_MSDOS=1 -DTARGET_BITS=16 -DTARGET_REALMODE=1 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -DDEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL)
NASMFORMAT=obj
WLINK_SYSTEM=dos

# DOS *IS* a console OS, flags are the same
WCCFLAGS_CONSOLE=$(WCCFLAGS)
WASMFLAGS_CONSOLE=$(WASMFLAGS)
NASMFLAGS_CONSOLE=$(NASMFLAGS)
WLINKFLAGS_CONSOLE=$(WLINKFLAGS)
WLINK_SYSTEM_CONSOLE=$(WLINK_SYSTEM)

