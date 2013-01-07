
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
#include <hw/cpu/cpu.h>
#include <misc/useful.h>

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

#endif /* __DOSLIB2_HW_CPU_CPUSSE_H */

