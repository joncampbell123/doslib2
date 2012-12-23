#if defined(TARGET_WINDOWS)
# include <windows.h>
# include <windows/apihelp.h>
#endif

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <hw/cpu/cpu.h>

#include <misc/useful.h>

signed char			cpu_basic_level = -1;
signed char			cpu_basic_fpu_level = -1;
unsigned short			cpu_flags = 0;
struct cpu_cpuid_info*		cpuid_info = NULL;
uint16_t			cpu_type_and_mask = 0;	/* on 386/486 systems without CPUID, this contains type and stepping value (DX) */
	/* Possible values (if it worked):
	 *
	 *     0x03xx   386DX
	 *     0x04xx   486
	 *     0x05xx   Pentium
	 *     0x23xx   386SX
	 *     0x33xx   Intel i376
	 *     0x43xx   386SL
	 *     0xA3xx   IBM 386SLC
	 *     0xA4xx   IBM 486SLC
	 *
	 *     0x0303   386 B1 to B10, Am386DX/DXL step A
	 *     0x0305   Intel D0
	 *     0x0308   Intel D1/D2/E1, Am386DX/DXL step B
	 *
	 *     0x2304   Intel A0
	 *     0x2305   Intel B
	 *     0x2308   Intel C/D1, Am386SX/SXL step A1
	 *     0x2309   Intel 386CX/386EX/386SXstatic step A
	 *
	 *     For complete list see [http://www.youtube.com/watch?NR=1&feature=endscreen&v=DUiTZVinZEM]
	 */

/* CPUID function. To avoid redundant asm blocks */
#if defined(__GNUC__)
# if defined(__i386__) /* Linux GCC + i386 */
/* defined in cpu.h */
# elif defined(__amd64__) /* Linux GCC + x86_64 */
/* TODO */
# endif
#elif TARGET_BITS == 32
/* defined in cpu.h */
#elif TARGET_BITS == 16
/* defined in cpu.c */
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

void cpu_copy_id_string(char *tmp/*must be CPU_ID_STRING_LENGTH or more*/,struct cpu_cpuid_00000000_id_info *i) {
	*((uint32_t*)(tmp+0)) = i->id_1;
	*((uint32_t*)(tmp+4)) = i->id_2;
	*((uint32_t*)(tmp+8)) = i->id_3;
	tmp[12] = 0;
}

char *cpu_copy_ext_id_string(char *tmp/*CPU_EXT_ID_STRING_LENGTH*/,struct cpu_cpuid_info *i) {
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

		/* now check for the extended CPUID. it is said that in the original
		 * Pentium ranges 0x80000000-0x8000001F respond exactly the same as
		 * 0x00000000-0x0000001F */
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

		cpuid_info->cpu_cores = (tmp.c & 0xFF) + 1;
		if (tmp.c & 0xF000) cpuid_info->cpu_acpi_id_bits = 1 << (((tmp.c >> 12) & 0xF) - 1);
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
		}

		cpuid_info->guest_phys_addr_bits = cpuid_info->phys_addr_bits;
	}
}

