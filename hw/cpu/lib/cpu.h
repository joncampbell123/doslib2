
#ifndef __DOSLIB2_HW_CPU_CPU_H
#define __DOSLIB2_HW_CPU_CPU_H

#if defined(TARGET_WINDOWS)
# include <windows.h>
#endif

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include <misc/useful.h>

#pragma pack(push,1)
struct cpu_info_t {
/* offset defines are necessary only because Watcom's stupid inline assembler does not support accessing structure members */
	signed char				cpu_basic_level;	/* +0 */
	signed char				cpu_basic_fpu_level;	/* +1 */
	uint16_t				cpu_flags;		/* +2 */
	uint16_t				cpu_type_and_mask;	/* +4 on 386/486 systems without CPUID, this contains type and stepping value (DX) */
	struct cpu_cpuid_info*			cpuid_info;		/* +6 */
								/* +8/+10 */
};

struct cpu_cpuid_generic_block {
	uint32_t				a,b,c,d;		/* EAX EBX ECX EDX */
};

struct cpu_cpuid_00000000_id_info {
	uint32_t				cpuid_max;		/* EAX */
	uint32_t				id_1,id_3,id_2;		/* EBX ECX EDX. id_1 id_2 id_3 becomes EBX EDX ECX. do NOT change member order */
};

/* see what I'm doing here? :)
 * it avoids the need for redunant assembly language when using CPUID
 * while bringing meaning to each field */
union cpu_cpuid_00000000_id_union {
	struct cpu_cpuid_generic_block		g;
	struct cpu_cpuid_00000000_id_info	i;
};

