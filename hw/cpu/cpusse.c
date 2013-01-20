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
#include <hw/cpu/dpmi.h>

/*DEBUG: Force the SSE test to execute even if CPUID is missing or CPUID indicates lack of SSE.
 *       You would enable this to test how well our exception handlers work in environments where
 *       SSE is obviously not supported such as Windows 3.0 in DOSBox (which does not emulate
 *       anything past a Pentium) */
#define DEBUG_ASSUME_SSE

/*DEBUG: Ignore TOOLHELP.DLL. You would enable this to test the DPMI exception handlers */
/*#define DEBUG_IGNORE_TOOLHELP*/

unsigned char cpu_sse_flags = 0x80;

void reset_cpu_sse_flags() {
	cpu_sse_flags = CPU_SSE_NOT_YET_DETECTED;
}

#if TARGET_BITS == 32
# if defined(TARGET_WINDOWS_WIN386)
unsigned int _cdecl cpu_sse_dpmi32win386_test();
unsigned int _cdecl cpu_sse_wintoolhelp386_test();
#  ifndef DEBUG_IGNORE_TOOLHELP
/* attempts to hook the invalid opcode exception using TOOLHELP.DLL.
 * this will return 0 if TOOLHELP.DLL is not available */
DWORD _InterruptRegisterSSETEST = 0;
DWORD _InterruptUnregisterSSETEST = 0;
unsigned int cpu_sse_win386_toolhelp_test(unsigned char *flags) {
	/* Check: Do not execute this test under Windows 3.1, it causes an unexplained shutdown
	 *        to the DOS prompt. But unlike Windows 95 we can fallback to the DPMI exception
	 *        handler test anyway. */
	if (WORDSWAP(GetVersion()) == 0x30A)
		return 0;

	{
		HINSTANCE dll;
		int r=0;
		UINT f;

		f = SetErrorMode(SEM_FAILCRITICALERRORS|SEM_NOOPENFILEERRORBOX);
		dll = LoadLibrary("TOOLHELP.DLL");
		if (dll != NULL) {
			_InterruptUnregisterSSETEST = (DWORD)GetProcAddress(dll,"INTERRUPTUNREGISTER");
			_InterruptRegisterSSETEST = (DWORD)GetProcAddress(dll,"INTERRUPTREGISTER");
		}

		if (_InterruptRegisterSSETEST != NULL && _InterruptUnregisterSSETEST != NULL) {
			*flags |= cpu_sse_wintoolhelp386_test();
			r = 1;
		}

		if (dll != NULL) FreeLibrary(dll);
		SetErrorMode(f);
		return r;
	}
}
#  else
#   define cpu_sse_win386_toolhelp_test(x) (0)
#  endif
# elif defined(TARGET_MSDOS)
unsigned int _cdecl cpu_sse_dpmi32_test();
# endif
#elif TARGET_BITS == 16
# if defined(TARGET_WINDOWS)
unsigned int _cdecl cpu_sse_dpmi16_test();
unsigned int _cdecl cpu_sse_wintoolhelp_test();
#  ifndef DEBUG_IGNORE_TOOLHELP
/* attempts to hook the invalid opcode exception using TOOLHELP.DLL.
 * this will return 0 if TOOLHELP.DLL is not available */
BOOL (__stdcall __far *_InterruptUnregisterSSETEST)(HTASK) = NULL;
BOOL (__stdcall __far *_InterruptRegisterSSETEST)(HTASK,FARPROC) = NULL;
unsigned int cpu_sse_win16_toolhelp_test(unsigned char *flags) {
	HINSTANCE dll;
	int r=0;
	UINT f;

	f = SetErrorMode(SEM_FAILCRITICALERRORS|SEM_NOOPENFILEERRORBOX);
	dll = LoadLibrary("TOOLHELP.DLL");
	if (dll != NULL) {
		_InterruptUnregisterSSETEST = (BOOL (__stdcall __far *)(HTASK))GetProcAddress(dll,"INTERRUPTUNREGISTER");
		_InterruptRegisterSSETEST = (BOOL (__stdcall __far *)(HTASK,FARPROC))GetProcAddress(dll,"INTERRUPTREGISTER");
	}

	if (_InterruptRegisterSSETEST != NULL && _InterruptUnregisterSSETEST != NULL) {
		*flags |= cpu_sse_wintoolhelp_test();
		r = 1;
	}

	if (dll != NULL) FreeLibrary(dll);
	SetErrorMode(f);
	return r;
}
#  else
#   define cpu_sse_win16_toolhelp_test(x) (0)
#  endif
# elif defined(TARGET_MSDOS)
unsigned int cpu_sse_vm86_dpmi32_test() { return 0; }
unsigned int cpu_sse_vm86_dpmi16_test() { return 0; }
# endif
#endif

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
#ifndef DEBUG_ASSUME_SSE
	if (cpu_info.cpuid_info == NULL) return; /* if no CPUID info, then no SSE */
	if (!cpu_info.cpuid_info->e1.f.d_sse) return; /* if SSE not supported by CPU then stop now */
