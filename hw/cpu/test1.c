#if defined(TARGET_WINDOWS)
# include <windows.h>
# include <windows/w32imphk/compat.h>
# include <windows/apihelp.h>
# if defined(TARGET_WINDOWS_GUI) && !defined(TARGET_WINDOWS_CONSOLE)
#  define WINFCON_ENABLE 1
#  define WINFCON_STOCK_WIN_MAIN 1
#  include <windows/winfcon/winfcon.h>
# endif
#endif

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

/* useful macros */
#define cpp_stringify_l2(x) #x
#define cpp_stringify(x) cpp_stringify_l2(x)

/* useful FAR definition */
#ifndef FAR
# if TARGET_MSDOS == 16
#  if defined(__COMPACT__) || defined(__LARGE__) || defined(__HUGE__)
#   define FAR __far
#  else
#   define FAR
#  endif
# else
#  define FAR
# endif
#endif /* FAR */

signed char cpu_basic_level = -1;
signed char cpu_basic_fpu_level = -1;
unsigned short cpu_flags = 0;

#pragma pack(push,1)
struct cpu_cpuid_generic_block {
	uint32_t		a,b,c,d;		/* EAX EBX ECX EDX */
};

struct cpu_cpuid_00000000_id_info {
	uint32_t		cpuid_max;		/* EAX */
	uint32_t		id_1,id_3,id_2;		/* EBX ECX EDX. id_1 id_2 id_3 becomes EBX EDX ECX. do NOT change member order */
};

/* see what I'm doing here? :)
 * it avoids the need for redunant assembly language when using CPUID
 * while bringing meaning to each field */
union cpu_cpuid_00000000_id_union {
	struct cpu_cpuid_generic_block		g;
	struct cpu_cpuid_00000000_id_info	i;
};

