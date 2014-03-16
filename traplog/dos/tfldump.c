#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <fcntl.h>
#include <math.h>

#include "traplog.h"

#ifndef O_BINARY
#define O_BINARY 0
#endif

#ifdef TARGET_LINUX
static const char str_spc[] = " ";
static const char str_ast[] = "\x1B[33m*\x1B[0m";
#else
static const char str_spc[] = " ";
static const char str_ast[] = "*";
#endif

static unsigned char buffer[512];

static void dump_387(int fd) {
	struct tf387_record *rec,prec;
	int rd,fu;

	memset(&prec,0xFF,sizeof(prec));
	while ((rd=read(fd,buffer,4)) == 4) {
		rec = (struct tf387_record*)buffer;

		if (rec->r_reclen < 4) {
			fprintf(stderr,"Invalid record type=0x%04x length=0x%04x\n",rec->r_recid,rec->r_reclen);
			break;
		}

		if (rec->r_recid == 0x8387) {
			if (rec->r_reclen != 212) {
				fprintf(stderr,"WARNING: Invalid 387 record len=0x%04x\n",rec->r_reclen);
				lseek(fd,rec->r_reclen-4,SEEK_CUR);
				continue;
			}

			read(fd,buffer+4,212-4);
			printf("[387] CS:EIP %04x%s:%08lx%s [0x%02x 0x%02x 0x%02x 0x%02x] EFLAGS=%08lx%s\n",
					rec->r_cs,			(rec->r_cs == prec.r_cs)?str_spc:str_ast,
					(unsigned long)rec->r_eip,	(rec->r_eip == prec.r_eip)?str_spc:str_ast,
					rec->r_csip_capture[0],rec->r_csip_capture[1],
					rec->r_csip_capture[2],rec->r_csip_capture[3],
					(unsigned long)rec->r_eflags,	(rec->r_eflags == prec.r_eflags)?str_spc:str_ast);
			printf("       EAX=%08lx%s EBX=%08lx%s ECX=%08lx%s EDX=%08lx%s\n",
					(unsigned long)rec->r_eax,	(rec->r_eax == prec.r_eax)?str_spc:str_ast,
					(unsigned long)rec->r_ebx,	(rec->r_ebx == prec.r_ebx)?str_spc:str_ast,
					(unsigned long)rec->r_ecx,	(rec->r_ecx == prec.r_ecx)?str_spc:str_ast,
					(unsigned long)rec->r_edx,	(rec->r_edx == prec.r_edx)?str_spc:str_ast);
			printf("       ESI=%08lx%s EDI=%08lx%s EBP=%08lx%s DS=%04x%s\n",
					(unsigned long)rec->r_esi,	(rec->r_esi == prec.r_esi)?str_spc:str_ast,
					(unsigned long)rec->r_edi,	(rec->r_edi == prec.r_edi)?str_spc:str_ast,
					(unsigned long)rec->r_ebp,	(rec->r_ebp == prec.r_ebp)?str_spc:str_ast,
					rec->r_ds,	(rec->r_ds == prec.r_ds)?str_spc:str_ast);
			printf("       ES=%04x%s SS:ESP %04x%s:%08lx%s [0x%02x 0x%02x 0x%02x 0x%02x]\n",
					rec->r_es,	(rec->r_es == prec.r_es)?str_spc:str_ast,
					rec->r_ss,	(rec->r_ss == prec.r_ss)?str_spc:str_ast,
					(unsigned long)rec->r_esp,	(rec->r_esp == prec.r_esp)?str_spc:str_ast,
					rec->r_sssp_capture[0],rec->r_sssp_capture[1],
					rec->r_sssp_capture[2],rec->r_sssp_capture[3]);
			printf("       FS=%04x%s GS=%04x%s CR0=%08lx%s CR2=%08lx%s CR3=%08lx%s\n",
					rec->r_fs,	(rec->r_fs == prec.r_fs)?str_spc:str_ast,
					rec->r_gs,	(rec->r_gs == prec.r_gs)?str_spc:str_ast,
					(unsigned long)rec->r_cr0,	(rec->r_cr0 == prec.r_cr0)?str_spc:str_ast,
					(unsigned long)rec->r_cr2,	(rec->r_cr2 == prec.r_cr2)?str_spc:str_ast,
					(unsigned long)rec->r_cr3,	(rec->r_cr3 == prec.r_cr3)?str_spc:str_ast);
			printf("       CR4=%08lx%s DR0=%08lx%s DR1=%08lx%s DR2=%08lx%s\n",
					(unsigned long)rec->r_cr4,	(rec->r_cr4 == prec.r_cr4)?str_spc:str_ast,
					(unsigned long)rec->r_dr0,	(rec->r_dr0 == prec.r_dr0)?str_spc:str_ast,
					(unsigned long)rec->r_dr1,	(rec->r_dr1 == prec.r_dr1)?str_spc:str_ast,
					(unsigned long)rec->r_dr2,	(rec->r_dr2 == prec.r_dr2)?str_spc:str_ast);
			printf("       DR3=%08lx%s DR6=%08lx%s DR7=%08lx%s\n",
					(unsigned long)rec->r_dr3,	(rec->r_dr3 == prec.r_dr3)?str_spc:str_ast,
					(unsigned long)rec->r_dr6,	(rec->r_dr6 == prec.r_dr6)?str_spc:str_ast,
					(unsigned long)rec->r_dr7,	(rec->r_dr7 == prec.r_dr7)?str_spc:str_ast);
			printf("       LDTR=%04x%s GDTR=%04x,%08lx%s IDTR=%04x,%08lx%s\n",
					rec->r_ldtr,	(rec->r_ldtr == prec.r_ldtr)?str_spc:str_ast,
					rec->r_gdtr[0],
					(unsigned long)(*((uint32_t*)(&rec->r_gdtr[1]))),
					(memcmp(rec->r_gdtr,prec.r_gdtr,sizeof(prec.r_gdtr)) == 0)?str_spc:str_ast,
					rec->r_idtr[0],
					(unsigned long)(*((uint32_t*)(&rec->r_idtr[1]))),
					(memcmp(rec->r_idtr,prec.r_idtr,sizeof(prec.r_idtr)) == 0)?str_spc:str_ast);
			printf("       FPU-SW=%04lx%s FPU-CW=%04lx%s FPU-TAG=%04lx%s\n",
					(unsigned long)rec->f_sw,	(rec->f_sw == prec.f_sw)?str_spc:str_ast,
					(unsigned long)rec->f_cw,	(rec->f_cw == prec.f_cw)?str_spc:str_ast,
					(unsigned long)rec->f_tagw,	(rec->f_tagw == prec.f_tagw)?str_spc:str_ast);
			printf("       FPU-IP=%04lx%s FPU-16=%04lx%s FPU-OP=%04lx%s FPU-OP2=%04lx%s\n",
					(unsigned long)rec->f_ip,	(rec->f_ip == prec.f_ip)?str_spc:str_ast,
					(unsigned long)rec->f_st16,	(rec->f_st16 == prec.f_st16)?str_spc:str_ast,
					(unsigned long)rec->f_op,	(rec->f_op == prec.f_op)?str_spc:str_ast,
					(unsigned long)rec->f_op2,	(rec->f_op2 == prec.f_op2)?str_spc:str_ast);

			/* NTS: This is not well specified in Intel documentation, but despite the stack-based
			 *      "rotation" of the registers, FSAVE always writes st(0) to st(7) in that order */
			for (fu=0;fu < 8;fu++) {
				double flt;
				uint64_t m;
				int exp;

				exp = (int)((((unsigned int)rec->f_st[fu].b[9] << 8) + (unsigned int)rec->f_st[fu].b[8]) & 0x7FFF);
				exp -= 16383;

				m =	(((uint64_t)(rec->f_st[fu].b[7] & 0xFF)) << 56ULL) +
					(((uint64_t)(rec->f_st[fu].b[6] & 0xFF)) << 48ULL) +
					(((uint64_t)(rec->f_st[fu].b[5] & 0xFF)) << 40ULL) +
					(((uint64_t)(rec->f_st[fu].b[4] & 0xFF)) << 32ULL) +
					(((uint64_t)(rec->f_st[fu].b[3] & 0xFF)) << 24ULL) +
					(((uint64_t)(rec->f_st[fu].b[2] & 0xFF)) << 16ULL) +
					(((uint64_t)(rec->f_st[fu].b[1] & 0xFF)) <<  8ULL) +
					(((uint64_t)(rec->f_st[fu].b[0] & 0xFF)) <<  0ULL);

				flt = ldexp(((double)m) / 0x8000000000000000ULL,exp);

				printf("         st(%u): %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%s: ",fu,
						rec->f_st[fu].b[9],rec->f_st[fu].b[8],rec->f_st[fu].b[7],rec->f_st[fu].b[6],rec->f_st[fu].b[5],
						rec->f_st[fu].b[4],rec->f_st[fu].b[3],rec->f_st[fu].b[2],rec->f_st[fu].b[1],rec->f_st[fu].b[0],
						(memcmp(rec->f_st[fu].b,prec.f_st[fu].b,sizeof(rec->f_st[fu].b)) == 0)?str_spc:str_ast);
				printf("(2 ^ %d) * %c%u.0x%08llX\n",
						exp,rec->f_st[fu].b[9]&0x80?'-':'+',rec->f_st[fu].b[7]>>7,(m&0x7FFFFFFFULL)<<1ULL);
				printf("               value = %.50f\n",flt);
			}

			prec = *rec;
		}
		else {
			fprintf(stderr,"WARNING: Unknown record type=0x%04x len=0x%04x\n",rec->r_recid,rec->r_reclen);
			lseek(fd,rec->r_reclen-4,SEEK_CUR);
		}
	}
}