#endif
	cpu_sse_flags |= CPU_SSE_SUPPORTED;

#if TARGET_BITS == 16
	if (cpu_info.cpu_flags & CPU_FLAG_PROTMODE) {
# if defined(TARGET_WINDOWS)
	/* FIXME: Under OS/2 2.x, this crashes when run from within the WIN-OS/2 compatibility layer. */
	/* If TOOLHELP.DLL is available, use it. Else, use DPMI system calls.
	 * The DPMI system call method works under Windows 3.0/3.1 and under NTVDM.EXE in Windows NT.
	 * Windows 95/98/ME however does not honor our DPMI exception handlers, but hooking through
	 * TOOLHELP.DLL works fine. */
		if (cpu_sse_win16_toolhelp_test(&cpu_sse_flags) == 0)
			cpu_sse_flags |= cpu_sse_dpmi16_test();
# endif
	}
	else if (cpu_info.cpu_flags & CPU_FLAG_V86) {
# if defined(TARGET_MSDOS)
		/* Possible scenario #1: We're in a Windows DOSBox (or OS/2 DOSBox).
		 *                       The only way to catch invalid opcode exceptions is to
		 *                       jump into DPMI protected mode and set an exception handler
		 *                       because these DPMI servers will typically disregard the
		 *                       real-mode interrupt vector. */
		dos_dpmi_probe();
		if (dos_dpmi_state.flags & DPMI_SERVER_PRESENT) {
			/* if DPMI is present, then initialize the server then return to real mode
			 * to continue execution. If a 386 or higher, then first attempt to connect
			 * as a 32-bit program. If a 286, or 32-bit failed, then attempt to connect
			 * as a 16-bit program. */
			if (!(dos_dpmi_state.flags & DPMI_SERVER_INIT) && cpu_info.cpu_basic_level >= 3)
				dos_dpmi_init_server32();
			if (!(dos_dpmi_state.flags & DPMI_SERVER_INIT) && cpu_info.cpu_basic_level >= 2)
				dos_dpmi_init_server16();

			/* if we connected to the DPMI server, then based on the mode we used to connect
			 * jump into protected mode and set the exception handler, then jump back to real mode. */
			if (dos_dpmi_state.flags & DPMI_SERVER_INIT) {
				if (dos_dpmi_state.flags & DPMI_SERVER_INIT_32BIT)
					cpu_sse_flags |= cpu_sse_vm86_dpmi32_test();
				else
					cpu_sse_flags |= cpu_sse_vm86_dpmi16_test();
			}
		}
# endif
	}
	else {
		/* Real mode: we can do whatever we want including enabling/disabling SSE */
		cpu_sse_flags |= _direct_cr4_read_sse() | CPU_SSE_CAN_ENABLE | CPU_SSE_CAN_DISABLE;
	}
#elif TARGET_BITS == 32
# if defined(TARGET_WINDOWS)
#  if defined(TARGET_WINDOWS_WIN386)
	/* Watcom win386 has it's own variant of the DPMI32 test because despite being
	 * 32-bit code, Windows 3.1 DPMI is stuck in 16-bit thinking and the exception handler
	 * is still called as if 16-bit. Weird. */

	/* If TOOLHELP.DLL is available, use it. Else, use DPMI system calls.
	 * The DPMI system call method works under Windows 3.0/3.1 and under NTVDM.EXE in Windows NT.
	 * Windows 95/98/ME however does not honor our DPMI exception handlers, but hooking through
	 * TOOLHELP.DLL works fine. */
	if (cpu_sse_win386_toolhelp_test(&cpu_sse_flags) == 0)
		cpu_sse_flags |= cpu_sse_dpmi32win386_test();
#  else
	cpu_sse_flags |= _win32_test_sse();
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
		cpu_sse_flags |= cpu_sse_dpmi32_test();
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

