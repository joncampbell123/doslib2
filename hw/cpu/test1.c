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
	uint16_t		c_pni:1;		/* bit 0: prescott new instructions */
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

struct cpu_cpuid_info {
	union cpu_cpuid_00000000_id_union	e0;	/* CPUID 0x00000000 CPU identification */
	union cpu_cpuid_00000001_id_union	e1;	/* CPUID 0x00000001 CPU ID and features */
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
	__asm__ (	"cpuid"
			: "=a" (b->a), "=b" (b->b), "=c" (b->c), "=d" (b->d) /* outputs */
			: "a" (select) /* input */
			: /* clobber */);
}
# endif
#elif TARGET_BITS == 32
/* TODO: #ifdef to detect Watcom C */
/* TODO: Alternate do_cpuid() for CPUID functions that require you to fill in EBX ECX or EDX */
void do_cpuid(const uint32_t select,struct cpu_cpuid_generic_block *b);
# pragma aux do_cpuid = \
	".586p" \
	"cpuid" \
	"mov [esi],eax" \
	"mov [esi+4],ebx" \
	"mov [esi+8],ecx" \
	"mov [esi+12],edx" \
	parm [eax] [esi] \
	modify [eax ebx ecx edx]
#elif TARGET_BITS == 16
void do_cpuid(const uint32_t select,struct cpu_cpuid_generic_block *b) {
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
		pushfd
		pop	eax
		or	eax,0x40000
		push	eax
		popf
		pushf
		pop	eax
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
		char tmp[16];

		cpu_copy_id_string(tmp,&(cpuid_info->e0.i));
		printf("CPUID info available: max=%08lX id='%s'\n",
			(unsigned long)cpuid_info->e0.i.cpuid_max,
			tmp);

		if (cpuid_info->e0.i.cpuid_max >= 1) {
			printf(" - Stepping %u model %u family %u processor_type %u ext-family %u\n",
				cpuid_info->e1.f.stepping,
				cpuid_info->e1.f.model + (cpuid_info->e1.f.extended_model << 4),
				cpuid_info->e1.f.family,
				cpuid_info->e1.f.processor_type,
				cpuid_info->e1.f.extended_family);
			printf(" - ECX: ");
/* Save my wrists and avoid copypasta! */
#define _(x) if (cpuid_info->e1.f.c_##x) { printf(cpp_stringify(x) " "); }
			_(pni);		_(pclmulqdq);	_(dtes64);	_(monitor);
			_(ds_cpl);	_(vmx);		_(smx);		_(est);
			_(tm2);		_(ssse3);	_(cid);		_(fma);
			_(cx16);	_(xtpr);	_(pdcm);	_(pcid);
			_(dca);		_(sse4_1);	_(sse4_2);	_(x2apic);
			_(movbe);	_(popcnt);	_(tscdeadline);	_(aes);
			_(xsave);	_(osxsave);	_(avx);		_(f16c);
			_(rdrnd);	_(hypervisor);
#undef _
			printf("\n");

			printf(" - EDX: ");
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
	}

#ifdef WIN_STDOUT_CONSOLE
	_win_endloop_user_echo();
#endif
	return 0;
}

