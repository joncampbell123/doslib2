# Windows 16-bit real mode target

WCC=env $(WATENV) $(OWCC)
WCL=env $(WATENV) $(OWCL)
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
TARGET_WINDOWS_WIN16=1
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
_win16r_t1=$(subst 86,,$(patsubst win16r/%,%,$(target_subdir)))
_win16r_t=$(subst 31_,,$(subst 30_,,$(subst 20_,,$(subst 10_,,$(_win16r_t1)))))

ifeq ($(findstring 10,$(_win16r_t1)),10)
  TARGET_WINDOWS_VERSION=10
endif
ifeq ($(findstring 20,$(_win16r_t1)),20)
  TARGET_WINDOWS_VERSION=20
endif
ifeq ($(findstring 30,$(_win16r_t1)),30)
  TARGET_WINDOWS_VERSION=30
endif
ifeq ($(findstring 31,$(_win16r_t1)),31)
  TARGET_WINDOWS_VERSION=31
endif

ifeq ($(findstring 0,$(_win16r_t)),0)
  W_CPULEVEL=0
endif
ifeq ($(findstring 2,$(_win16r_t)),2)
  W_CPULEVEL=2
endif
ifeq ($(findstring 3,$(_win16r_t)),3)
  W_CPULEVEL=3
endif
ifeq ($(findstring 4,$(_win16r_t)),4)
  W_CPULEVEL=4
endif
ifeq ($(findstring 5,$(_win16r_t)),5)
  W_CPULEVEL=5
endif
ifeq ($(findstring 6,$(_win16r_t)),6)
  W_CPULEVEL=6
endif

ifeq ($(findstring c,$(_win16r_t)),c)
  W_MMODE=c
endif
ifeq ($(findstring s,$(_win16r_t)),s)
  W_MMODE=s
endif
ifeq ($(findstring m,$(_win16r_t)),m)
  W_MMODE=m
endif
ifeq ($(findstring l,$(_win16r_t)),l)
  W_MMODE=l
endif
ifeq ($(findstring h,$(_win16r_t)),h)
  W_MMODE=h
endif
ifeq ($(findstring f,$(_win16r_t)),f)
  W_MMODE=f
endif

ifeq ($(findstring o,$(_win16r_t)),o)
TARGET_CPUONLY=1
endif

ifeq ($(findstring x,$(_win16r_t)),x)
TARGET_EXTLIB=1
endif

ifeq ($(findstring d,$(_win16r_t)),d)
TARGET_DEBUG=1
W_DEBUG=-d3
endif

# compiler flags
_win16r_defs = -dTARGET_WINDOWS=1 -dTARGET_WINDOWS_WIN16=1 -dTARGET_BITS=16 -dTARGET_REALMODE=1 -dTARGET_CPU=$(W_CPULEVEL) -dTARGET_WINDOWS_GUI=1 -d_WINDOWS_16_=1
ifeq ($(TARGET_CPUONLY),1)
_win16r_defs += -dTARGET_CPUONLY=1
endif
ifeq ($(TARGET_EXTLIB),1)
_win16r_defs += -dTARGET_EXTLIB=1
endif
ifeq ($(TARGET_DEBUG),1)
_win16r_defs += -dTARGET_DEBUG=1
endif
ifneq ($(TARGET_WINDOWS_VERSION),)
_win16r_defs += -dTARGET_WINDOWS_VERSION=$(TARGET_WINDOWS_VERSION)
endif

WLINKFLAGS=
ifeq ($(TARGET_WINDOWS_VERSION),31)
WRCFLAGS=-q -r -31 
else
WRCFLAGS=-q -r -30
endif
WCCFLAGS=-e=2 -zq -m$(W_MMODE) $(W_DEBUG) -bt=windows -oilrtfm -wx -$(W_CPULEVEL) $(_win16r_defs) -q -fr=nul
WASMFLAGS=-e=2 -zq -m$(W_MMODE) $(W_DEBUG) -bt=windows -wx -$(W_CPULEVEL) $(_win16r_defs) -q
NASMFLAGS=-DTARGET_WINDOWS=1 -DTARGET_WINDOWS_GUI=1 -DTARGET_WINDOWS_WIN16=1 -DTARGET_BITS=16 -DTARGET_REALMODE=1 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -DDEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL) -DTARGET_WINDOWS_VERSION=$(TARGET_WINDOWS_VERSION)
WLINK_SYSTEM=windows
WLINKFLAGS=option stack=4096 option heapsize=512
WLINK_SEGMENTS=segment TYPE CODE MOVEABLE DISCARDABLE LOADONCALL segment TYPE DATA MOVEABLE LOADONCALL

# DOS *IS* a console OS, flags are the same (TODO: Copy params above)
WCCFLAGS_CONSOLE=$(WCCFLAGS)
WASMFLAGS_CONSOLE=$(WASMFLAGS)
NASMFLAGS_CONSOLE=$(NASMFLAGS)
WLINKFLAGS_CONSOLE=$(WLINKFLAGS)
WLINK_SYSTEM_CONSOLE=$(WLINK_SYSTEM)

# UTILITY TO SET WIN16 NE IMAGE VERSION
ifeq ($(W_CPULEVEL),0)
WIN16_NE_SETVER_CPU=-progflag +8086
endif
ifeq ($(W_CPULEVEL),2)
WIN16_NE_SETVER_CPU=-progflag +286
endif
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

ifeq ($(TARGET_WINDOWS_VERSION),31)
WIN16_NE_SETVER=$(abs_top_builddir)/util/chgnever.pl -progflag -protonly $(WIN16_NE_SETVER_CPU) 3.1
endif
ifeq ($(TARGET_WINDOWS_VERSION),30)
WIN16_NE_SETVER=$(abs_top_builddir)/util/chgnever.pl -progflag -protonly $(WIN16_NE_SETVER_CPU) 3.0
endif
ifeq ($(TARGET_WINDOWS_VERSION),20)
WIN16_NE_SETVER=$(abs_top_builddir)/util/chgnever.pl -progflag -protonly $(WIN16_NE_SETVER_CPU) -apptype 0 2.0
endif
ifeq ($(TARGET_WINDOWS_VERSION),10)
WIN16_NE_SETVER=$(abs_top_builddir)/util/chgnever.pl -progflag -protonly $(WIN16_NE_SETVER_CPU) -apptype 0 1.0
endif