static void dump_386(int fd) {
	struct tf386_record *rec,prec;
	int rd;

	memset(&prec,0xFF,sizeof(prec));
	while ((rd=read(fd,buffer,4)) == 4) {
		rec = (struct tf386_record*)buffer;

		if (rec->r_reclen < 4) {
			fprintf(stderr,"Invalid record type=0x%04x length=0x%04x\n",rec->r_recid,rec->r_reclen);
			break;
		}

		if (rec->r_recid == 0x8386) {
			if (rec->r_reclen != 118) {
				fprintf(stderr,"WARNING: Invalid 386 record len=0x%04x\n",rec->r_reclen);
				lseek(fd,rec->r_reclen-4,SEEK_CUR);
				continue;
			}

			read(fd,buffer+4,118-4);
			printf("[386] CS:EIP %04x%s:%08lx%s [0x%02x 0x%02x 0x%02x 0x%02x] EFLAGS=%08lx%s\n",
					rec->r_cs,			(rec->r_cs == prec.r_cs)?str_spc:str_ast,
					(unsigned long)rec->r_eip,	(rec->r_eip == prec.r_eip)?str_spc:str_ast,
					rec->r_csip_capture[0],rec->r_csip_capture[1],
					rec->r_csip_capture[2],rec->r_csip_capture[3],
					(unsigned long)rec->r_eflags,	(rec->r_eflags == prec.r_eflags)?str_spc:str_ast);
			printf("       EAX=%08lx%s EBX=%08lx%s ECX=%08lx%s EDX=%08lx%s\n",
					(unsigned long)rec->r_eax,	(rec->r_eax == prec.r_eax)?str_spc:str_ast,
					(unsigned long)rec->r_ebx,	(rec->r_ebx == prec.r_ebx)?str_spc:str_ast,
					(unsigned long)rec->r_ecx,	(rec->r_ecx == prec.r_ecx)?str_spc:str_ast,
					(unsigned long)rec->r_edx,	(rec->r_edx == prec.r_edx)?str_spc:str_ast);
			printf("       ESI=%08lx%s EDI=%08lx%s EBP=%08lx%s DS=%04x%s\n",
					(unsigned long)rec->r_esi,	(rec->r_esi == prec.r_esi)?str_spc:str_ast,
					(unsigned long)rec->r_edi,	(rec->r_edi == prec.r_edi)?str_spc:str_ast,
					(unsigned long)rec->r_ebp,	(rec->r_ebp == prec.r_ebp)?str_spc:str_ast,
					rec->r_ds,	(rec->r_ds == prec.r_ds)?str_spc:str_ast);
			printf("       ES=%04x%s SS:ESP %04x%s:%08lx%s [0x%02x 0x%02x 0x%02x 0x%02x]\n",
					rec->r_es,	(rec->r_es == prec.r_es)?str_spc:str_ast,
					rec->r_ss,	(rec->r_ss == prec.r_ss)?str_spc:str_ast,
					(unsigned long)rec->r_esp,	(rec->r_esp == prec.r_esp)?str_spc:str_ast,
					rec->r_sssp_capture[0],rec->r_sssp_capture[1],
					rec->r_sssp_capture[2],rec->r_sssp_capture[3]);
			printf("       FS=%04x%s GS=%04x%s CR0=%08lx%s CR2=%08lx%s CR3=%08lx%s\n",
					rec->r_fs,	(rec->r_fs == prec.r_fs)?str_spc:str_ast,
					rec->r_gs,	(rec->r_gs == prec.r_gs)?str_spc:str_ast,
					(unsigned long)rec->r_cr0,	(rec->r_cr0 == prec.r_cr0)?str_spc:str_ast,
					(unsigned long)rec->r_cr2,	(rec->r_cr2 == prec.r_cr2)?str_spc:str_ast,
					(unsigned long)rec->r_cr3,	(rec->r_cr3 == prec.r_cr3)?str_spc:str_ast);
			printf("       CR4=%08lx%s DR0=%08lx%s DR1=%08lx%s DR2=%08lx%s\n",
					(unsigned long)rec->r_cr4,	(rec->r_cr4 == prec.r_cr4)?str_spc:str_ast,
					(unsigned long)rec->r_dr0,	(rec->r_dr0 == prec.r_dr0)?str_spc:str_ast,
					(unsigned long)rec->r_dr1,	(rec->r_dr1 == prec.r_dr1)?str_spc:str_ast,
					(unsigned long)rec->r_dr2,	(rec->r_dr2 == prec.r_dr2)?str_spc:str_ast);
			printf("       DR3=%08lx%s DR6=%08lx%s DR7=%08lx%s\n",
					(unsigned long)rec->r_dr3,	(rec->r_dr3 == prec.r_dr3)?str_spc:str_ast,
					(unsigned long)rec->r_dr6,	(rec->r_dr6 == prec.r_dr6)?str_spc:str_ast,
					(unsigned long)rec->r_dr7,	(rec->r_dr7 == prec.r_dr7)?str_spc:str_ast);
			printf("       LDTR=%04x%s GDTR=%04x,%08lx%s IDTR=%04x,%08lx%s\n",
					rec->r_ldtr,	(rec->r_ldtr == prec.r_ldtr)?str_spc:str_ast,
					rec->r_gdtr[0],
					(unsigned long)(*((uint32_t*)(&rec->r_gdtr[1]))),
					(memcmp(rec->r_gdtr,prec.r_gdtr,sizeof(prec.r_gdtr)) == 0)?str_spc:str_ast,
					rec->r_idtr[0],
					(unsigned long)(*((uint32_t*)(&rec->r_idtr[1]))),
					(memcmp(rec->r_idtr,prec.r_idtr,sizeof(prec.r_idtr)) == 0)?str_spc:str_ast);

			prec = *rec;
		}
		else {
			fprintf(stderr,"WARNING: Unknown record type=0x%04x len=0x%04x\n",rec->r_recid,rec->r_reclen);
			lseek(fd,rec->r_reclen-4,SEEK_CUR);
		}
	}
}

