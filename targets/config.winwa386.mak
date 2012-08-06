# Windows 16-bit protected mode target

WCC=env $(WATENV) $(OWCC386)
WCL=env $(WATENV) $(OWCL386)
WRC=env $(WATENV) $(OWRC)
WLIB=env $(WATENV) $(OWLIB)
WLINK=env $(WATENV) $(OWLINK)
WBIND=env $(WATENV) $(OWBIND)
WSTRIP=env $(WATENV) $(OWSTRIP)
exe_suffix=.exe
obj_suffix=.obj
lib_suffix=.lib

WATENV += "INCLUDE=$(OPENWATCOM)/h;$(OPENWATCOM)/h/win"

# make flags
TARGET_WINDOWS=1
TARGET_WINDOWS_WIN386=1
TARGET_BITS=32
TARGET_PROTMODE=1

# target-dependent
TARGET_EXTLIB=0
TARGET_CPUONLY=0
W_CPULEVEL=0
W_MMODE=l

TARGET_DEBUG=0
W_DEBUG=-d0 -s

# eval the targetdir
_win386_t1=$(subst 86,,$(patsubst win386/%,%,$(target_subdir)))
_win386_t=$(subst 31_,,$(subst 30_,,$(subst 20_,,$(subst 10_,,$(_win386_t1)))))

ifeq ($(findstring 30,$(_win386_t1)),30)
  TARGET_WINDOWS_VERSION=30
endif
ifeq ($(findstring 31,$(_win386_t1)),31)
  TARGET_WINDOWS_VERSION=31
endif

ifeq ($(findstring 3,$(_win386_t)),3)
  W_CPULEVEL=3
endif
ifeq ($(findstring 4,$(_win386_t)),4)
  W_CPULEVEL=4
endif
ifeq ($(findstring 5,$(_win386_t)),5)
  W_CPULEVEL=5
endif
ifeq ($(findstring 6,$(_win386_t)),6)
  W_CPULEVEL=6
endif

ifeq ($(findstring c,$(_win386_t)),c)
  W_MMODE=c
endif
ifeq ($(findstring s,$(_win386_t)),s)
  W_MMODE=s
endif
ifeq ($(findstring m,$(_win386_t)),m)
  W_MMODE=m
endif
ifeq ($(findstring l,$(_win386_t)),l)
  W_MMODE=l
endif
ifeq ($(findstring h,$(_win386_t)),h)
  W_MMODE=h
endif
ifeq ($(findstring f,$(_win386_t)),f)
  W_MMODE=f
endif

ifeq ($(findstring o,$(_win386_t)),o)
TARGET_CPUONLY=1
endif

ifeq ($(findstring x,$(_win386_t)),x)
TARGET_EXTLIB=1
endif

ifeq ($(findstring d,$(_win386_t)),d)
TARGET_DEBUG=1
W_DEBUG=-d3
endif

# compiler flags
_win386_defs = -dTARGET_WINDOWS=1 -dTARGET_WINDOWS_WIN386=1 -dTARGET_BITS=32 -dTARGET_PROTMODE=1 -dTARGET_CPU=$(W_CPULEVEL) -dTARGET_WINDOWS_GUI=1
ifeq ($(TARGET_CPUONLY),1)
_win386_defs += -dTARGET_CPUONLY=1
endif
ifeq ($(TARGET_EXTLIB),1)
_win386_defs += -dTARGET_EXTLIB=1
endif
ifeq ($(TARGET_DEBUG),1)
_win386_defs += -dTARGET_DEBUG=1
endif
ifneq ($(TARGET_WINDOWS_VERSION),)
_win386_defs += -dTARGET_WINDOWS_VERSION=$(TARGET_WINDOWS_VERSION)
endif

WLINKFLAGS=
ifeq ($(TARGET_WINDOWS_VERSION),31)
WRCFLAGS=-q -r -31 
else
WRCFLAGS=-q -r -30
endif
WCCFLAGS=-e=2 -zq -m$(W_MMODE) $(W_DEBUG) -bt=windows -oilrtfm -wx -$(W_CPULEVEL) $(_win386_defs) -q -fr=nul
WASMFLAGS=-e=2 -zq -m$(W_MMODE) $(W_DEBUG) -bt=windows -wx -$(W_CPULEVEL) $(_win386_defs) -q
NASMFLAGS=-DTARGET_WINDOWS=1 -DTARGET_WINDOWS_GUI=1 -DTARGET_WINDOWS_WIN386=1 -DTARGET_BITS=32 -DTARGET_PROTMODE=1 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -DDEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL) -DTARGET_WINDOWS_VERSION=$(TARGET_WINDOWS_VERSION)
WLINK_SYSTEM=win386
WLINKFLAGS=
WLINK_SEGMENTS=

# DOS *IS* a console OS, flags are the same
WCCFLAGS_CONSOLE=$(WCCFLAGS)
WASMFLAGS_CONSOLE=$(WASMFLAGS)
NASMFLAGS_CONSOLE=$(NASMFLAGS)
WLINKFLAGS_CONSOLE=$(WLINKFLAGS)
WLINK_SYSTEM_CONSOLE=$(WLINK_SYSTEM)

# UTILITY TO SET WIN16 NE IMAGE VERSION
ifeq ($(W_CPULEVEL),3)
WIN16_NE_SETVER_CPU=-progflag +386
endif
ifeq ($(W_CPULEVEL),4)
WIN16_NE_SETVER_CPU=-progflag +486
endif
ifeq ($(W_CPULEVEL),5)
WIN16_NE_SETVER_CPU=-progflag +486
endif
ifeq ($(W_CPULEVEL),6)
WIN16_NE_SETVER_CPU=-progflag +486
endif

# Despite internally being 32-bit the EXE on the outside is still 16-bit NE
ifeq ($(TARGET_WINDOWS_VERSION),31)
WIN16_NE_SETVER=$(abs_top_builddir)/util/chgnever.pl -progflag +protonly $(WIN16_NE_SETVER_CPU) 3.1
endif
ifeq ($(TARGET_WINDOWS_VERSION),30)
WIN16_NE_SETVER=$(abs_top_builddir)/util/chgnever.pl -progflag +protonly $(WIN16_NE_SETVER_CPU) 3.0
endif

# Watcom actually emits a .rex file (signature MQ). to make it run we have to bind it to their win386 stub
WIN386_EXE_TO_REX_IF_REX=$(abs_top_builddir)/util/win386rexname.pl