struct cpu_cpuid_00000001_id_features {
	/* EAX */
	uint16_t		stepping:4;		/* bits 0-3 */
	uint16_t		model:4;		/* bits 4-7 */
	uint16_t		family:4;		/* bits 8-11 */
	uint16_t		processor_type:2;	/* bits 12-13 */
	uint16_t		__undef_eax_15_14:2;	/* bits 14-15 */
	uint16_t		extended_model:4;	/* bits 16-19 */
	uint16_t		extended_family:8;	/* bits 20-27 */
	uint16_t		__undef_eax_31_28:4;	/* bits 28-31 */
	/* EBX */
	uint32_t		__undef_ebx;		/* bits 0-31 */
	/* ECX */
	uint16_t		c_sse3:1;		/* bit 0: SSE3, prescott new instructions */
	uint16_t		c_pclmulqdq:1;		/* bit 1: PCLMULQDQ */
	uint16_t		c_dtes64:1;		/* bit 2: dtes64 debug store (EDX bit 21) */
	uint16_t		c_monitor:1;		/* bit 3: MONITOR and MWAIT */
	uint16_t		c_ds_cpl:1;		/* bit 4: CPL qualified debug store */
	uint16_t		c_vmx:1;		/* bit 5: Virtual Machine eXtensions */
	uint16_t		c_smx:1;		/* bit 6: Safer Mode eXtensions */
	uint16_t		c_est:1;		/* bit 7: Enhanced SpeedStep */
	uint16_t		c_tm2:1;		/* bit 8: Thermal Monitor 2 */
	uint16_t		c_ssse3:1;		/* bit 9: Supplemental SSE3 instructions */
	uint16_t		c_cid:1;		/* bit 10: Context ID */
	uint16_t		_c_reserved_11:1;	/* bit 11 */
	uint16_t		c_fma:1;		/* bit 12: Fused multiply-add (FMA3) */
	uint16_t		c_cx16:1;		/* bit 13: CMPXCHG16B */
	uint16_t		c_xtpr:1;		/* bit 14: Can disable sending task priority messages */
	uint16_t		c_pdcm:1;		/* bit 15: Perfmon & debug capability */
	uint16_t		_c_reserved_16:1;	/* bit 16 */
	uint16_t		c_pcid:1;		/* bit 17: Process context identifiers (CR4 bit 17) */
	uint16_t		c_dca:1;		/* bit 18: Direct cache access for DMA writes */
	uint16_t		c_sse4_1:1;		/* bit 19: SSE4.1 instructions */
	uint16_t		c_sse4_2:1;		/* bit 20: SSE4.2 instructions */
	uint16_t		c_x2apic:1;		/* bit 21: x2APIC support */
	uint16_t		c_movbe:1;		/* bit 22: MOVBE instruction */
	uint16_t		c_popcnt:1;		/* bit 23: POPCNT instruction */
	uint16_t		c_tscdeadline:1;	/* bit 24: APIC supports one-shot operation using a TSC deadline value */
	uint16_t		c_aes:1;		/* bit 25: AES instruction set */
	uint16_t		c_xsave:1;		/* bit 26: XSAVE, XRESTOR, XSETBV, XGETBV */
	uint16_t		c_osxsave:1;		/* bit 27: XSAVE enabled by OS */
	uint16_t		c_avx:1;		/* bit 28: Advanced Vector Extensions */
	uint16_t		c_f16c:1;		/* bit 29: CVT16 instruction set (half precision) floating point support */
	uint16_t		c_rdrnd:1;		/* bit 30: RDRAND (on-chip random number generator) support */
	uint16_t		c_hypervisor:1;		/* bit 31: Running on a hypervisor (0 on a real CPU) */
	/* EDX */
	uint16_t		d_fpu:1;		/* bit 0: Onboard x87 FPU */
	uint16_t		d_vme:1;		/* bit 1: Virtual mode extensions (VIF) */
	uint16_t		d_de:1;			/* bit 2: Debugging extensions (CR4 bit 3) */
	uint16_t		d_pse:1;		/* bit 3: Page size extensions */
	uint16_t		d_tsc:1;		/* bit 4: Time stamp counter */
	uint16_t		d_msr:1;		/* bit 5: Model-specific registers */
	uint16_t		d_pae:1;		/* bit 6: Physical Address Extension */
	uint16_t		d_mce:1;		/* bit 7: Machine Check Exception */
	uint16_t		d_cx8:1;		/* bit 8: CMPXCHG8 */
	uint16_t		d_apic:1;		/* bit 9: Onboard APIC */
	uint16_t		_d_reserved_10:1;	/* bit 10 */
	uint16_t		d_sep:1;		/* bit 11: SYSENTER and SYSEXIT */
	uint16_t		d_mtrr:1;		/* bit 12: Memory Type Range Registers */
	uint16_t		d_pge:1;		/* bit 13: Page Global Enable bit in CR4 */
	uint16_t		d_mca:1;		/* bit 14: Machine check architecture */
	uint16_t		d_cmov:1;		/* bit 15: CMOV and FCMOV instructions */
	uint16_t		d_pat:1;		/* bit 16: Page Attribute Table */
	uint16_t		d_pse36:1;		/* bit 17: 36-bit page table extension */
	uint16_t		d_pn:1;			/* bit 18: Processor serial number */
	uint16_t		d_clflush:1;		/* bit 19: CLFLUSH (SSE2 */
	uint16_t		_d_reserved_20:1;	/* bit 20 */
	uint16_t		d_dts:1;		/* bit 21: Debug store: save trace of executed jumps */
	uint16_t		d_acpi:1;		/* bit 22: Onboard thermal control MSRs for ACPI */
	uint16_t		d_mmx:1;		/* bit 23: MMX instructions */
	uint16_t		d_fxsr:1;		/* bit 24: FXSAVE, FXRESTOR instructions CR4 bit 9 */
	uint16_t		d_sse:1;		/* bit 25: SSE instructions */
	uint16_t		d_sse2:1;		/* bit 26: SSE2 instructions */
	uint16_t		d_ss:1;			/* bit 27: CPU supports Self Snoop */
	uint16_t		d_ht:1;			/* bit 28: Hyper threading */
	uint16_t		d_tm:1;			/* bit 29: Thermal monitoring automatically limits temp */
	uint16_t		d_ia64:1;		/* bit 30: IA64 processor emulating x86 */
	uint16_t		d_pbe:1;		/* bit 31: Pending Break Enable (PBE# pin) wakeup support */
};

union cpu_cpuid_00000001_id_union {
	struct cpu_cpuid_generic_block		g;
	struct cpu_cpuid_00000001_id_features	f;
};

struct cpu_cpuid_80000000_id_info {
	uint32_t		cpuid_max;		/* EAX */
	uint32_t		b,c,d;			/* other regs... unknown what they contain */
};

union cpu_cpuid_80000000_id_union {
	struct cpu_cpuid_generic_block		g;
	struct cpu_cpuid_80000000_id_info	i;
};

