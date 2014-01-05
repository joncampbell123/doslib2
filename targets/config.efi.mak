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
W_CPULEVEL=6
EFI_LD_OBJCOPY=objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym  -j .rel -j .rela -j .reloc --target=efi-app-ia32
EFI_LD_SO=ld -nostdlib -znocombreloc -T /usr/lib/elf_ia32_efi.lds -shared -Bsymbolic -L /usr/lib/gnuefi -L /usr/lib /usr/lib/crt0-efi-ia32.o
EFI_CC=gcc
EFI_IA32_CFLAGS += -DTARGET_BITS=32 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -DDEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL) -I/usr/include/efi -I/usr/include/efi/ia32 -I/usr/include/efi/protocol -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -Wall -march=i686
NASMFLAGS += -DTARGET_BITS=32
NASMFORMAT=elf32
endif
ifeq ($(linux_host_mach),x86_64)
W_CPULEVEL=6
EFI_IA32_CFLAGS += -DTARGET_BITS=64 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -DDEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL)
NASMFLAGS += -DTARGET_BITS=64
NASMFORMAT=elf64
endif

CFLAGS += $(EFI_IA32_CFLAGS)
CPPFLAGS += $(EFI_IA32_CFLAGS)
CXXFLAGS += $(EFI_IA32_CFLAGS)

CFLAGS_CONSOLE += $(EFI_IA32_CFLAGS)
CPPFLAGS_CONSOLE += $(EFI_IA32_CFLAGS)
CXXFLAGS_CONSOLE += $(EFI_IA32_CFLAGS)

