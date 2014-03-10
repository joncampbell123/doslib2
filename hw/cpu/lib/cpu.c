#if defined(TARGET_WINDOWS)
# include <windows.h>
# include <windows/apihelp.h>
#endif

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <misc/useful.h>
#include <hw/cpu/lib/cpu.h>

struct cpu_info_t cpu_info = {
	-1,		/* cpu basic level */
	-1,		/* cpu basic FPU level */
	0,		/* flags */
	0,		/* cpu_type_and_mask */
	NULL		/* cpu_cpuid_info */
};

/* Possible values of cpu_type_and_mask (if it worked):
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
 *     For complete list see [http://www.intel-assembler.it/portale/5/identify_cpu/386ID_four_ways_to_identify_your_cpu.asp]
 */

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
	struct cpu_cpuid_generic_block tmp;

	if (cpu_info.cpuid_info != NULL) return;

	cpu_info.cpuid_info = malloc(sizeof(*cpu_info.cpuid_info));
	if (cpu_info.cpuid_info == NULL) return;
	memset(cpu_info.cpuid_info,0,sizeof(*cpu_info.cpuid_info));

	/* alright then, let's ask the CPU it's identification */
	do_cpuid(0x00000000,&(cpu_info.cpuid_info->e0.g)); /* NTS: e0.g aliases over e0.i and fills in info */

	/* if we didn't get anything, then CPUID is not functional */
	if (cpu_info.cpuid_info->e0.i.cpuid_max == 0) {
		cpu_info.cpu_flags &= ~CPU_FLAG_CPUID;
		free(cpu_info.cpuid_info);
		return;
	}

	if (cpu_info.cpuid_info->e0.i.cpuid_max >= 1) {
		do_cpuid(0x00000001,&(cpu_info.cpuid_info->e1.g));
		if (cpu_info.cpuid_info->e1.f.family >= 4 && cpu_info.cpuid_info->e1.f.family <= 6)
			cpu_info.cpu_basic_level = cpu_info.cpuid_info->e1.f.family;

		/* now check for the extended CPUID. it is said that in the original
		 * Pentium ranges 0x80000000-0x8000001F respond exactly the same as
		 * 0x00000000-0x0000001F */
		do_cpuid(0x80000000,&(cpu_info.cpuid_info->e80000000.g));
		if (cpu_info.cpuid_info->e80000000.i.cpuid_max < 0x80000000)
			cpu_info.cpuid_info->e80000000.i.cpuid_max = 0;
		else if (cpu_info.cpuid_info->e80000000.i.cpuid_max >= 0x80000001)
			do_cpuid(0x80000001,&(cpu_info.cpuid_info->e80000001.g));
	}

	/* extended CPU id string */
	if (cpu_info.cpuid_info->e80000000.i.cpuid_max >= 0x80000004) {
		do_cpuid(0x80000002,&(cpu_info.cpuid_info->e80000002));
		do_cpuid(0x80000003,&(cpu_info.cpuid_info->e80000003));
		do_cpuid(0x80000004,&(cpu_info.cpuid_info->e80000004));
	}

	/* modern CPUs report the largest physical address, virtual address, etc. */
	if (cpu_info.cpuid_info->e80000000.i.cpuid_max >= 0x80000008) {
		do_cpuid(0x80000008,&tmp);
		cpu_info.cpuid_info->phys_addr_bits = tmp.a & 0xFF;
		cpu_info.cpuid_info->virt_addr_bits = (tmp.a >> 8) & 0xFF;
		cpu_info.cpuid_info->guest_phys_addr_bits = (tmp.a >> 16) & 0xFF;
		if (cpu_info.cpuid_info->guest_phys_addr_bits == 0)
			cpu_info.cpuid_info->guest_phys_addr_bits = cpu_info.cpuid_info->phys_addr_bits;

		cpu_info.cpuid_info->cpu_cores = (tmp.c & 0xFF) + 1;
		if (tmp.c & 0xF000) cpu_info.cpuid_info->cpu_acpi_id_bits = 1 << (((tmp.c >> 12) & 0xF) - 1);
	}
	/* we have to guess for older CPUs */
	else {
		/* If CPU supports long mode, then assume 40 bits */
		if (cpu_info.cpuid_info->e80000001.f.d_lm) {
			cpu_info.cpuid_info->phys_addr_bits = 40;
			cpu_info.cpuid_info->virt_addr_bits = 40;
		}
		/* If CPU supports PSE36, then assume 36 bits */
		else if (cpu_info.cpuid_info->e1.f.d_pse36) {
			cpu_info.cpuid_info->phys_addr_bits = 36;
			cpu_info.cpuid_info->virt_addr_bits = 36;
		}
		else {
			cpu_info.cpuid_info->phys_addr_bits = 32;
			cpu_info.cpuid_info->virt_addr_bits = 32;
		}

		cpu_info.cpuid_info->guest_phys_addr_bits = cpu_info.cpuid_info->phys_addr_bits;
	}
}

static void probe_fpu() {
	/* If CPUID is available and reports an FPU, then assume
	 * FPU is present (integrated into the CPU) and do not test.
	 * Carry out the test if CPUID does not report one. */
	if ((cpu_info.cpu_flags & CPU_FLAG_CPUID) && cpu_info.cpuid_info != NULL) {
		if (cpu_info.cpuid_info->e1.f.d_fpu) {
			cpu_info.cpu_basic_fpu_level = cpu_info.cpu_basic_level;
			cpu_info.cpu_flags |= CPU_FLAG_FPU;
			return;
		}
	}

	if (probe_basic_has_fpu()) {
		cpu_info.cpu_basic_fpu_level = cpu_info.cpu_basic_level;
		cpu_info.cpu_flags |= CPU_FLAG_FPU;

		/* it is said that the 386 was pairable with the 287 or the 387. */
		if (cpu_info.cpu_basic_level == 3)
			cpu_info.cpu_basic_fpu_level = probe_basic_fpu_287_387();
	}
}

static void probe_basic_cpu_level() {
	unsigned char level,flags;
	unsigned int dtmp;

#if TARGET_BITS == 32 /* 32-bit DOS, Linux i386, Win32, etc... */
	dtmp = probe_basic_cpu_345_86();
	level = dtmp & 0xFF;
	flags = (dtmp >> 8U) | CPU_FLAG_PROTMODE;
#elif TARGET_BITS == 16
/* ======================= 16-bit realmode DOS / real/protected mode Windows =================== */
	dtmp = probe_basic_cpu_0123_86();
	level = dtmp & 0xFF;
	flags = dtmp >> 8U;

	if (level == 3) {
		dtmp = probe_basic_cpu_345_86();
		level = dtmp & 0xFF;
		flags |= dtmp >> 8U;
	}
#endif /* TARGET_BITS */

	cpu_info.cpu_flags = flags;
	cpu_info.cpu_basic_level = level;
	if (cpu_info.cpu_flags & CPU_FLAG_CPUID)
		probe_cpuid();
}

void probe_cpu() {
	if (cpu_info.cpu_basic_level < 0) {
		probe_basic_cpu_level();
		probe_fpu();
	}
}

#ifndef cpu_meets_compile_target
unsigned int cpu_meets_compile_target() {
	if (cpu_info.cpu_basic_level < 0) probe_cpu();
	return (cpu_info.cpu_basic_level >= TARGET_CPU)?1:0;
}
#endif

#ifndef cpu_err_out_requirements
void cpu_err_out_requirements() {
	static char msg[] = "This program requires a " _cpp_stringify_num(TARGET_CPU) "86 CPU or better.\r\n";
	write(2/*STDERR*/,msg,sizeof(msg));
}
#endif