static void dump_286(int fd) {
	struct tf286_record *rec,prec;
	int rd;

	memset(&prec,0xFF,sizeof(prec));
	while ((rd=read(fd,buffer,4)) == 4) {
		rec = (struct tf286_record*)buffer;

		if (rec->r_reclen < 4) {
			fprintf(stderr,"Invalid record type=0x%04x length=0x%04x\n",rec->r_recid,rec->r_reclen);
			break;
		}

		if (rec->r_recid == 0x8286) {
			if (rec->r_reclen != 56) {
				fprintf(stderr,"WARNING: Invalid 286 record len=0x%04x\n",rec->r_reclen);
				lseek(fd,rec->r_reclen-4,SEEK_CUR);
				continue;
			}

			read(fd,buffer+4,56-4);
			printf("[286] CS:IP %04x%s:%04x%s [0x%02x 0x%02x 0x%02x 0x%02x] FLAGS=%04x%s\n",
					rec->r_cs,	(rec->r_cs == prec.r_cs)?str_spc:str_ast,
					rec->r_ip,	(rec->r_ip == prec.r_ip)?str_spc:str_ast,
					rec->r_csip_capture[0],rec->r_csip_capture[1],
					rec->r_csip_capture[2],rec->r_csip_capture[3],
					rec->r_flags,	(rec->r_flags == prec.r_flags)?str_spc:str_ast);
			printf("       AX=%04x%s BX=%04x%s CX=%04x%s DX=%04x%s SI=%04x%s DI=%04x%s BP=%04x%s\n",
					rec->r_ax,	(rec->r_ax == prec.r_ax)?str_spc:str_ast,
					rec->r_bx,	(rec->r_bx == prec.r_bx)?str_spc:str_ast,
					rec->r_cx,	(rec->r_cx == prec.r_cx)?str_spc:str_ast,
					rec->r_dx,	(rec->r_dx == prec.r_dx)?str_spc:str_ast,
					rec->r_si,	(rec->r_si == prec.r_si)?str_spc:str_ast,
					rec->r_di,	(rec->r_di == prec.r_di)?str_spc:str_ast,
					rec->r_bp,	(rec->r_bp == prec.r_bp)?str_spc:str_ast);
			printf("       DS=%04x%s ES=%04x%s MSW=%04x%s SS:SP %04x%s:%04x%s [0x%02x 0x%02x 0x%02x 0x%02x]\n",
					rec->r_ds,	(rec->r_ds == prec.r_ds)?str_spc:str_ast,
					rec->r_es,	(rec->r_es == prec.r_es)?str_spc:str_ast,
					rec->r_msw,	(rec->r_msw == prec.r_msw)?str_spc:str_ast,
					rec->r_ss,	(rec->r_ss == prec.r_ss)?str_spc:str_ast,
					rec->r_sp,	(rec->r_sp == prec.r_sp)?str_spc:str_ast,
					rec->r_sssp_capture[0],rec->r_sssp_capture[1],
					rec->r_sssp_capture[2],rec->r_sssp_capture[3]);
			printf("       LDTR=%04x%s GDTR=%04x,%08lx%s IDTR=%04x,%08lx%s\n",
					rec->r_ldtr,	(rec->r_ldtr == prec.r_ldtr)?str_spc:str_ast,
					rec->r_gdtr[0],
					(unsigned long)(*((uint32_t*)(&rec->r_gdtr[1]))),
					(memcmp(rec->r_gdtr,prec.r_gdtr,sizeof(prec.r_gdtr)) == 0)?str_spc:str_ast,
					rec->r_idtr[0],
					(unsigned long)(*((uint32_t*)(&rec->r_idtr[1]))),
					(memcmp(rec->r_idtr,prec.r_idtr,sizeof(prec.r_idtr)) == 0)?str_spc:str_ast);

			prec = *rec;
		}
		else {
			fprintf(stderr,"WARNING: Unknown record type=0x%04x len=0x%04x\n",rec->r_recid,rec->r_reclen);
			lseek(fd,rec->r_reclen-4,SEEK_CUR);
		}
	}
}

