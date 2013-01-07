#if defined(TARGET_WINDOWS)
# include <windows.h>
# include <windows/apihelp.h>
#endif
#if defined(TARGET_LINUX)
# include <signal.h>
# include <unistd.h>
# include <sys/mman.h>
#endif

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <hw/cpu/cpu.h>
#include <hw/cpu/cpusse.h>
#include <misc/useful.h>

unsigned char cpu_sse_flags = 0x80;

void reset_cpu_sse_flags() {
	cpu_sse_flags = CPU_SSE_NOT_YET_DETECTED;
}

static unsigned int _direct_cr4_read_sse() {
	/* read CR4 */
	register unsigned int tst,r = 0;

	tst = read_cr4i_creg();
	if (tst & 0x200) r |= CPU_SSE_ENABLED;
	if (tst & 0x400) r |= CPU_SSE_EXCEPTIONS_ENABLED;
	return r;
}

/* NTS: It is expected that this function will be called multiple times.
 *      Most likely the extra calls will be from external libraries wishing
 *      to know if SSE is enabled and working. In normal circumstances
 *      this code will do the detection process ONCE then return without
 *      changing the flags.
 *
 *      If the program truly wants us to re-detect SSE state, it must call
 *      reset_cpu_sse_flags() which will set the SSE detection back to
 *      "unknown" and allow probe_cpu_sse() to do it's magic again. The
 *      caller is expected to do this SPARINGLY, only in cases where external
 *      code might change SSE or processor state. One recommended case where
 *      a program might re-run SSE detection would be immediately after
 *      executing another program, because the external program might enable
 *      SSE on it's own, or enable virtual 8086 mode, or cause EMM386.EXE
 *      to become active, or it might even cause Windows to start. */
void probe_cpu_sse() {
	probe_cpu();

	if (!(cpu_sse_flags & CPU_SSE_NOT_YET_DETECTED))
		return;

	cpu_sse_flags = 0;
	if (cpu_info.cpuid_info == NULL) return; /* if no CPUID info, then no SSE */
	if (!cpu_info.cpuid_info->e1.f.d_sse) return; /* if SSE not supported by CPU then stop now */
	cpu_sse_flags |= CPU_SSE_SUPPORTED;

#if TARGET_BITS == 16
	if (cpu_info.cpu_flags & CPU_FLAG_PROTMODE) {
# if defined(TARGET_WINDOWS)
	/* TODO: Load TOOLHELP.DLL, setup exception handler, execute SSE instruction and see if it triggers invalid opcode exception */
	/* TODO: If Windows 3.1 or 3.0, make DPMI calls to hook invalid opcode exception and execute SSE instruction.
	 *       The DPMI hook trick does not work under Windows 95 or later. */
# endif
	}
	else if (cpu_info.cpu_flags & CPU_FLAG_V86) {
	/* TODO: If virtual 8086 mode detected, then:
	 *  
	 *             a) look for VCPI server, and try to use VCPI to enter 32-bit protected mode where we
	 *                can then safely read CR4. If successful, then remember to use this technique when
	 *                the caller wants to enable/disable SSE.
	 *
	 *             b) look for DPMI server, enter DPMI protected mode, use DPMI protected mode to hook
	 *                int 6h (invalid opcode) then abuse the DPMI server "entry points" to jump back
	 *                to realmode. hook real-mode INT 6h just to be safe. execute an SSE instruction and
	 *                note whether or not an invalid opcode exception occurs. Jump back into DPMI
	 *                protected mode, remove the exception hook, and then jump back to real mode.
	 *
	 *                ^ In the ideal Windows "DOS box" situation the DOS program could simply hook INT 6h
	 *                  in the realmode vector table, but Windows it seems will not pass INT 6h down to
	 *                  the v86 DOS box when it actually happens, it will always execute the DPMI server's
	 *                  exception handler. Thus to catch Invalid Opcode exceptions, we must hook INT 6h
	 *                  at the DPMI server even when we expect the exception to happen in "real mode". */
	}
	else {
		/* Real mode: we can do whatever we want including enabling/disabling SSE */
		cpu_sse_flags |= _direct_cr4_read_sse() | CPU_SSE_CAN_ENABLE | CPU_SSE_CAN_DISABLE;
	}
#elif TARGET_BITS == 32
# if defined(TARGET_WINDOWS)
#  if defined(TARGET_WINDOWS_WIN386)
	/* TODO: What can we do? DPMI hooks? Do 32-bit DPMI hooks work under Win95 unlike the 16-bit ones? */
#  else
	{
		BOOL (WINAPI *__IsProcessorFeaturePresent)(DWORD feature) =
			GetProcAddress(GetModuleHandle("KERNEL32.DLL"),"IsProcessorFeaturePresent");

		if (__IsProcessorFeaturePresent != NULL) {
			MessageBox(NULL,"IPFP","",MB_OK);
			if (__IsProcessorFeaturePresent(PF_XMMI_INSTRUCTIONS_AVAILABLE))
				cpu_sse_flags |= CPU_SSE_ENABLED | CPU_SSE_EXCEPTIONS_ENABLED;
		}

		if (!(cpu_sse_flags & CPU_SSE_ENABLED)) {
			/* Any kernel too old to have IsProcessorFeaturePresent is too old
			 * to support SSE instructions. So if we detect HERE that SSE is enabled
			 * it was probably enabled by one of our hacks and exceptions are probably
			 * NOT enabled */
			__try {
				__asm {
					.686
					.xmm
					xorps xmm0,xmm0
				}
				cpu_sse_flags |= CPU_SSE_ENABLED;
			}
			__except(1) {
			}
		}
	}
#  endif
# elif defined(TARGET_MSDOS)
	/* If the DOS extender is running us on Ring 0 (which is usually the case
	 * unless EMM386.EXE is resident) then we can just read CR4 directly to know if
	 * SSE is enabled, and write CR4 to enable SSE.
	 *
	 * we can look at bits 1-0 of the code segment to detect Ring 0 execution */
	if ((read_cs_sreg()&3) == 0) {
		/* Yes: Ring 0 execution. Read CR4 directly. We can also write CR4 and therefore enable/disable SSE */
		cpu_sse_flags |= _direct_cr4_read_sse() | CPU_SSE_CAN_ENABLE | CPU_SSE_CAN_DISABLE;
	}
	else {
		/* No: Ring 3 probably. We will cause a fault if we try to read CR4.
		 * The only way to test whether SSE is enabled is to try executing an SSE
		 * instruction and noting whether or not an Invalid Opcode exception happens.
		 * When EMM386.EXE is active, or from within a DOS Box in Windows this is the
		 * only way to detect it. */
		/* TODO */
	}
# elif defined(TARGET_LINUX)
	cpu_sse_flags |= cpu_sse_linux_test();
# endif
#endif
}