struct cpu_cpuid_00000001_id_features {
	/* EAX */
	uint16_t				stepping:4;		/* bits 0-3 */
	uint16_t				model:4;		/* bits 4-7 */
	uint16_t				family:4;		/* bits 8-11 */
	uint16_t				processor_type:2;	/* bits 12-13 */
	uint16_t				__undef_eax_15_14:2;	/* bits 14-15 */
	uint16_t				extended_model:4;	/* bits 16-19 */
	uint16_t				extended_family:8;	/* bits 20-27 */
	uint16_t				__undef_eax_31_28:4;	/* bits 28-31 */
	/* EBX */
	uint32_t				__undef_ebx;		/* bits 0-31 */
	/* ECX */
	uint16_t				c_sse3:1;		/* bit 0: SSE3, prescott new instructions */
	uint16_t				c_pclmulqdq:1;		/* bit 1: PCLMULQDQ */
	uint16_t				c_dtes64:1;		/* bit 2: dtes64 debug store (EDX bit 21) */
	uint16_t				c_monitor:1;		/* bit 3: MONITOR and MWAIT */
	uint16_t				c_ds_cpl:1;		/* bit 4: CPL qualified debug store */
	uint16_t				c_vmx:1;		/* bit 5: Virtual Machine eXtensions */
	uint16_t				c_smx:1;		/* bit 6: Safer Mode eXtensions */
	uint16_t				c_est:1;		/* bit 7: Enhanced SpeedStep */
	uint16_t				c_tm2:1;		/* bit 8: Thermal Monitor 2 */
	uint16_t				c_ssse3:1;		/* bit 9: Supplemental SSE3 instructions */
	uint16_t				c_cid:1;		/* bit 10: Context ID */
	uint16_t				_c_reserved_11:1;	/* bit 11 */
	uint16_t				c_fma:1;		/* bit 12: Fused multiply-add (FMA3) */
	uint16_t				c_cx16:1;		/* bit 13: CMPXCHG16B */
	uint16_t				c_xtpr:1;		/* bit 14: Can disable sending task priority messages */
	uint16_t				c_pdcm:1;		/* bit 15: Perfmon & debug capability */
	uint16_t				_c_reserved_16:1;	/* bit 16 */
	uint16_t				c_pcid:1;		/* bit 17: Process context identifiers (CR4 bit 17) */
	uint16_t				c_dca:1;		/* bit 18: Direct cache access for DMA writes */
	uint16_t				c_sse4_1:1;		/* bit 19: SSE4.1 instructions */
	uint16_t				c_sse4_2:1;		/* bit 20: SSE4.2 instructions */
	uint16_t				c_x2apic:1;		/* bit 21: x2APIC support */
	uint16_t				c_movbe:1;		/* bit 22: MOVBE instruction */
	uint16_t				c_popcnt:1;		/* bit 23: POPCNT instruction */
	uint16_t				c_tscdeadline:1;	/* bit 24: APIC supports one-shot operation using a TSC deadline value */
	uint16_t				c_aes:1;		/* bit 25: AES instruction set */
	uint16_t				c_xsave:1;		/* bit 26: XSAVE, XRESTOR, XSETBV, XGETBV */
	uint16_t				c_osxsave:1;		/* bit 27: XSAVE enabled by OS */
	uint16_t				c_avx:1;		/* bit 28: Advanced Vector Extensions */
	uint16_t				c_f16c:1;		/* bit 29: CVT16 instruction set (half precision) floating point support */
	uint16_t				c_rdrnd:1;		/* bit 30: RDRAND (on-chip random number generator) support */
	uint16_t				c_hypervisor:1;		/* bit 31: Running on a hypervisor (0 on a real CPU) */
	/* EDX */
	uint16_t				d_fpu:1;		/* bit 0: Onboard x87 FPU */
	uint16_t				d_vme:1;		/* bit 1: Virtual mode extensions (VIF) */
	uint16_t				d_de:1;			/* bit 2: Debugging extensions (CR4 bit 3) */
	uint16_t				d_pse:1;		/* bit 3: Page size extensions */
	uint16_t				d_tsc:1;		/* bit 4: Time stamp counter */
	uint16_t				d_msr:1;		/* bit 5: Model-specific registers */
	uint16_t				d_pae:1;		/* bit 6: Physical Address Extension */
	uint16_t				d_mce:1;		/* bit 7: Machine Check Exception */
	uint16_t				d_cx8:1;		/* bit 8: CMPXCHG8 */
	uint16_t				d_apic:1;		/* bit 9: Onboard APIC */
	uint16_t				_d_reserved_10:1;	/* bit 10 */
	uint16_t				d_sep:1;		/* bit 11: SYSENTER and SYSEXIT */
	uint16_t				d_mtrr:1;		/* bit 12: Memory Type Range Registers */
	uint16_t				d_pge:1;		/* bit 13: Page Global Enable bit in CR4 */
	uint16_t				d_mca:1;		/* bit 14: Machine check architecture */
	uint16_t				d_cmov:1;		/* bit 15: CMOV and FCMOV instructions */
	uint16_t				d_pat:1;		/* bit 16: Page Attribute Table */
	uint16_t				d_pse36:1;		/* bit 17: 36-bit page table extension */
	uint16_t				d_pn:1;			/* bit 18: Processor serial number */
	uint16_t				d_clflush:1;		/* bit 19: CLFLUSH (SSE2 */
	uint16_t				_d_reserved_20:1;	/* bit 20 */
	uint16_t				d_dts:1;		/* bit 21: Debug store: save trace of executed jumps */
	uint16_t				d_acpi:1;		/* bit 22: Onboard thermal control MSRs for ACPI */
	uint16_t				d_mmx:1;		/* bit 23: MMX instructions */
	uint16_t				d_fxsr:1;		/* bit 24: FXSAVE, FXRESTOR instructions CR4 bit 9 */
	uint16_t				d_sse:1;		/* bit 25: SSE instructions */
	uint16_t				d_sse2:1;		/* bit 26: SSE2 instructions */
	uint16_t				d_ss:1;			/* bit 27: CPU supports Self Snoop */
	uint16_t				d_ht:1;			/* bit 28: Hyper threading */
	uint16_t				d_tm:1;			/* bit 29: Thermal monitoring automatically limits temp */
	uint16_t				d_ia64:1;		/* bit 30: IA64 processor emulating x86 */
	uint16_t				d_pbe:1;		/* bit 31: Pending Break Enable (PBE# pin) wakeup support */
};

