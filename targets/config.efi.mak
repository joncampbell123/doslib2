exe_suffix=
obj_suffix=.o
lib_suffix=.a

TARGET_DEBUG=0
TARGET_EXTLIB=0
TARGET_CPUONLY=0
W_MMODE=f

NASMFLAGS=-DTARGET_EFI=1 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -DDEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL)

EFI_IA32_CFLAGS = -DTARGET_EFI=1 -DTARGET_PROTMODE=1
ifeq ($(linux_host_mach),i686)
# This hardcoded path will be removed once someone provides a RELIABLE way for GCC to tell me where this is!
LD_LIBGCC=/usr/lib/gcc/i686-pc-linux-gnu/4.8.2/libgcc.a

# NTS: The linker will silently fail to error this condition, but compiling without -lefi and -lgnuefi makes an executable that crashes on startup.
#      Also, gnu-efi has it's own #define DEBUG() macro that conflicts with ours.
#      Also, unlike the examples given on the 'net we must also copy the .plt section.
#      Also, we have the EFI libs referenced twice to avoid brain-dead GNU linker problems with synbols
#      Also, you must use -Bsymbolic or else the linker will rely on .plt type relocations which of course don't work in the EFI world.
#      Also.... when is the GNU linker going to directly support generating EFI binaries instead of requiring us to do this objcopy hack-fuckery?
W_CPULEVEL=6
EFI_LD_OBJCOPY=objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym  -j .rel -j .rela -j .reloc --target=efi-app-ia32
EFI_LD_SO=ld
EFI_IA32_LDFLAGS=--no-undefined -shared -static -Bsymbolic -nostdlib -znow -znocombreloc -L/usr/lib -T /usr/lib/elf_ia32_efi.lds /usr/lib/crt0-efi-ia32.o -lgnuefi -lefi $(LD_LIBGCC)
EFI_IA32_LDFLAGS_POST=-lgnuefi -lefi $(LD_LIBGCC)
EFI_CC=gcc
EFI_IA32_CFLAGS += -DTARGET_BITS=32 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -D_DEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL) -I/usr/include/efi -I/usr/include/efi/ia32 -I/usr/include/efi/protocol -fno-stack-protector -fshort-wchar -mno-red-zone -Wall -march=i686 -fpic -I$(abs_top_builddir)
NASMFLAGS += -DTARGET_BITS=32
NASMFORMAT=elf32

CFLAGS += $(EFI_IA32_CFLAGS)
CPPFLAGS += $(EFI_IA32_CFLAGS)
CXXFLAGS += $(EFI_IA32_CFLAGS)

LDFLAGS += $(EFI_IA32_LDFLAGS)
LDFLAGS_POST += $(EFI_IA32_LDFLAGS_POST)

CFLAGS_CONSOLE += $(EFI_IA32_CFLAGS)
CPPFLAGS_CONSOLE += $(EFI_IA32_CFLAGS)
CXXFLAGS_CONSOLE += $(EFI_IA32_CFLAGS)
endif
ifeq ($(linux_host_mach),x86_64)
W_CPULEVEL=6
EFI_IA32_CFLAGS += -DTARGET_BITS=64 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -D_DEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL)
NASMFLAGS += -DTARGET_BITS=64
NASMFORMAT=elf64
endif

