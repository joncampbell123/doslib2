/* WARNING: This code assumes 16-bit real mode */

#include <dos.h>
#include <stdio.h>
#include <fcntl.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>

#pragma pack(push,1)
struct ne_header {
	uint8_t			sig_n,sig_e;				/* +0x00 N E */
	uint8_t			linker_version,linker_revision;		/* +0x02 */
	uint16_t		entry_table_offset;			/* +0x04 */
	uint16_t		entry_table_length;			/* +0x06 */
	uint32_t		reserved;				/* +0x08 (32-bit CRC) */
	uint16_t		flags;					/* +0x0C */
	uint16_t		autodata_segment_index;			/* +0x0E */
	uint16_t		heap_initial_size;			/* +0x10 */
	uint16_t		stack_initial_size;			/* +0x12 */
	uint16_t		init_cs,init_ip;			/* +0x14 */
	uint16_t		init_ss,init_sp;			/* +0x18 */
	uint16_t		segment_table_entries;			/* +0x1C */
	uint16_t		module_reference_table_entries;		/* +0x1E */
	uint16_t		nonresident_table_size;			/* +0x20 in bytes */
	uint16_t		segment_table_rel_offset;		/* +0x22 relative to header */
	uint16_t		resource_table_rel_offset;		/* +0x24 relative to header */
	uint16_t		resident_name_table_rel_offset;		/* +0x26 relative to header */
	uint16_t		module_reference_table_rel_offset;	/* +0x28 relative to header */
	uint16_t		imported_name_table_rel_offset;		/* +0x2A relative to header */
	uint32_t		nonresident_name_table_rel_offset;	/* +0x2C relative to file */
	uint16_t		movable_entry_points;			/* +0x30 */
	uint16_t		logical_sector_shift_count;		/* +0x32 */
	uint16_t		resource_segment_count;			/* +0x34 */
	uint8_t			target_os;				/* +0x36 */
	uint8_t			additional_info;			/* +0x37 */
	uint16_t		fast_load_area_offset;			/* +0x38 in sectors */
	uint16_t		fast_load_area_length;			/* +0x3A in sectors */
	uint16_t		reserved2;				/* +0x3C */
	uint16_t		windows_version;			/* +0x3E minimum windows version required */
};									/* =0x40 */
#pragma pack(pop)

struct ne_module {
	int			fd;
	uint32_t		ne_header_offset;
	struct ne_header	ne_header;
};

void ne_module_zero(struct ne_module far *n) {
	_fmemset(n,0,sizeof(*n));
	n->fd = -1;
}

int ne_module_load_header(struct ne_module far *n,int fd) {
	unsigned char tmp[64];
	unsigned int x;

	if (n->fd != -1) return 1;
	n->fd = fd;

	if (lseek(n->fd,0,SEEK_SET) != 0) return 1;
	if (read(n->fd,tmp,64) != 64) return 1;
	if (memcmp(tmp,"MZ",2) != 0) return 1;

	x = *((uint16_t*)(tmp+8));
	if (x < 4) return 1; /* at least 4 paragraphs (64 bytes) */

	n->ne_header_offset = *((uint32_t*)(tmp+0x3C));
	if (lseek(n->fd,n->ne_header_offset,SEEK_SET) != n->ne_header_offset) return 1;

	x = 0;
	if (_dos_read(n->fd,&(n->ne_header),sizeof(struct ne_header),&x) || x != sizeof(struct ne_header)) return 1;
	if (n->ne_header.sig_n != 'N' || n->ne_header.sig_e != 'E') return 1;

	return 0;
}

void ne_module_dump_header(struct ne_module far *n,FILE *fp) {
	fprintf(fp,"NE(%Fp) fd=%d hdr=%lu\n",(void far*)n,n->fd,(unsigned long)n->ne_header_offset);
	fprintf(fp,"         Linker ver: %u.%u\n",
		n->ne_header.linker_version,n->ne_header.linker_revision);
	fprintf(fp,"        Entry table: @%u, %u bytes long\n",
		n->ne_header.entry_table_offset,n->ne_header.entry_table_length);
	fprintf(fp,"              Flags: 0x%04x\n",n->ne_header.flags);
	fprintf(fp,"   AUTODATA segment: %u\n",n->ne_header.autodata_segment_index);
	fprintf(fp,"     Heap init size: %u\n",n->ne_header.heap_initial_size);
	fprintf(fp,"    Stack init size: %u\n",n->ne_header.stack_initial_size);
	fprintf(fp,"         Init CS:IP: 0x%04x:0x%04x\n",n->ne_header.init_cs,n->ne_header.init_ip);
	fprintf(fp,"         Init SS:SP: 0x%04x:0x%04x\n",n->ne_header.init_ss,n->ne_header.init_sp);
	fprintf(fp,"  Seg table entries: %u\n",n->ne_header.segment_table_entries);
	fprintf(fp,"Mod ref tbl entries: %u\n",n->ne_header.module_reference_table_entries);
	fprintf(fp,"   Nonres tabl size: %u\n",n->ne_header.nonresident_table_size);
	fprintf(fp,"       Sector shift: %u (1 << %u = %u)\n",
		n->ne_header.logical_sector_shift_count,
		n->ne_header.logical_sector_shift_count,
		1 << n->ne_header.logical_sector_shift_count);
	fprintf(fp,"    Windows version: %u.%u\n",
		n->ne_header.windows_version>>8,n->ne_header.windows_version&0xFF);
}

void ne_module_free(struct ne_module far *n) {
	/* TODO: Doesn't do anything yet, but should eventually since memory allocation will be involved */
}

int main(int argc,char **argv,char **envp) {
	struct ne_module ne;
	int fd;

	/* validate */
	assert(sizeof(struct ne_header) == 0x40);

	ne_module_zero(&ne);

	/* examdll1 */
	if ((fd=open("examdll1.dso",O_RDONLY|O_BINARY)) < 0) {
		fprintf(stderr,"Cannot open EXAMDLL1.DSO\n");
		return 1;
	}
	if (ne_module_load_header(&ne,fd)) {
		fprintf(stderr,"Failed to load header\n");
		return 1;
	}
	ne_module_dump_header(&ne,stdout);
	ne_module_free(&ne);
	close(fd);

	return 0;
}

