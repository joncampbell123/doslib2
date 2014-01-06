exe_suffix=
obj_suffix=.o
lib_suffix=.a

TARGET_DEBUG=0
TARGET_EXTLIB=0
TARGET_CPUONLY=0
W_MMODE=f

NASMFLAGS=-DTARGET_EFI=1 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -DDEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL)

EFI_IA32_CFLAGS = -DTARGET_EFI=1 -DTARGET_PROTMODE=1
EFI_X64_CFLAGS = -DTARGET_EFI=1 -DTARGET_PROTMODE=1

ifeq ($(target_subdir),efi/ia32)
# We need GCC to tell us where libgcc.a is
LD_LIBGCC=$(shell /usr/i386-pc-linux-gnu/bin/i386-pc-linux-gnu-gcc --print-libgcc-file-name)

# NTS: The linker will silently fail to error this condition, but compiling without -lefi and -lgnuefi makes an executable that crashes on startup.
#      Also, gnu-efi has it's own #define DEBUG() macro that conflicts with ours.
#      Also, we have the EFI libs referenced twice to avoid brain-dead GNU linker problems with synbols
#      Also, you must use -Bsymbolic or else the linker will rely on .plt type relocations which of course don't work in the EFI world.
#      Also.... when is the GNU linker going to directly support generating EFI binaries instead of requiring us to do this objcopy hack-fuckery?
W_CPULEVEL=6
EFI_LD_AR=/usr/i386-pc-linux-gnu/bin/i386-pc-linux-gnu-ar
EFI_LD_OBJCOPY=/usr/i386-pc-linux-gnu/bin/i386-pc-linux-gnu-objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym  -j .rel -j .rela -j .reloc --target=efi-app-ia32
EFI_LD_SO=/usr/i386-pc-linux-gnu/bin/i386-pc-linux-gnu-ld
EFI_IA32_LDFLAGS=--no-undefined -shared -static -Bsymbolic -nostdlib -znow -znocombreloc -L/usr/gnu-efi-ia32/lib -T /usr/gnu-efi-ia32/lib/elf_ia32_efi.lds /usr/gnu-efi-ia32/lib/crt0-efi-ia32.o -lgnuefi -lefi $(LD_LIBGCC)
EFI_IA32_LDFLAGS_POST=-lgnuefi -lefi $(LD_LIBGCC)
EFI_CC=/usr/i386-pc-linux-gnu/bin/i386-pc-linux-gnu-gcc
EFI_IA32_CFLAGS += -DTARGET_BITS=32 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -D_DEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL) -I/usr/gnu-efi-ia32/include/efi -I/usr/gnu-efi-ia32/include/efi/ia32 -I/usr/gnu-efi-ia32/include/efi/protocol -fno-stack-protector -fshort-wchar -mno-red-zone -Wall -march=i686 -fpic -I$(abs_top_builddir)
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

ifeq ($(target_subdir),efi/x64)
# We need GCC to tell us where libgcc.a is
LD_LIBGCC=$(shell /usr/x86_64-pc-linux-gnu/bin/x86_64-pc-linux-gnu-gcc --print-libgcc-file-name)

# NTS: The linker will silently fail to error this condition, but compiling without -lefi and -lgnuefi makes an executable that crashes on startup.
#      Also, gnu-efi has it's own #define DEBUG() macro that conflicts with ours.
#      Also, we have the EFI libs referenced twice to avoid brain-dead GNU linker problems with synbols
#      Also, you must use -Bsymbolic or else the linker will rely on .plt type relocations which of course don't work in the EFI world.
#      Also.... when is the GNU linker going to directly support generating EFI binaries instead of requiring us to do this objcopy hack-fuckery?
W_CPULEVEL=6
EFI_LD_AR=/usr/x86_64-pc-linux-gnu/bin/x86_64-pc-linux-gnu-ar
EFI_LD_OBJCOPY=/usr/x86_64-pc-linux-gnu/bin/x86_64-pc-linux-gnu-objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym  -j .rel -j .rela -j .reloc --target=efi-app-x86_64
EFI_LD_SO=/usr/x86_64-pc-linux-gnu/bin/x86_64-pc-linux-gnu-ld
EFI_X64_LDFLAGS=--no-undefined -shared -static -Bsymbolic -nostdlib -znow -znocombreloc -L/usr/gnu-efi-x86_64/lib -T /usr/gnu-efi-x86_64/lib/elf_x86_64_efi.lds /usr/gnu-efi-x86_64/lib/crt0-efi-x86_64.o -lgnuefi -lefi $(LD_LIBGCC)
EFI_X64_LDFLAGS_POST=-lgnuefi -lefi $(LD_LIBGCC)
EFI_CC=/usr/x86_64-pc-linux-gnu/bin/x86_64-pc-linux-gnu-gcc
EFI_X64_CFLAGS += -DTARGET_BITS=64 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -D_DEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL) -I/usr/gnu-efi-x86_64/include/efi -I/usr/gnu-efi-x86_64/include/efi/x86_64 -I/usr/gnu-efi-x86_64/include/efi/protocol -fno-stack-protector -fshort-wchar -mno-red-zone -Wall -march=x86-64 -fpic -I$(abs_top_builddir) "-DEFIAPI=__attribute__((ms_abi))" -DEFI_FUNCTION_WRAPPER
NASMFLAGS += -DTARGET_BITS=64
NASMFORMAT=elf64

CFLAGS += $(EFI_X64_CFLAGS)
CPPFLAGS += $(EFI_X64_CFLAGS)
CXXFLAGS += $(EFI_X64_CFLAGS)

LDFLAGS += $(EFI_X64_LDFLAGS)
LDFLAGS_POST += $(EFI_X64_LDFLAGS_POST)

CFLAGS_CONSOLE += $(EFI_X64_CFLAGS)
CPPFLAGS_CONSOLE += $(EFI_X64_CFLAGS)
CXXFLAGS_CONSOLE += $(EFI_X64_CFLAGS)
endif