static void probe_fpu() {
	unsigned short tmp=0;

	/* If CPUID is available and reports an FPU, then assume
	 * FPU is present (integrated into the CPU) and do not test.
	 * Carry out the test if CPUID does not report one. */
	if ((cpu_flags & CPU_FLAG_CPUID) && cpuid_info != NULL) {
		if (cpuid_info->e1.f.d_fpu) {
			cpu_basic_fpu_level = cpu_basic_level;
			cpu_flags |= CPU_FLAG_FPU;
			return;
		}
	}

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

	if (cpu_flags & CPU_FLAG_FPU) {
		/* what we assume initially is based on the CPU basic level we detected earlier.
		 * these assumptions are based on typical CPU+FPU hookups and the compatibility
		 * of the chips:
		 *
		 *    8086/8088      can be paired with 8087
		 *    286            can be paired with 80287 (or 80387?)
		 *    386            can be paired with 80287 or 80387
		 *    486            can be paired with 80487 or integrated into the CPU
		 *    Pentium        normally integrated into the CPU
		 *  (anything newer) integrated into the CPU */
		if (cpu_basic_level == 2/*286*/ || cpu_basic_level == 3/*386*/) {
#if defined(__GNUC__)
			cpu_basic_fpu_level = 3;
			/* Linux host: TODO */
#else
			cpu_basic_fpu_level = 2;

			__asm {
				.386
				.387
/* 287 vs 387 detection code borrowed from:
 * http://qlibdos32.sourceforge.net/tutor/fpu-detect.asm.txt
 *
 * I have this code execute ONLY on 286 and 386 systems because I'm
 * concerned the test's specific checks might fail on newer processors
 * that do not exactly emulate these small details --J.C.
 *
 * This test can only distinguish a 8087 from 387, it can't exactly detect
 * if it is a 287. So we assume that if it fails the test for a 387, then
 * it's a 287. If it's an 8087, then this code path wouldn't run at all
 * (see "if" statement above)
 *
 * TODO: The test code mentions that it enables FPU interrupts. It also
 *       deliberately divides by zero as part of the test. So far it doesn't
 *       seem to trigger any kind of FPU exception handler, but how do we
 *       make sure that interrupt won't trigger? */
				fstcw		word ptr [tmp]
				and		word ptr [tmp],0xFF7F
				fldcw		word ptr [tmp]
				fdisi
				fstcw		word ptr [tmp]
				fwait
				mov		ax,word ptr [tmp]
				and		ax,0x80
				jz		test_ok2
				jmp		test_done

test_ok2:			finit
				fld1
				fldz
				fdiv
				fld		st(0)
				fchs
				fcompp
				fstsw		ax
				fwait
				and		ah,0x40
				jz		test_ok3
				jmp		test_done

test_ok3:			push		ds
# if defined(__COMPACT__) || defined(__LARGE__) || defined(__HUGE__)
				mov		ax,seg cpu_basic_fpu_level
				mov		ds,ax
# endif
				mov		byte ptr [cpu_basic_fpu_level],3
				pop		ds
test_done:
			}
#endif
		}
		else {
			cpu_basic_fpu_level = cpu_basic_level;
		}
	}
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
			shl	al,2			; (1 << 2) == 0x04 == CPU_FLAG_PROTMODE
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
		 *       For example, is it possible to run Windows 3.0 real mode under EMM386.EXE? */
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
# elif defined(__amd64__) /* Linux x86_64 + GCC */
/* TODO */
# endif
#else
	/* a 386 will not allow setting the AC bit (bit 18) */
	/* NTS: Inline assembly: #if TARGET_BITS == 16 doesn't work right, use only #ifdef */
	/* NTS: Do NOT use cli/sti under 32-bit Windows targets. The NT kernel will fault us for it.
	 *      Everyone expects 16-bit code to do it though */
	__asm {
		.386
# ifdef TARGET_CLI_STI_IS_SAFE
		cli
# endif
		pushfd
		pop	eax
		or	eax,0x40000
		push	eax
		popf
		pushf
		pop	eax
# ifdef TARGET_CLI_STI_IS_SAFE
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
# if defined(__i386__) /* Linux i386 + GCC */
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
# elif defined(__amd64__) /* Linux x86_64 + GCC */
	/* TODO */
# endif
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

#if defined(TARGET_WINDOWS)
	if (!(cpu_flags & CPU_FLAG_CPUID)) {/* we can assume at least >= 386 here */
		cpuid_info->virt_addr_bits = 32;
		cpuid_info->phys_addr_bits = 32;
		cpuid_info->guest_phys_addr_bits = 32;
	}
#else
	/* if the CPU does not provide CPUID, then try to get type/model ID value (386/486) */
	if (!(cpu_flags & CPU_FLAG_CPUID)) {/* we can assume at least >= 386 here */
# if !defined(__GNUC__) /* Not under Linux! */
#  if !defined(TARGET_WINDOWS) /* Not under Windows! */
		/* take the safest route first and ask the BIOS */
		__asm {
			push	ax
			xor	cx,cx
			mov	ax,0xC910
			int	15h
			jc	nocando
			cmp	ah,0x00		; if AH != 0x00 then it didnt work
#   if defined(__COMPACT__) || defined(__LARGE__) || defined(__HUGE__)
			mov	ax,seg cpu_type_and_mask
			mov	ds,ax
#   endif
			mov	cpu_type_and_mask,cx
			jnz	nocando
nocando:		pop	ax
		}
#  endif
# endif

		/* the phys/virt addr bits are not set by this point if probe_cpuid() is never executed.
		 * so we need to set them to work 100% properly on pre-CPUID x86 processors */
		cpuid_info->virt_addr_bits = 32;
		/* TODO: It is said 386EX/386CX systems have 26-bit external addressing?? */
		/* TODO: Is there anything we can do to identify some 486-class systems I have where
		 *       address wraparound occurs every 64MB?? (26-bit address limit) */
		if ((cpu_type_and_mask&0xFF00) == 0x23) /* Intel 386SX */
			cpuid_info->phys_addr_bits = 24;
		else
			cpuid_info->phys_addr_bits = 32;

		cpuid_info->guest_phys_addr_bits = cpuid_info->phys_addr_bits;
	}
#endif
}

void probe_cpu() {
	if (cpu_basic_level < 0) {
		probe_basic_cpu_level();
		probe_fpu();
	}
}