union cpu_cpuid_00000001_id_union {
	struct cpu_cpuid_generic_block		g;
	struct cpu_cpuid_00000001_id_features	f;
};

struct cpu_cpuid_80000000_id_info {
	uint32_t				cpuid_max;		/* EAX */
	uint32_t				b,c,d;			/* other regs... unknown what they contain */
};

union cpu_cpuid_80000000_id_union {
	struct cpu_cpuid_generic_block		g;
	struct cpu_cpuid_80000000_id_info	i;
};

struct cpu_cpuid_80000001_id_features {
	/* EAX */
	uint16_t				stepping:4;		/* bits 0-3 */
	uint16_t				model:4;		/* bits 4-7 */
	uint16_t				family:4;		/* bits 8-11 */
	uint16_t				processor_type:2;	/* bits 12-13 */
	uint16_t				__undef_eax_15_14:2;	/* bits 14-15 */
	uint16_t				extended_model:4;	/* bits 16-19 */
	uint16_t				extended_family:8;	/* bits 20-27 */
	uint16_t				__undef_eax_31_28:4;	/* bits 28-31 */
	/* EBX */
	uint32_t				__undef_ebx;		/* bits 0-31 */
	/* ECX */
	uint16_t				c_ahf64:1;		/* bit 0: LAHF + SAHF available in amd64 */
	uint16_t				c_cmp:1;		/* bit 1: HTT=1 indicates HTT (0) or CMP (1) (?what does that mean?) */
	uint16_t				c_svm:1;		/* bit 2: EFER.SVME, VMRUN, VMMCALL, VMLOAD, VMSAVE, STGI, and CLGI, SKINIT, INVLPGA */
	uint16_t				c_eas:1;		/* bit 3: Extended APIC space */
	uint16_t				c_cr8d:1;		/* bit 4: MOV from/to CR8D using LOCK MOV from/to CR0 */
	uint16_t				c_lzcnt:1;		/* bit 5: LZCNT */
	uint16_t				c_sse4a:1;		/* bit 6: SSE4A */
	uint16_t				c_msse:1;		/* bit 7: misaligned SSE, MXCSR.MM */
	uint16_t				c_3dnow_prefetch:1;	/* bit 8: PREFETCH and PREFETCHW 3DNow! */
	uint16_t				c_osvw:1;		/* bit 9: OS visible workaround (?) */
	uint16_t				c_ibs:1;		/* bit 10: Instruction based sampling */
	uint16_t				c_xop:1;		/* bit 11: XOP instructions */
	uint16_t				c_skinit:1;		/* bit 12: SKINIT, STGI, DEV */
	uint16_t				c_wdt:1;		/* bit 13: Watchdog timer */
	uint16_t				_c_reserved_14:1;	/* bit 14 */
	uint16_t				c_lwp:1;		/* bit 15: LWP (?) */
	uint16_t				c_fma4:1;		/* bit 16: FMA4 */
	uint16_t				c_tce:1;		/* bit 17: Translation cache extension */
	uint16_t				_c_reserved_18:1;	/* bit 18 */
	uint16_t				c_nodeid:1;		/* bit 19: Node ID in MSR 0xC001100C */
	uint16_t				_c_reserved_20:1;	/* bit 20 */
	uint16_t				c_tbm:1;		/* bit 21: TBM (?) */
	uint16_t				c_topx:1;		/* bit 22: Topology extensions: extended levels 0x8000001D and 0x8000001E */
	uint16_t				c_pcx_core:1;		/* bit 23: core perf counter extensions */
	uint16_t				c_pcx_nb:1;		/* bit 24: nb perf counter extensions */
	uint16_t				_c_reserved_25:1;	/* bit 25 */
	uint16_t				_c_reserved_26:1;	/* bit 26 */
	uint16_t				_c_reserved_27:1;	/* bit 27 */
	uint16_t				_c_reserved_28:1;	/* bit 28 */
	uint16_t				_c_reserved_29:1;	/* bit 29 */
	uint16_t				_c_reserved_30:1;	/* bit 30 */
	uint16_t				_c_reserved_31:1;	/* bit 31 */
	/* EDX */
	uint16_t				d_fpu:1;		/* bit 0: Onboard x87 FPU */
	uint16_t				d_vme:1;		/* bit 1: Virtual mode extensions (VIF) */
	uint16_t				d_de:1;			/* bit 2: Debugging extensions (CR4 bit 3) */
	uint16_t				d_pse:1;		/* bit 3: Page size extensions */
	uint16_t				d_tsc:1;		/* bit 4: Time stamp counter */
	uint16_t				d_msr:1;		/* bit 5: Model-specific registers */
	uint16_t				d_pae:1;		/* bit 6: Physical Address Extension */
	uint16_t				d_mce:1;		/* bit 7: Machine Check Exception */
	uint16_t				d_cx8:1;		/* bit 8: CMPXCHG8 */
	uint16_t				d_apic:1;		/* bit 9: Onboard APIC */
	uint16_t				_d_reserved_10:1;	/* bit 10 */
	uint16_t				d_sep:1;		/* bit 11: SYSENTER and SYSEXIT */
	uint16_t				d_mtrr:1;		/* bit 12: Memory Type Range Registers */
	uint16_t				d_pge:1;		/* bit 13: Page Global Enable bit in CR4 */
	uint16_t				d_mca:1;		/* bit 14: Machine check architecture */
	uint16_t				d_cmov:1;		/* bit 15: CMOV and FCMOV instructions */
	uint16_t				d_pat:1;		/* bit 16: Page Attribute Table */
	uint16_t				d_pse36:1;		/* bit 17: 36-bit page table extension */
	uint16_t				_d_reserved_18:1;	/* bit 18 */
	uint16_t				d_mp:1;			/* bit 19: MP capable */
	uint16_t				d_nx:1;			/* bit 20: NX (No execute) */
	uint16_t				_d_reserved_21:1;	/* bit 21 */
	uint16_t				d_mmxplus:1;		/* bit 22: AMD MMX+ */
	uint16_t				d_mmx:1;		/* bit 23: MMX instructions */
	uint16_t				d_fxsr:1;		/* bit 24: FXSAVE, FXRESTOR instructions CR4 bit 9 or Cyrix MMX+ */
	uint16_t				d_ffxsr:1;		/* bit 25: FFXSR */
	uint16_t				d_pg1g:1;		/* bit 26: PG1G (1GB pages?) */
	uint16_t				d_tscp:1;		/* bit 27: TSC, TSC_AUX, RDTSCP, CR4.TSD */
	uint16_t				_d_reserved_28:1;	/* bit 28 */
	uint16_t				d_lm:1;			/* bit 29: AMD64 long mode */
	uint16_t				d_3dnowplus:1;		/* bit 30: 3DNow!+ */
	uint16_t				d_3dnow:1;		/* bit 31: 3DNow! */
};

