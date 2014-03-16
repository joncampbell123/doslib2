
#include <stdint.h>

#pragma pack(push,1)
typedef struct tf8086_record {
	uint16_t			r_recid;
	uint16_t			r_reclen;
	uint16_t			r_di;
	uint16_t			r_si;
	uint16_t			r_bp;
	uint16_t			r_sp;
	uint16_t			r_bx;
	uint16_t			r_dx;
	uint16_t			r_cx;
	uint16_t			r_ax;
	uint16_t			r_flags;
	uint16_t			r_ip;
	uint16_t			r_cs;
	uint16_t			r_ss;
	uint16_t			r_ds;
	uint16_t			r_es;
	unsigned char			r_csip_capture[4];
	unsigned char			r_sssp_capture[4];
} tf8086_record; /* 40 bytes */
#pragma pack(pop)

#pragma pack(push,1)
typedef struct tf286_record {
	uint16_t			r_recid;
	uint16_t			r_reclen;
	uint16_t			r_di;
	uint16_t			r_si;
	uint16_t			r_bp;
	uint16_t			r_sp;
	uint16_t			r_bx;
	uint16_t			r_dx;
	uint16_t			r_cx;
	uint16_t			r_ax;
	uint16_t			r_flags;
	uint16_t			r_ip;
	uint16_t			r_cs;
	uint16_t			r_ss;
	uint16_t			r_ds;
	uint16_t			r_es;
	unsigned char			r_csip_capture[4];
	unsigned char			r_sssp_capture[4];
	uint16_t			r_msw;
	uint16_t			r_gdtr[3];
	uint16_t			r_idtr[3];
	uint16_t			r_ldtr;
} tf286_record; /* 56 bytes */
#pragma pack(pop)

#pragma pack(push,1)
typedef struct tf386_record {
	uint16_t			r_recid;
	uint16_t			r_reclen;
	uint32_t			r_edi;
	uint32_t			r_esi;
	uint32_t			r_ebp;
	uint32_t			r_esp;
	uint32_t			r_ebx;
	uint32_t			r_edx;
	uint32_t			r_ecx;
	uint32_t			r_eax;
	uint32_t			r_eflags;
	uint32_t			r_eip;
	uint32_t			r_cr0;
	uint32_t			r_cr2;
	uint32_t			r_cr3;
	uint32_t			r_cr4;
	uint32_t			r_dr0;
	uint32_t			r_dr1;
	uint32_t			r_dr2;
	uint32_t			r_dr3;
	uint32_t			r_dr6;
	uint32_t			r_dr7;
	uint16_t			r_cs;
	uint16_t			r_ss;
	uint16_t			r_ds;
	uint16_t			r_es;
	uint16_t			r_fs;
	uint16_t			r_gs;
	uint16_t			r_gdtr[3];
	uint16_t			r_idtr[3];
	uint16_t			r_ldtr;
	unsigned char			r_csip_capture[4];
	unsigned char			r_sssp_capture[4];
} tf386_record; /* 118 bytes */
#pragma pack(pop)

#pragma pack(push,1)
typedef struct tf87_fp80 {
	unsigned char			b[10];
} tf87_fp80; /* 10 bytes */
#pragma pack(pop)

#pragma pack(push,1)
typedef struct tf387_record {
	uint16_t			r_recid;
	uint16_t			r_reclen;
	uint32_t			r_edi;
	uint32_t			r_esi;
	uint32_t			r_ebp;
	uint32_t			r_esp;
	uint32_t			r_ebx;
	uint32_t			r_edx;
	uint32_t			r_ecx;
	uint32_t			r_eax;
	uint32_t			r_eflags;
	uint32_t			r_eip;
	uint32_t			r_cr0;
	uint32_t			r_cr2;
	uint32_t			r_cr3;
	uint32_t			r_cr4;
	uint32_t			r_dr0;
	uint32_t			r_dr1;
	uint32_t			r_dr2;
	uint32_t			r_dr3;
	uint32_t			r_dr6;
	uint32_t			r_dr7;
	uint16_t			r_cs;
	uint16_t			r_ss;
	uint16_t			r_ds;
	uint16_t			r_es;
	uint16_t			r_fs;
	uint16_t			r_gs;
	uint16_t			r_gdtr[3];
	uint16_t			r_idtr[3];
	uint16_t			r_ldtr;
	unsigned char			r_csip_capture[4];
	unsigned char			r_sssp_capture[4];
	uint16_t			f_cw;			/* FPU control word */
	uint16_t			f_sw;			/* FPU status word */
	uint16_t			f_tagw;			/* FPU tag word */
	uint16_t			f_ip;
	uint16_t			f_st16;
	uint16_t			f_op;
	uint16_t			f_op2;
	tf87_fp80			f_st[8];
} tf387_record; /* 212 bytes */
#pragma pack(pop)