static void dump_8086(int fd) {
	struct tf8086_record *rec,prec;
	int rd;

	memset(&prec,0xFF,sizeof(prec));
	while ((rd=read(fd,buffer,4)) == 4) {
		rec = (struct tf8086_record*)buffer;

		if (rec->r_reclen < 4) {
			fprintf(stderr,"Invalid record type=0x%04x length=0x%04x\n",rec->r_recid,rec->r_reclen);
			break;
		}

		if (rec->r_recid == 0x8086) {
			if (rec->r_reclen != 40) {
				fprintf(stderr,"WARNING: Invalid 8086 record len=0x%04x\n",rec->r_reclen);
				lseek(fd,rec->r_reclen-4,SEEK_CUR);
				continue;
			}

			read(fd,buffer+4,40-4);
			printf("[8086] CS:IP %04x%s:%04x%s [0x%02x 0x%02x 0x%02x 0x%02x] FLAGS=%04x%s\n",
					rec->r_cs,	(rec->r_cs == prec.r_cs)?str_spc:str_ast,
					rec->r_ip,	(rec->r_ip == prec.r_ip)?str_spc:str_ast,
					rec->r_csip_capture[0],rec->r_csip_capture[1],
					rec->r_csip_capture[2],rec->r_csip_capture[3],
					rec->r_flags,	(rec->r_flags == prec.r_flags)?str_spc:str_ast);
			printf("       AX=%04x%s BX=%04x%s CX=%04x%s DX=%04x%s SI=%04x%s DI=%04x%s BP=%04x%s\n",
					rec->r_ax,	(rec->r_ax == prec.r_ax)?str_spc:str_ast,
					rec->r_bx,	(rec->r_bx == prec.r_bx)?str_spc:str_ast,
					rec->r_cx,	(rec->r_cx == prec.r_cx)?str_spc:str_ast,
					rec->r_dx,	(rec->r_dx == prec.r_dx)?str_spc:str_ast,
					rec->r_si,	(rec->r_si == prec.r_si)?str_spc:str_ast,
					rec->r_di,	(rec->r_di == prec.r_di)?str_spc:str_ast,
					rec->r_bp,	(rec->r_bp == prec.r_bp)?str_spc:str_ast);
			printf("       DS=%04x%s ES=%04x%s SS:SP %04x%s:%04x%s [0x%02x 0x%02x 0x%02x 0x%02x]\n",
					rec->r_ds,	(rec->r_ds == prec.r_ds)?str_spc:str_ast,
					rec->r_es,	(rec->r_es == prec.r_es)?str_spc:str_ast,
					rec->r_ss,	(rec->r_ss == prec.r_ss)?str_spc:str_ast,
					rec->r_sp,	(rec->r_sp == prec.r_sp)?str_spc:str_ast,
					rec->r_sssp_capture[0],rec->r_sssp_capture[1],
					rec->r_sssp_capture[2],rec->r_sssp_capture[3]);

			prec = *rec;
		}
		else {
			fprintf(stderr,"WARNING: Unknown record type=0x%04x len=0x%04x\n",rec->r_recid,rec->r_reclen);
			lseek(fd,rec->r_reclen-4,SEEK_CUR);
		}
	}
}

int main(int argc,char **argv) {
	struct tf8086_record *rec;
	int fd,rd;

	assert(sizeof(*rec) == 40);
	assert(sizeof(struct tf286_record) == 56);
	assert(sizeof(struct tf386_record) == 118);

	if (argc < 2) {
		fprintf(stderr,"tflogdump <file>\n");
		return 1;
	}

	fd = open(argv[1],O_RDONLY|O_BINARY);
	if (fd < 0) {
		fprintf(stderr,"Cannot open for reading %s, %s\n",argv[1],strerror(errno));
		return 1;
	}

	rec = (struct tf8086_record*)buffer;
	if ((rd=read(fd,buffer,4)) != 4)
		return 1;

	lseek(fd,0,SEEK_SET);
	if (rec->r_recid == 0x8086)
		dump_8086(fd);
	else if (rec->r_recid == 0x8286)
		dump_286(fd);
	else if (rec->r_recid == 0x8386)
		dump_386(fd);
	else if (rec->r_recid == 0x8387)
		dump_387(fd);
	else
		fprintf(stderr,"Unknown record type 0x%04x\n",rec->r_recid);

	close(fd);
	return 0;
}