union cpu_cpuid_80000001_id_union {
	struct cpu_cpuid_generic_block		g;
	struct cpu_cpuid_80000001_id_features	f;
};

struct cpu_cpuid_info {
	union cpu_cpuid_00000000_id_union	e0;		/* CPUID 0x00000000 CPU identification */
	union cpu_cpuid_00000001_id_union	e1;		/* CPUID 0x00000001 CPU ID and features */
	union cpu_cpuid_80000000_id_union	e80000000;	/* CPUID 0x80000000 CPU ext. identification */
	union cpu_cpuid_80000001_id_union	e80000001;	/* CPUID 0x80000001 CPU ID and features */
	struct cpu_cpuid_generic_block		e80000002;	/* CPUID 0x80000002 CPU extended ID, first 1/3 of string */
	struct cpu_cpuid_generic_block		e80000003;	/* CPUID 0x80000003 CPU extended ID, first 2/3 of string */
	struct cpu_cpuid_generic_block		e80000004;	/* CPUID 0x80000004 CPU extended ID, first 3/3 of string */
	unsigned char				phys_addr_bits;	/* physical address bits supported by CPU */
	unsigned char				virt_addr_bits;	/* virtual address bits supported by CPU */
	unsigned char				guest_phys_addr_bits; /* guest physical address bits */
	unsigned char				cpu_cores;	/* if CPU actually provides it, number of cores on this CPU */
	unsigned char				cpu_acpi_id_bits;
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

extern struct cpu_info_t cpu_info;

/* CPU ID string buffer length expected: 12 bytes for 3 DWORDs plus ASCIIZ NUL */
#define CPU_ID_STRING_LENGTH 13

/* extended CPU id string buffer length extended: 48 bytes for 4 x 3 DWORDs plus ASCIIZ NUL */
#define CPU_EXT_ID_STRING_LENGTH 49

#if defined(TARGET_MSDOS) || defined(TARGET_WINDOWS)
static unsigned short read_cs_sreg();
#pragma aux read_cs_sreg = \
	"mov ax,cs" value [ax]
static unsigned int read_cr4i_creg();
# if TARGET_BITS == 32
#  pragma aux read_cr4i_creg = \
	".386p" \
	"mov eax,cr4" value [eax]
# else
#  pragma aux read_cr4i_creg = \
	".386p" \
	"mov eax,cr4" value [ax]
# endif
#endif

static void _sse_enable();
#pragma aux _sse_enable = \
	".386p" \
	"mov eax,cr4" \
	"or eax,0x200" \
	"mov cr4,eax"

static void _sse_disable();
#pragma aux _sse_disable = \
	".386p" \
	"mov eax,cr4" \
	"and eax,0xFFFFFDFF" \
	"mov cr4,eax"

/* CPUID function. To avoid redundant asm blocks */
#if TARGET_BITS == 64
# if defined(__GNUC__)
void do_cpuid(const uint32_t select,struct cpu_cpuid_generic_block *b);
# else
void _cdecl do_cpuid(const uint32_t select,struct cpu_cpuid_generic_block *b);
# endif
#elif TARGET_BITS == 32
# if defined(__GNUC__)
void do_cpuid(const uint32_t select,struct cpu_cpuid_generic_block *b);
# else
void _cdecl do_cpuid(const uint32_t select,struct cpu_cpuid_generic_block *b);
# endif
#elif TARGET_BITS == 16
void _cdecl do_cpuid(const uint32_t select,struct cpu_cpuid_generic_block FAR *b);
#endif

#if defined(__GNUC__)
# if TARGET_BITS == 16 || TARGET_BITS == 32
unsigned int probe_basic_fpu_287_387();
unsigned int probe_basic_cpu_345_86();
unsigned int probe_basic_has_fpu();
# endif
#else
# if TARGET_BITS == 16
unsigned int _cdecl probe_basic_cpu_0123_86();
# endif
# if TARGET_BITS == 16 || TARGET_BITS == 32
unsigned int _cdecl probe_basic_fpu_287_387();
unsigned int _cdecl probe_basic_cpu_345_86();
unsigned int _cdecl probe_basic_has_fpu();
# endif
#endif

void cpu_copy_id_string(char *tmp/*must be CPU_ID_STRING_LENGTH or more*/,struct cpu_cpuid_00000000_id_info *i);
char *cpu_copy_ext_id_string(char *tmp/*CPU_EXT_ID_STRING_LENGTH*/,struct cpu_cpuid_info *i);
void probe_cpu();

/* for 8086 target, or 286 targets assuming protected mode, this becomes a macro */
#if TARGET_BITS == 16 && (TARGET_CPU == 0 || (TARGET_CPU == 2 && defined(TARGET_PROTMODE)))
# define cpu_meets_compile_target() (1)
# define cpu_err_out_requirements() { }
#elif TARGET_BITS == 32 && TARGET_CPU == 3
# define cpu_meets_compile_target() (1)
# define cpu_err_out_requirements() { }
#elif TARGET_BITS == 64 && TARGET_CPU == 6
# define cpu_meets_compile_target() (1)
# define cpu_err_out_requirements() { }
#else
unsigned int cpu_meets_compile_target();
void cpu_err_out_requirements();
#endif

#endif /* __DOSLIB2_HW_CPU_CPU_H */

