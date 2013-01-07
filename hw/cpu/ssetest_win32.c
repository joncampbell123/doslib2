#if TARGET_BITS == 32
# if defined(TARGET_WINDOWS)
#  if !defined(TARGET_WINDOWS_WIN386)
#   include <windows.h>
#   include <windows/apihelp.h>
#   include <stdio.h>
#   include <assert.h>
#   include <stdlib.h>
#   include <string.h>
#   include <stdint.h>
#   include <hw/cpu/cpu.h>
#   include <hw/cpu/cpusse.h>
#   include <misc/useful.h>

unsigned int _win32_test_sse() {
	unsigned int r = 0;
	BOOL (WINAPI *__IsProcessorFeaturePresent)(DWORD feature);

	if ((__IsProcessorFeaturePresent = (void*)GetProcAddress(GetModuleHandle("KERNEL32.DLL"),"IsProcessorFeaturePresent")) != NULL &&
		__IsProcessorFeaturePresent(PF_XMMI_INSTRUCTIONS_AVAILABLE))
		return CPU_SSE_ENABLED | CPU_SSE_EXCEPTIONS_ENABLED;

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

		r = CPU_SSE_ENABLED;
	}
	__except(1) { }
	return r;
}
#  endif
# endif
#endif