struct cpu_cpuid_80000001_id_features {
	/* EAX */
	uint16_t		stepping:4;		/* bits 0-3 */
	uint16_t		model:4;		/* bits 4-7 */
	uint16_t		family:4;		/* bits 8-11 */
	uint16_t		processor_type:2;	/* bits 12-13 */
	uint16_t		__undef_eax_15_14:2;	/* bits 14-15 */
	uint16_t		extended_model:4;	/* bits 16-19 */
	uint16_t		extended_family:8;	/* bits 20-27 */
	uint16_t		__undef_eax_31_28:4;	/* bits 28-31 */
	/* EBX */
	uint32_t		__undef_ebx;		/* bits 0-31 */
	/* ECX */
	uint16_t		c_ahf64:1;		/* bit 0: LAHF + SAHF available in amd64 */
	uint16_t		c_cmp:1;		/* bit 1: HTT=1 indicates HTT (0) or CMP (1) (?what does that mean?) */
	uint16_t		c_svm:1;		/* bit 2: EFER.SVME, VMRUN, VMMCALL, VMLOAD, VMSAVE, STGI, and CLGI, SKINIT, INVLPGA */
	uint16_t		c_eas:1;		/* bit 3: Extended APIC space */
	uint16_t		c_cr8d:1;		/* bit 4: MOV from/to CR8D using LOCK MOV from/to CR0 */
	uint16_t		c_lzcnt:1;		/* bit 5: LZCNT */
	uint16_t		c_sse4a:1;		/* bit 6: SSE4A */
	uint16_t		c_msse:1;		/* bit 7: misaligned SSE, MXCSR.MM */
	uint16_t		c_3dnow_prefetch:1;	/* bit 8: PREFETCH and PREFETCHW 3DNow! */
	uint16_t		c_osvw:1;		/* bit 9: OS visible workaround (?) */
	uint16_t		c_ibs:1;		/* bit 10: Instruction based sampling */
	uint16_t		c_xop:1;		/* bit 11: XOP instructions */
	uint16_t		c_skinit:1;		/* bit 12: SKINIT, STGI, DEV */
	uint16_t		c_wdt:1;		/* bit 13: Watchdog timer */
	uint16_t		_c_reserved_14:1;	/* bit 14 */
	uint16_t		c_lwp:1;		/* bit 15: LWP (?) */
	uint16_t		c_fma4:1;		/* bit 16: FMA4 */
	uint16_t		c_tce:1;		/* bit 17: Translation cache extension */
	uint16_t		_c_reserved_18:1;	/* bit 18 */
	uint16_t		c_nodeid:1;		/* bit 19: Node ID in MSR 0xC001100C */
	uint16_t		_c_reserved_20:1;	/* bit 20 */
	uint16_t		c_tbm:1;		/* bit 21: TBM (?) */
	uint16_t		c_topx:1;		/* bit 22: Topology extensions: extended levels 0x8000001D and 0x8000001E */
	uint16_t		c_pcx_core:1;		/* bit 23: core perf counter extensions */
	uint16_t		c_pcx_nb:1;		/* bit 24: nb perf counter extensions */
	uint16_t		_c_reserved_25:1;	/* bit 25 */
	uint16_t		_c_reserved_26:1;	/* bit 26 */
	uint16_t		_c_reserved_27:1;	/* bit 27 */
	uint16_t		_c_reserved_28:1;	/* bit 28 */
	uint16_t		_c_reserved_29:1;	/* bit 29 */
	uint16_t		_c_reserved_30:1;	/* bit 30 */
	uint16_t		_c_reserved_31:1;	/* bit 31 */
	/* EDX */
	uint16_t		d_fpu:1;		/* bit 0: Onboard x87 FPU */
	uint16_t		d_vme:1;		/* bit 1: Virtual mode extensions (VIF) */
	uint16_t		d_de:1;			/* bit 2: Debugging extensions (CR4 bit 3) */
	uint16_t		d_pse:1;		/* bit 3: Page size extensions */
	uint16_t		d_tsc:1;		/* bit 4: Time stamp counter */
	uint16_t		d_msr:1;		/* bit 5: Model-specific registers */
	uint16_t		d_pae:1;		/* bit 6: Physical Address Extension */
	uint16_t		d_mce:1;		/* bit 7: Machine Check Exception */
	uint16_t		d_cx8:1;		/* bit 8: CMPXCHG8 */
	uint16_t		d_apic:1;		/* bit 9: Onboard APIC */
	uint16_t		_d_reserved_10:1;	/* bit 10 */
	uint16_t		d_sep:1;		/* bit 11: SYSENTER and SYSEXIT */
	uint16_t		d_mtrr:1;		/* bit 12: Memory Type Range Registers */
	uint16_t		d_pge:1;		/* bit 13: Page Global Enable bit in CR4 */
	uint16_t		d_mca:1;		/* bit 14: Machine check architecture */
	uint16_t		d_cmov:1;		/* bit 15: CMOV and FCMOV instructions */
	uint16_t		d_pat:1;		/* bit 16: Page Attribute Table */
	uint16_t		d_pse36:1;		/* bit 17: 36-bit page table extension */
	uint16_t		_d_reserved_18:1;	/* bit 18 */
	uint16_t		d_mp:1;			/* bit 19: MP capable */
	uint16_t		d_nx:1;			/* bit 20: NX (No execute) */
	uint16_t		_d_reserved_21:1;	/* bit 21 */
	uint16_t		d_mmxplus:1;		/* bit 22: AMD MMX+ */
	uint16_t		d_mmx:1;		/* bit 23: MMX instructions */
	uint16_t		d_fxsr:1;		/* bit 24: FXSAVE, FXRESTOR instructions CR4 bit 9 or Cyrix MMX+ */
	uint16_t		d_ffxsr:1;		/* bit 25: FFXSR */
	uint16_t		d_pg1g:1;		/* bit 26: PG1G (1GB pages?) */
	uint16_t		d_tscp:1;		/* bit 27: TSC, TSC_AUX, RDTSCP, CR4.TSD */
	uint16_t		_d_reserved_28:1;	/* bit 28 */
	uint16_t		d_lm:1;			/* bit 29: AMD64 long mode */
	uint16_t		d_3dnowplus:1;		/* bit 30: 3DNow!+ */
	uint16_t		d_3dnow:1;		/* bit 31: 3DNow! */
};