unsigned int cpu_sse_enable() {
	if (!(cpu_sse_flags & CPU_SSE_SUPPORTED))
		return 0;
	if (!(cpu_sse_flags & CPU_SSE_CAN_ENABLE))
		return 0;

#if TARGET_BITS == 16
	if (cpu_info.cpu_flags & CPU_FLAG_PROTMODE) {
# if defined(TARGET_WINDOWS)
		/* TODO: How? */
		return 0;
# endif
	}
	else if (cpu_info.cpu_flags & CPU_FLAG_V86) {
		/* TODO: If VCPI is available, use VCPI to enter protected mode and then
		 *       change the contents of CR4 */
	}
	else {
		_sse_enable();
		cpu_sse_flags |= CPU_SSE_ENABLED;
	}
#elif TARGET_BITS == 32
# if defined(TARGET_WINDOWS)
	/* TODO: Use GetProcAddress() to call IsProcessorFeaturePresent() with PF_XMMI_INSTRUCTIONS_AVAILABLE */
	/* TODO: Use code to execute an SSE instruction within a __try __except(1) block to catch the invalid opcode exception to detect SSE */
# elif defined(TARGET_MSDOS)
	/* If the DOS extender is running us on Ring 0 (which is usually the case
	 * unless EMM386.EXE is resident) then we can just read CR4 directly to know if
	 * SSE is enabled, and write CR4 to enable SSE.
	 *
	 * we can look at bits 1-0 of the code segment to detect Ring 0 execution */
	if ((read_cs_sreg()&3) == 0) {
		_sse_enable();
		cpu_sse_flags |= CPU_SSE_ENABLED;
	}
	else {
		return 0;
	}
# elif defined(TARGET_LINUX)
	return 0;
# endif
#endif

	return 1;
}

unsigned int cpu_sse_disable() {
	if (!(cpu_sse_flags & CPU_SSE_SUPPORTED))
		return 0;
	if (!(cpu_sse_flags & CPU_SSE_CAN_DISABLE))
		return 0;

#if TARGET_BITS == 16
	if (cpu_info.cpu_flags & CPU_FLAG_PROTMODE) {
# if defined(TARGET_WINDOWS)
		/* TODO: How? */
		return 0;
# endif
	}
	else if (cpu_info.cpu_flags & CPU_FLAG_V86) {
		/* TODO: If VCPI is available, use VCPI to enter protected mode and then
		 *       change the contents of CR4 */
	}
	else {
		_sse_disable();
		cpu_sse_flags &= ~CPU_SSE_ENABLED;
	}
#elif TARGET_BITS == 32
# if defined(TARGET_WINDOWS)
	/* TODO: Use GetProcAddress() to call IsProcessorFeaturePresent() with PF_XMMI_INSTRUCTIONS_AVAILABLE */
	/* TODO: Use code to execute an SSE instruction within a __try __except(1) block to catch the invalid opcode exception to detect SSE */
# elif defined(TARGET_MSDOS)
	/* If the DOS extender is running us on Ring 0 (which is usually the case
	 * unless EMM386.EXE is resident) then we can just read CR4 directly to know if
	 * SSE is enabled, and write CR4 to enable SSE.
	 *
	 * we can look at bits 1-0 of the code segment to detect Ring 0 execution */
	if ((read_cs_sreg()&3) == 0) {
		_sse_disable();
		cpu_sse_flags &= ~CPU_SSE_ENABLED;
	}
	else {
		return 0;
	}
# elif defined(TARGET_LINUX)
	return 0;
# endif
#endif

	return 1;
}

