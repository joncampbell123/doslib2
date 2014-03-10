
#ifndef __DOSLIB2_HW_CPU_CPUSSE_H
#define __DOSLIB2_HW_CPU_CPUSSE_H

#if defined(TARGET_WINDOWS)
# include <windows.h>
#endif

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <misc/useful.h>
#include <hw/cpu/lib/cpu.h>

#define CPU_SSE_SUPPORTED		0x01
#define CPU_SSE_ENABLED			0x02
#define CPU_SSE_EXCEPTIONS_ENABLED	0x04
#define CPU_SSE_CAN_ENABLE		0x08
#define CPU_SSE_CAN_DISABLE		0x10
#define CPU_SSE_NOT_YET_DETECTED	0x80

extern unsigned char cpu_sse_flags;

void probe_cpu_sse();
void reset_cpu_sse_flags();
unsigned int cpu_sse_enable();
unsigned int cpu_sse_disable();

# if defined(TARGET_LINUX)
unsigned int cpu_sse_linux_test();
# endif

# if TARGET_BITS == 32
#  if defined(TARGET_WINDOWS)
#   if !defined(TARGET_WINDOWS_WIN386)
unsigned int _win32_test_sse();
#   endif
#  endif
# endif
	
#endif /* __DOSLIB2_HW_CPU_CPUSSE_H */