union cpu_cpuid_80000001_id_union {
	struct cpu_cpuid_generic_block		g;
	struct cpu_cpuid_80000001_id_features	f;
};

struct cpu_cpuid_info {
	union cpu_cpuid_00000000_id_union	e0;		/* CPUID 0x00000000 CPU identification */
	union cpu_cpuid_00000001_id_union	e1;		/* CPUID 0x00000001 CPU ID and features */
	union cpu_cpuid_80000000_id_union	e80000000;	/* CPUID 0x80000000 CPU ext. identification */
	union cpu_cpuid_80000001_id_union	e80000001;	/* CPUID 0x80000001 CPU ID and features */
	struct cpu_cpuid_generic_block		e80000002;	/* CPUID 0x80000002 CPU extended ID, first 1/3 of string */
	struct cpu_cpuid_generic_block		e80000003;	/* CPUID 0x80000003 CPU extended ID, first 2/3 of string */
	struct cpu_cpuid_generic_block		e80000004;	/* CPUID 0x80000004 CPU extended ID, first 3/3 of string */
	unsigned char				phys_addr_bits;	/* physical address bits supported by CPU */
	unsigned char				virt_addr_bits;	/* virtual address bits supported by CPU */
	unsigned char				guest_phys_addr_bits; /* guest physical address bits */
};
#pragma pack(pop)

/* FPU is present */
#define CPU_FLAG_FPU		0x01
/* CPU is running in virtual 8086 mode, not real mode */
#define CPU_FLAG_V86		0x02
/* CPU is running in protected mode */
#define CPU_FLAG_PROTMODE	0x04
/* CPU supports CPUID */
#define CPU_FLAG_CPUID		0x08

struct cpu_cpuid_info*		cpuid_info = NULL;

/* CPUID function. To avoid redundant asm blocks */
#if defined(__GNUC__)
# if defined(__i386__) /* Linux GCC + i386 */
static inline void do_cpuid(const uint32_t select,struct cpu_cpuid_generic_block *b) {
	__asm__ __volatile__ (	"cpuid"
				: "=a" (b->a), "=b" (b->b), "=c" (b->c), "=d" (b->d) /* outputs */
				: "a" (select), "b" (b->b), "c" (b->c), "d" (b->d) /* input */
				: /* clobber */);
}
# endif
#elif TARGET_BITS == 32
/* TODO: #ifdef to detect Watcom C */
/* TODO: How do we do this to ensure it's a function call not inline? */
void do_cpuid(const uint32_t select,struct cpu_cpuid_generic_block *b);
# pragma aux do_cpuid = \
	".586p" \
	"mov ebx,[esi+4]" \
	"mov ecx,[esi+8]" \
	"mov edx,[esi+12]" \
	"cpuid" \
	"mov [esi],eax" \
	"mov [esi+4],ebx" \
	"mov [esi+8],ecx" \
	"mov [esi+12],edx" \
	parm [eax] [esi] \
	modify [eax ebx ecx edx]
#elif TARGET_BITS == 16
void do_cpuid(const uint32_t select,struct cpu_cpuid_generic_block FAR *b) {
	__asm {
		.586p
# if defined(__LARGE__) || defined(__COMPACT__) || defined(__HUGE__)
		push	ds
# endif
		push	eax
		mov	eax,select
# if defined(__LARGE__) || defined(__COMPACT__) || defined(__HUGE__)
		lds	si,word ptr [b]
# else
		mov	si,word ptr [b]
# endif
		mov	ebx,[si+4]
		mov	ecx,[si+8]
		mov	edx,[si+12]
		cpuid
		mov	[si],eax
		mov	[si+4],ebx
		mov	[si+8],ecx
		mov	[si+12],edx
		pop	eax
# if defined(__LARGE__) || defined(__COMPACT__) || defined(__HUGE__)
		pop	ds
# endif
	}
}
#endif

