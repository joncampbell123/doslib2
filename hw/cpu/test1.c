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
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

signed char cpu_basic_level = -1;
signed char cpu_basic_fpu_level = -1;
unsigned short cpu_flags = 0;

#pragma pack(push,1)
struct cpu_cpuid_info {
	uint32_t		cpuid_max;
	char			manufacturer_id[13]; /* 12 bytes ASCII + NUL */
	unsigned char		unused[3];
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

static void probe_cpuid() {
	if (cpuid_info != NULL) return;

	cpuid_info = malloc(sizeof(*cpuid_info));
	if (cpuid_info == NULL) return;
	memset(cpuid_info,0,sizeof(*cpuid_info));

#if defined(__GNUC__)
	/* Linux host: TODO */
#elif TARGET_BITS == 32
	__asm {
		.586
		pushad
		mov	esi,[cpuid_info]
		; ESI = cpuid info
		xor	eax,eax
		cpuid
		mov	[esi+0/*cpuid_max*/],eax
		mov	[esi+4/*manufact[0]*/],ebx
		mov	[esi+8/*manufact[4]*/],edx
		mov	[esi+12/*manufact[8]*/],ecx
		popad
	}
#else /* TARGET_BITS == 16 */
	__asm {
		.586
		push	ds
		pusha
# if defined(__COMPACT__) || defined(__LARGE__)
		mov	si,seg cpuid_info
		mov	ds,si
		lds	si,word ptr [cpuid_info]
# else
		mov	si,word ptr [cpuid_info]
# endif
		; DS:SI = cpuid info
		xor	eax,eax
		cpuid
		mov	[si+0/*cpuid_max*/],eax
		mov	[si+4/*manufact[0]*/],ebx
		mov	[si+8/*manufact[4]*/],edx
		mov	[si+12/*manufact[8]*/],ecx
		popa
		pop	ds
	}
#endif
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

# if defined(__COMPACT__) || defined(__LARGE__)
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
#if TARGET_BITS == 32
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

# if defined(__COMPACT__) || defined(__LARGE__)
		mov	ax,seg cpu_basic_level
		mov	ds,ax
# endif
		mov	cpu_basic_level,2

		jmp	fin

is_not_286:		
# if defined(__COMPACT__) || defined(__LARGE__)
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
#if defined(__COMPACT__) || defined(__LARGE__)
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
	/* Linux host: TODO */
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
# if defined(__COMPACT__) || defined(__LARGE__)
		mov	ax,seg cpu_basic_level
		mov	ds,ax
# endif
		mov	cpu_basic_level,4

fin2:		nop
	}

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

#if defined(__COMPACT__) || defined(__LARGE__)
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
		printf("CPUID info available: max=%08lX id='%s'\n",
			(unsigned long)cpuid_info->cpuid_max,
			cpuid_info->manufacturer_id);
	}

#ifdef WIN_STDOUT_CONSOLE
	_win_endloop_user_echo();
#endif
	return 0;
}

