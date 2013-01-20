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
#include <hw/cpu/cpusse.h>
#include <misc/useful.h>
#include <hw/cpu/dpmi.h>

int main(int argc,char **argv,char **envp) {
	probe_cpu();

	if (!cpu_meets_compile_target()) {
		cpu_err_out_requirements();
		return -1;
	}

	if (argc > 1) {
		if (!strcmp(argv[1],"?")) {
			fprintf(stderr,"test                         Show all CPU info\n");
			fprintf(stderr,"test sse                     Turn on SSE extensions\n");
			fprintf(stderr,"test sseoff                  Turn off SSE extensions\n");
		}
		else if (!strcmp(argv[1],"sse")) {
			probe_cpu_sse();

			if (!(cpu_sse_flags & CPU_SSE_SUPPORTED)) {
				printf(" - CPU does not support SSE\n");
				return 1;
			}
			if (!(cpu_sse_flags & CPU_SSE_CAN_ENABLE)) {
				if (cpu_sse_flags & CPU_SSE_ENABLED)
					printf(" - SSE is already enabled, though I cannot enable it\n");
				else
					printf(" - This program cannot enable SSE\n");

				return 1;
			}
			if (cpu_sse_flags & CPU_SSE_ENABLED)
				printf(" - CPU SSE extensions are already enabled, this will enable again\n");
			if (cpu_sse_flags & CPU_SSE_EXCEPTIONS_ENABLED)
				printf(" - CPU SSE exceptions are already enabled\n");

			if (!cpu_sse_enable())
				printf(" ! Unable to enable SSE\n");
		}
		else if (!strcmp(argv[1],"sseoff")) {
			probe_cpu_sse();

			if (!(cpu_sse_flags & CPU_SSE_SUPPORTED)) {
				printf(" - CPU does not support SSE\n");
				return 1;
			}
			if (!(cpu_sse_flags & CPU_SSE_CAN_DISABLE)) {
				if (!(cpu_sse_flags & CPU_SSE_ENABLED))
					printf(" - SSE is already disabled, though I cannot disable it\n");
				else
					printf(" - This program cannot disable SSE\n");

				return 1;
			}
			if (!(cpu_sse_flags & CPU_SSE_ENABLED))
				printf(" - CPU SSE extensions are already disabled\n");

			if (!cpu_sse_disable())
				printf(" ! Unable to disable SSE\n");
		}

		return 1;
	}

	printf("CPU level: %d\n",cpu_info.cpu_basic_level);
	if (cpu_info.cpu_flags & CPU_FLAG_FPU) printf("- FPU is present, level %d\n",cpu_info.cpu_basic_fpu_level);
	if (cpu_info.cpu_flags & CPU_FLAG_V86) printf("- Virtual 8086 mode is active\n");
	if (cpu_info.cpu_flags & CPU_FLAG_CPUID) printf("- CPUID is present\n");
	if (cpu_info.cpu_flags & CPU_FLAG_PROTMODE) printf("- Protected mode is active\n");

	if (cpu_info.cpuid_info != NULL) {
		char tmp[64];

		cpu_copy_id_string(tmp,&(cpu_info.cpuid_info->e0.i));
		printf("CPUID info available: max=%08lX ext_max=0x%08lX id='%s'\n",
			(unsigned long)cpu_info.cpuid_info->e0.i.cpuid_max,
			(unsigned long)cpu_info.cpuid_info->e80000000.i.cpuid_max,
			tmp);

		if (cpu_info.cpuid_info->e0.i.cpuid_max >= 1) {
			printf(" - Stepping %u model %u family %u processor_type %u ext-family %u\n",
				cpu_info.cpuid_info->e1.f.stepping,
				cpu_info.cpuid_info->e1.f.model + (cpu_info.cpuid_info->e1.f.extended_model << 4),
				cpu_info.cpuid_info->e1.f.family,
				cpu_info.cpuid_info->e1.f.processor_type,
				cpu_info.cpuid_info->e1.f.extended_family);
			printf("   - RAW: ABCD %08lX %08lX %08lX %08lX\n",
				(unsigned long)cpu_info.cpuid_info->e1.g.a,
				(unsigned long)cpu_info.cpuid_info->e1.g.b,
				(unsigned long)cpu_info.cpuid_info->e1.g.c,
				(unsigned long)cpu_info.cpuid_info->e1.g.d);
			printf("   - ECX: ");
/* Save my wrists and avoid copypasta! */
#define _(x) if (cpu_info.cpuid_info->e1.f.c_##x) { printf(cpp_stringify(x) " "); }
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
#define _(x) if (cpu_info.cpuid_info->e1.f.d_##x) { printf(cpp_stringify(x) " "); }
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

		if (cpu_info.cpuid_info->e80000000.i.cpuid_max >= 0x80000001) {
			printf(" - Ext. stepping %u model %u family %u processor_type %u ext-family %u\n",
				cpu_info.cpuid_info->e80000001.f.stepping,
				cpu_info.cpuid_info->e80000001.f.model + (cpu_info.cpuid_info->e80000001.f.extended_model << 4),
				cpu_info.cpuid_info->e80000001.f.family,
				cpu_info.cpuid_info->e80000001.f.processor_type,
				cpu_info.cpuid_info->e80000001.f.extended_family);
			printf("   - RAW: ABCD %08lX %08lX %08lX %08lX\n",
				(unsigned long)cpu_info.cpuid_info->e80000001.g.a,
				(unsigned long)cpu_info.cpuid_info->e80000001.g.b,
				(unsigned long)cpu_info.cpuid_info->e80000001.g.c,
				(unsigned long)cpu_info.cpuid_info->e80000001.g.d);
			printf("   - ECX: ");
/* Save my wrists and avoid copypasta! */
#define _(x) if (cpu_info.cpuid_info->e80000001.f.c_##x) { printf(cpp_stringify(x) " "); }
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
#define _(x) if (cpu_info.cpuid_info->e80000001.f.d_##x) { printf(cpp_stringify(x) " "); }
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

		if (cpu_info.cpuid_info->e80000000.i.cpuid_max >= 0x80000004) {
			printf(" - Extended CPU id '%s'\n",cpu_copy_ext_id_string(tmp,cpu_info.cpuid_info));
		}

		printf(" - CPU address bits: physical=%u virtual=%u guest=%u\n",
			cpu_info.cpuid_info->phys_addr_bits,
			cpu_info.cpuid_info->virt_addr_bits,
			cpu_info.cpuid_info->guest_phys_addr_bits);

		if (cpu_info.cpuid_info->e80000000.i.cpuid_max >= 0x80000008) {
			/* TODO: If this field is the number of cores, then why do most systems so
			 *       far report 1 (field is zero)? */
			printf(" - cores=%u acpi_id_bits=%u\n",
				cpu_info.cpuid_info->cpu_cores,
				cpu_info.cpuid_info->cpu_acpi_id_bits);
		}

		/* detecting SSE by CPUID is not enough, the OS must have enabled it.
		 * if we're in pure 16-bit real mode, then it's probably NOT enabled but
		 * we're free to enable it ourselves.
		 *
		 * The detection process is NOT carried out by default. most of these
		 * projects aren't going to use SSE anyway. we don't want SSE support
		 * bloating up the core library, nor do we want possible instability
		 * involved in detecting SSE when the program will not use it anyway. */
		probe_cpu_sse();
		if (cpu_sse_flags & CPU_SSE_SUPPORTED)
			printf(" - CPU supports SSE\n");
		if (cpu_sse_flags & CPU_SSE_ENABLED)
			printf(" - CPU SSE extensions are enabled\n");
		if (cpu_sse_flags & CPU_SSE_EXCEPTIONS_ENABLED)
			printf(" - CPU SSE exceptions are enabled\n");
		if (cpu_sse_flags & CPU_SSE_CAN_ENABLE)
			printf(" - This program can enable SSE if needed\n");
		if (cpu_sse_flags & CPU_SSE_CAN_DISABLE)
			printf(" - This program can disable SSE if needed\n");
	}
	else if (cpu_info.cpu_type_and_mask != 0) {
		/* FIXME: Dig out your ancient 386/486 systems and test that this code gets some actual values */
		printf(" - CPU type=0x%02X maskrev=0x%02x\n",cpu_info.cpu_type_and_mask>>8,cpu_info.cpu_type_and_mask&0xFF);
	}

#ifdef DOS_DPMI_AVAILABLE
	dos_dpmi_probe();
	if (dos_dpmi_state.flags & DPMI_SERVER_PRESENT) {
		printf("DPMI server present\n");
		printf("  Flags: ");
		if (dos_dpmi_state.flags & DPMI_SERVER_INIT) printf("INIT ");
		if (dos_dpmi_state.flags & DPMI_SERVER_CAN_DO_32BIT) printf("CAN_DO_32BIT ");
		if (dos_dpmi_state.flags & DPMI_SERVER_INIT_32BIT) printf("INIT_32BIT ");
		printf("\n");
		printf("  Entry point: %04x:%04x\n",dos_dpmi_state.entry_cs,dos_dpmi_state.entry_ip);
		printf("  Private size: %u paragraphs at 0x%04x\n",dos_dpmi_state.dpmi_private_size,dos_dpmi_state.dpmi_private_segment);
		printf("  Version: %u.%02u\n",dos_dpmi_state.dpmi_version>>8,dos_dpmi_state.dpmi_version&0xFF);
		printf("  CPU: %u\n",dos_dpmi_state.dpmi_processor);
		if (dos_dpmi_state.flags & DPMI_SERVER_INIT) {
			printf("  DPMI CS=0x%04x DS=0x%04x ES=0x%04x SS=0x%04x\n",
				dos_dpmi_state.dpmi_cs,
				dos_dpmi_state.dpmi_ds,
				dos_dpmi_state.dpmi_es,
				dos_dpmi_state.dpmi_ss);
			printf("  DPMI real-to-prot: %04x:%04x\n",
				dos_dpmi_state.r2p_entry_cs,
				dos_dpmi_state.r2p_entry_ip);
			if (dos_dpmi_state.flags & DPMI_SERVER_INIT_32BIT) {
				printf("  DPMI prot-to-real[16]: %04x:%04x%04x\n",
					dos_dpmi_state.p2r_entry[2],
					dos_dpmi_state.p2r_entry[1],
					dos_dpmi_state.p2r_entry[0]);
			}
			else {
				printf("  DPMI prot-to-real[16]: %04x:%04x\n",
					dos_dpmi_state.p2r_entry[1],
					dos_dpmi_state.p2r_entry[0]);
			}
		}
	}
#endif

#ifdef WIN_STDOUT_CONSOLE
	_win_endloop_user_echo();
#endif
	return 0;
}