/* CPU ID string buffer length expected: 12 bytes for 3 DWORDs plus ASCIIZ NUL */
#define CPU_ID_STRING_LENGTH 13
void cpu_copy_id_string(char *tmp/*must be CPU_ID_STRING_LENGTH or more*/,struct cpu_cpuid_00000000_id_info *i) {
	*((uint32_t*)(tmp+0)) = i->id_1;
	*((uint32_t*)(tmp+4)) = i->id_2;
	*((uint32_t*)(tmp+8)) = i->id_3;
	tmp[12] = 0;
}

/* extended CPU id string buffer length extended: 48 bytes for 4 x 3 DWORDs plus ASCIIZ NUL */
#define CPU_EXT_ID_STRING_LENGTH 49
char *cpu_copy_ext_id_string(char *tmp,struct cpu_cpuid_info *i) {
	unsigned int ii=0;

	*((uint32_t*)(tmp+0)) = i->e80000002.a;
	*((uint32_t*)(tmp+4)) = i->e80000002.b;
	*((uint32_t*)(tmp+8)) = i->e80000002.c;
	*((uint32_t*)(tmp+12)) = i->e80000002.d;

	*((uint32_t*)(tmp+16)) = i->e80000003.a;
	*((uint32_t*)(tmp+20)) = i->e80000003.b;
	*((uint32_t*)(tmp+24)) = i->e80000003.c;
	*((uint32_t*)(tmp+28)) = i->e80000003.d;

	*((uint32_t*)(tmp+32)) = i->e80000004.a;
	*((uint32_t*)(tmp+36)) = i->e80000004.b;
	*((uint32_t*)(tmp+40)) = i->e80000004.c;
	*((uint32_t*)(tmp+44)) = i->e80000004.d;

	tmp[48] = 0;
	while (ii < 48 && tmp[ii] == ' ') ii++;
	return tmp+ii;
}

static void probe_cpuid() {
	if (cpuid_info != NULL) return;

	cpuid_info = malloc(sizeof(*cpuid_info));
	if (cpuid_info == NULL) return;
	memset(cpuid_info,0,sizeof(*cpuid_info));

	/* alright then, let's ask the CPU it's identification */
	do_cpuid(0x00000000,&(cpuid_info->e0.g)); /* NTS: e0.g aliases over e0.i and fills in info */

	/* if we didn't get anything, then CPUID is not functional */
	if (cpuid_info->e0.i.cpuid_max == 0) {
		cpu_flags &= ~CPU_FLAG_CPUID;
		free(cpuid_info);
		return;
	}

	if (cpuid_info->e0.i.cpuid_max >= 1) {
		do_cpuid(0x00000001,&(cpuid_info->e1.g));
		if (cpuid_info->e1.f.family >= 4 && cpuid_info->e1.f.family <= 6)
			cpu_basic_level = cpuid_info->e1.f.family;

		/* now check for the extended CPUID. if the value of EAX is less than
		 * 0x80000000 then it's probably the original Pentium which responds
		 * to these addresses but with the same responses to 0x00000000.... */
		do_cpuid(0x80000000,&(cpuid_info->e80000000.g));
		if (cpuid_info->e80000000.i.cpuid_max < 0x80000000)
			cpuid_info->e80000000.i.cpuid_max = 0;
		else if (cpuid_info->e80000000.i.cpuid_max >= 0x80000001)
			do_cpuid(0x80000001,&(cpuid_info->e80000001.g));
	}

	/* extended CPU id string */
	if (cpuid_info->e80000000.i.cpuid_max >= 0x80000004) {
		do_cpuid(0x80000002,&(cpuid_info->e80000002));
		do_cpuid(0x80000003,&(cpuid_info->e80000003));
		do_cpuid(0x80000004,&(cpuid_info->e80000004));
	}

	/* modern CPUs report the largest physical address, virtual address, etc. */
	if (cpuid_info->e80000000.i.cpuid_max >= 0x80000008) {
		struct cpu_cpuid_generic_block tmp={0};

		do_cpuid(0x80000008,&tmp);
		cpuid_info->phys_addr_bits = tmp.a & 0xFF;
		cpuid_info->virt_addr_bits = (tmp.a >> 8) & 0xFF;
		cpuid_info->guest_phys_addr_bits = (tmp.a >> 16) & 0xFF;
		if (cpuid_info->guest_phys_addr_bits == 0)
			cpuid_info->guest_phys_addr_bits = cpuid_info->phys_addr_bits;
	}
	/* we have to guess for older CPUs */
	else {
		/* If CPU supports long mode, then assume 40 bits */
		if (cpuid_info->e80000001.f.d_lm) {
			cpuid_info->phys_addr_bits = 40;
			cpuid_info->virt_addr_bits = 40;
		}
		/* If CPU supports PSE36, then assume 36 bits */
		else if (cpuid_info->e1.f.d_pse36) {
			cpuid_info->phys_addr_bits = 36;
			cpuid_info->virt_addr_bits = 36;
		}
		else {
			cpuid_info->phys_addr_bits = 32;
			cpuid_info->virt_addr_bits = 32;
			/* TODO: If possible, identify 386SX, which has a 24-bit phys addr limit */
			/* TODO: If possible, identify 486SX, which has a 26-bit phys addr limit */
		}

		cpuid_info->guest_phys_addr_bits = cpuid_info->phys_addr_bits;
	}
}

