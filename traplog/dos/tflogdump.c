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

#ifndef O_BINARY
#define O_BINARY 0
#endif

static const char str_spc[] = " ";
static const char str_ast[] = "\x1B[33m*\x1B[0m";

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
} __attribute__((packed)) tf8086_record; /* 36 bytes */

int main(int argc,char **argv) {
	struct tf8086_record *rec,prec;
	unsigned char buffer[512];
	int fd,rd;

	if (argc < 2) {
		fprintf(stderr,"tflogdump <file>\n");
		return 1;
	}

	fd = open(argv[1],O_RDONLY|O_BINARY);
	if (fd < 0) {
		fprintf(stderr,"Cannot open for reading %s, %s\n",argv[1],strerror(errno));
		return 1;
	}

	memset(&prec,0xFF,sizeof(prec));
	assert(sizeof(*rec) == 40);

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
			printf("[8086] CS:IP 0x%04x%s:0x%04x%s [0x%02x 0x%02x 0x%02x 0x%02x] FLAGS=0x%04x%s\n",
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
			printf("       DS=%04x%s ES=%04x%s SS:SP 0x%04x%s:%04x%s [0x%02x 0x%02x 0x%02x 0x%02x]\n",
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

	close(fd);
	return 0;
}

