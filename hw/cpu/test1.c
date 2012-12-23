#if defined(TARGET_WINDOWS)
# include <windows.h>
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

#include <hw/cpu/cpu.h>

#include <misc/useful.h>

int main() {
	probe_cpu();
	printf("CPU level: %d\n",cpu_basic_level);
	if (cpu_flags & CPU_FLAG_FPU) printf("- FPU is present, level %d\n",cpu_basic_fpu_level);
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

		if (cpuid_info->e80000000.i.cpuid_max >= 0x80000008) {
			/* TODO: If this field is the number of cores, then why do most systems so
			 *       far report 1 (field is zero)? */
			printf(" - cores=%u acpi_id_bits=%u\n",
				cpuid_info->cpu_cores,
				cpuid_info->cpu_acpi_id_bits);
		}
	}
	else if (cpu_type_and_mask != 0) {
		/* FIXME: Dig out your ancient 386/486 systems and test that this code gets some actual values */
		printf(" - CPU type=0x%02X maskrev=0x%02x\n",cpu_type_and_mask>>8,cpu_type_and_mask&0xFF);
	}

#ifdef WIN_STDOUT_CONSOLE
	_win_endloop_user_echo();
#endif
	return 0;
}