static void probe_fpu() {
	unsigned short tmp=0;

#if defined(__GNUC__)
	/* Linux host: TODO */
#else
	__asm {
		fninit
		mov		word ptr [tmp],0x5A5A
		fnstsw		word ptr [tmp]
		cmp		word ptr [tmp],0
		jnz		no_fpu

		fnstcw		word ptr [tmp]
		mov		ax,word ptr [tmp]
		and		ax,0x103F
		cmp		ax,0x003F
		jnz		no_fpu

# if defined(__COMPACT__) || defined(__LARGE__) || defined(__HUGE__)
		mov		ax,seg cpu_flags
		mov		ds,ax
# endif
		or		byte ptr cpu_flags,0x01	; CPU_FLAG_FPU

no_fpu:
	}
#endif
}

static void probe_basic_cpu_level() {
/* 32-bit builds: The fact that we're executing is proof enough the CPU is a 386 or higher, skip the 8086/286 tests.
 * 16-bit builds: Use the Intel Standard test to determine 8086, 286, or up to 386. Also detect "virtual 8086 mode". */
#if TARGET_BITS == 32 /* 32-bit DOS, Linux i386, Win32, etc... */
	cpu_basic_level = 3;	/* we're running as 32-bit code therefore the CPU is at least a 386, we are in protected mode, and not v86 mode */
	cpu_flags = CPU_FLAG_PROTMODE;
#elif TARGET_BITS == 16
	cpu_basic_level = 0;
	cpu_flags = 0;

	__asm {
		.286
		push	ds
		pusha

		/* an 8086 will always set bits 12-15 */
		pushf
		pop	ax
		and	ax,0x0FFF
		push	ax
		popf
		pushf
		pop	ax
		and	ax,0xF000
		cmp	ax,0xF000
		jne	is_not_8086
		; cpu_basic_level == 0 already!
		jmp	fin

		/* a 286 will always clear bits 12-15 in real mode */
		/* NTS: experience says we must restore FLAGS after the test because protected mode environments will crash otherwise */
is_not_8086:	pushf				; save FLAGS
		or	ax,0xF000
		push	ax
		popf
		pushf
		pop	ax
		popf				; restore FLAGS
		and	ax,0xF000
		jnz	is_not_286

# if defined(__COMPACT__) || defined(__LARGE__) || defined(__HUGE__)
		mov	ax,seg cpu_basic_level
		mov	ds,ax
# endif
		mov	cpu_basic_level,2

		jmp	fin

is_not_286:		
# if defined(__COMPACT__) || defined(__LARGE__) || defined(__HUGE__)
		mov	ax,seg cpu_basic_level
		mov	ds,ax
# endif
		mov	cpu_basic_level,3

fin:		popa
		pop	ds			/* END */
	}

	if (cpu_basic_level >= 2) {
		__asm {
			.286

			push	ds
			push	ax
			push	bx
			/* use "smsw" to detect whether the CPU is running in protected mode.
			 * note that if we're real-mode DOS code running under a virtual 8086
			 * monitor, that "smsw" is legal and does not trigger a fault like
			 * "mov eax,cr0" would */
			smsw	ax
			and	al,1
			shl	al,2			; (1 << 1) == 0x04 == CPU_FLAG_PROTMODE
#if defined(__COMPACT__) || defined(__LARGE__) || defined(__HUGE__)
			mov	bx,seg cpu_flags
			mov	ds,bx
#endif
			or	byte ptr cpu_flags,al
			pop	bx
			pop	ax
			pop	ds
		}
	}

/*============================== 16-bit Windows ==========================*/
# if defined(TARGET_WINDOWS)
#  if !defined(TARGET_WINDOWS_WIN16)
#   error what
#  endif
	if ((GetWinFlags()&(WF_ENHANCED|WF_STANDARD)) == 0) {
		/* TODO: Is it even possible to run Windows real-mode under a v86 kernel?
		 *       Such as, for example, running Windows 3.0 real mode under EMM386.EXE? */
		if (cpu_flags & CPU_FLAG_PROTMODE) cpu_flags |= CPU_FLAG_V86;
	}
/*================================ 16-bit DOS ============================*/
# elif defined(TARGET_MSDOS)
	/* 16-bit DOS is supposed to run in real mode. So if CPU_FLAG_PROTMODE is set,
	 * we're in virtual 8086 mode */
	if (cpu_flags & CPU_FLAG_PROTMODE) cpu_flags |= CPU_FLAG_V86;
# else
#  error what
# endif
#else
# error Unknown TARGET_BITS
#endif /* TARGET_BITS */

	/* do not test further if less than a 386 */
	if (cpu_basic_level < 3) return;

#if defined(__GNUC__)
# if defined(__i386__) /* Linux i386 + GCC */
	{
		unsigned int a;

		/* a 386 will not allow setting the AC bit (bit 18) */
		__asm__(	"pushfl\n"

				"pushfl\n"
				"popl	%%eax\n"
				"or	$0x40000,%%eax\n"
				"pushl	%%eax\n"
				"popfl\n"
				"pushfl\n"
				"popl	%%eax\n"

				"popfl\n"
				: "=a" (a) /* output */ : /* input */ : /* clobbered */);
		if (a&0x40000) cpu_basic_level = 4;
	}
# endif
#else
	/* a 386 will not allow setting the AC bit (bit 18) */
	__asm {
		.386
# if TARGET_BITS == 16
		cli
# endif
		pushfd
		pop	eax
		or	eax,0x40000
		push	eax
		popf
		pushf
		pop	eax
# if TARGET_BITS == 16
		sti
# endif
		test	eax,0x40000
		jnz	is_not_386
		jmp	fin2

is_not_386:
# if defined(__COMPACT__) || defined(__LARGE__) || defined(__HUGE__)
		mov	ax,seg cpu_basic_level
		mov	ds,ax
# endif
		mov	cpu_basic_level,4

fin2:		nop
	}
#endif

#if defined(__GNUC__)
	/* if a 486 or higher, check for CPUID */
	{
		unsigned int a,b;

		__asm__(	"pushfl\n"

				"pushfl\n"
				"popl	%%eax\n"
				"and	$0xFFDFFFFF,%%eax\n"
				"pushl	%%eax\n"
				"popfl\n"
				"pushfl\n"
				"popl	%%eax\n"

				"mov	%%eax,%%ebx\n"

				"or	$0x00200000,%%ebx\n"
				"pushl	%%ebx\n"
				"popfl\n"
				"pushfl\n"
				"pop	%%ebx\n"

				"popfl\n"
				: "=a" (a), "=b" (b) /* output */ : /* input */ : /* clobbered */);

		/* a=when we cleared ID  b=when we set ID */
		if ((a&0x00200000) == 0 && (b&0x00200000)) cpu_flags |= CPU_FLAG_CPUID;
	}
#else
	/* if a 486 or higher, check for CPUID */
	if (cpu_basic_level >= 4) {
		__asm {
			.386

			pushfd
			pop	eax
			and	eax,0xFFDFFFFF
			push	eax
			popfd
			pushfd
			pop	eax
			test	eax,0x200000
			jnz	no_cpuid		; if we failed to clear CPUID then no CPUID

			or	eax,0x200000
			push	eax
			popfd
			pushfd
			pop	eax
			test	eax,0x200000
			jz	no_cpuid		; if we failed to set CPUID then no CPUID

#if defined(__COMPACT__) || defined(__LARGE__) || defined(__HUGE__)
			mov	ax,seg cpu_flags
			mov	ds,ax
#endif
			or	byte ptr cpu_flags,0x08 ; CPU_FLAG_CPUID

no_cpuid:		nop
		}
	}
#endif

	if (cpu_flags & CPU_FLAG_CPUID)
		probe_cpuid();
}

void probe_cpu() {
	if (cpu_basic_level < 0) {
		probe_basic_cpu_level();
		probe_fpu();
	}
}

int main() {
	probe_cpu();
	printf("CPU level: %d\n",cpu_basic_level);
	if (cpu_flags & CPU_FLAG_FPU) printf("- FPU is present\n");
	if (cpu_flags & CPU_FLAG_V86) printf("- Virtual 8086 mode is active\n");
	if (cpu_flags & CPU_FLAG_CPUID) printf("- CPUID is present\n");
	if (cpu_flags & CPU_FLAG_PROTMODE) printf("- Protected mode is active\n");

	if (cpuid_info != NULL) {
		char tmp[64];

		cpu_copy_id_string(tmp,&(cpuid_info->e0.i));
		printf("CPUID info available: max=%08lX ext_max=0x%08lX id='%s'\n",
			(unsigned long)cpuid_info->e0.i.cpuid_max,
			(unsigned long)cpuid_info->e80000000.i.cpuid_max,
			tmp);

		if (cpuid_info->e0.i.cpuid_max >= 1) {
			printf(" - Stepping %u model %u family %u processor_type %u ext-family %u\n",
				cpuid_info->e1.f.stepping,
				cpuid_info->e1.f.model + (cpuid_info->e1.f.extended_model << 4),
				cpuid_info->e1.f.family,
				cpuid_info->e1.f.processor_type,
				cpuid_info->e1.f.extended_family);
			printf("   - RAW: ABCD %08lX %08lX %08lX %08lX\n",
				(unsigned long)cpuid_info->e1.g.a,
				(unsigned long)cpuid_info->e1.g.b,
				(unsigned long)cpuid_info->e1.g.c,
				(unsigned long)cpuid_info->e1.g.d);
			printf("   - ECX: ");
/* Save my wrists and avoid copypasta! */
#define _(x) if (cpuid_info->e1.f.c_##x) { printf(cpp_stringify(x) " "); }
			_(sse3);	_(pclmulqdq);	_(dtes64);	_(monitor);
			_(ds_cpl);	_(vmx);		_(smx);		_(est);
			_(tm2);		_(ssse3);	_(cid);		_(fma);
			_(cx16);	_(xtpr);	_(pdcm);	_(pcid);
			_(dca);		_(sse4_1);	_(sse4_2);	_(x2apic);
			_(movbe);	_(popcnt);	_(tscdeadline);	_(aes);
			_(xsave);	_(osxsave);	_(avx);		_(f16c);
			_(rdrnd);	_(hypervisor);
#undef _
			printf("\n");

			printf("   - EDX: ");
/* Save my wrists and avoid copypasta! */
#define _(x) if (cpuid_info->e1.f.d_##x) { printf(cpp_stringify(x) " "); }
			_(fpu);		_(vme);		_(de);		_(pse);
			_(tsc);		_(msr);		_(pae);		_(mce);
			_(cx8);		_(apic);	_(sep);		_(mtrr);
			_(pge);		_(mca);		_(cmov);	_(pat);
			_(pse36);	_(pn);		_(clflush);	_(dts);
			_(acpi);	_(mmx);		_(fxsr);	_(sse);
			_(sse2);	_(ss);		_(ht);		_(tm);
			_(ia64);	_(pbe);
#undef _
			printf("\n");
			assert(sizeof(struct cpu_cpuid_00000001_id_features) == (4 * 4));
		}

		if (cpuid_info->e80000000.i.cpuid_max >= 0x80000001) {
			printf(" - Ext. stepping %u model %u family %u processor_type %u ext-family %u\n",
				cpuid_info->e80000001.f.stepping,
				cpuid_info->e80000001.f.model + (cpuid_info->e80000001.f.extended_model << 4),
				cpuid_info->e80000001.f.family,
				cpuid_info->e80000001.f.processor_type,
				cpuid_info->e80000001.f.extended_family);
			printf("   - RAW: ABCD %08lX %08lX %08lX %08lX\n",
				(unsigned long)cpuid_info->e80000001.g.a,
				(unsigned long)cpuid_info->e80000001.g.b,
				(unsigned long)cpuid_info->e80000001.g.c,
				(unsigned long)cpuid_info->e80000001.g.d);
			printf("   - ECX: ");
/* Save my wrists and avoid copypasta! */
#define _(x) if (cpuid_info->e80000001.f.c_##x) { printf(cpp_stringify(x) " "); }
			_(ahf64);	_(cmp);		_(svm);		_(eas);
			_(cr8d);	_(lzcnt);	_(sse4a);	_(msse);
			_(3dnow_prefetch); _(osvw);	_(ibs);		_(xop);
			_(skinit);	_(wdt);		_(lwp);		_(fma4);
			_(tce);		_(nodeid);	_(tbm);		_(topx);
			_(pcx_core);	_(pcx_nb);
#undef _
			printf("\n");

			printf("   - EDX: ");
/* Save my wrists and avoid copypasta! */
#define _(x) if (cpuid_info->e80000001.f.d_##x) { printf(cpp_stringify(x) " "); }
			_(fpu);		_(vme);		_(de);		_(pse);
			_(tsc);		_(msr);		_(pae);		_(mce);
			_(cx8);		_(apic);	_(sep);		_(mtrr);
			_(pge);		_(mca);		_(cmov);	_(pat);
			_(pse36);	_(mp);		_(nx);		_(mmxplus);
			_(mmx);		_(fxsr);	_(ffxsr);	_(pg1g);
			_(tscp);	_(lm);		_(3dnowplus);	_(3dnow);
#undef _
			printf("\n");
			assert(sizeof(struct cpu_cpuid_80000001_id_features) == (4 * 4));
		}

		if (cpuid_info->e80000000.i.cpuid_max >= 0x80000004) {
			printf(" - Extended CPU id '%s'\n",cpu_copy_ext_id_string(tmp,cpuid_info));
		}

		printf(" - CPU address bits: physical=%u virtual=%u guest=%u\n",
			cpuid_info->phys_addr_bits,
			cpuid_info->virt_addr_bits,
			cpuid_info->guest_phys_addr_bits);
	}

#ifdef WIN_STDOUT_CONSOLE
	_win_endloop_user_echo();
#endif
	return 0;
}

