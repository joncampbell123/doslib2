/* WARNING: This code assumes 16-bit real mode */

#include <dos.h>
#include <stdio.h>
#include <fcntl.h>
#include <assert.h>
#include <stdlib.h>
#include <malloc.h>
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

struct ne_segment_def {
	uint16_t		offset_sectors;				/* +0x00 offset of the segment (in sectors) */
	uint16_t		length;					/* +0x02 length in bytes. 0x0000 means 64K, unless offset also zero */
	uint16_t		flags;					/* +0x04 */
	uint16_t		minimum_allocation_size;		/* +0x06 in bytes. 0x0000 means 64K */
};

struct ne_segment_assign {
	uint16_t		segment;				/* 0 if not assigned, else realmode segment */
	uint16_t		length_para;				/* allocated length in paragraphs */
};
#pragma pack(pop)

struct ne_module {
	int				fd;
	uint32_t			ne_header_offset;
	struct ne_header		ne_header;
	struct ne_segment_def*		ne_segd;
	struct ne_segment_assign*	ne_sega;
};

void ne_module_zero(struct ne_module *n) {
	_fmemset(n,0,sizeof(*n));
	n->fd = -1;
}

int ne_module_load_header(struct ne_module *n,int fd) {
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

int ne_module_load_segments(struct ne_module *n) {
	struct ne_segment_assign *af;
	struct ne_segment_def *df;
	unsigned int x,trd;

	/* TODO: Move to it's own segment */
	if (n->ne_sega == NULL) {
		if (n->ne_header.segment_table_entries == 0) return 0;
		if (n->ne_header.segment_table_entries > 512) return 1;

		n->ne_sega = malloc(n->ne_header.segment_table_entries * sizeof(struct ne_segment_assign));
		if (n->ne_sega == NULL) return 1;
		_fmemset(n->ne_sega,0,n->ne_header.segment_table_entries * sizeof(struct ne_segment_assign));
	}

	for (x=0;x < n->ne_header.segment_table_entries;x++) {
		df = n->ne_segd + x;
		af = n->ne_sega + x;

		if (af->segment == 0) {
			unsigned char far *p;
			unsigned long sz,rd;
			unsigned tseg=0;

			rd = df->length;
			sz = df->minimum_allocation_size;
			if (sz == 0UL) sz = 0x10000UL;
			if (df->length == 0 && df->offset_sectors != 0U) rd = 0x10000UL;
			if (sz < rd) sz = rd;
			assert(sz != 0UL);

			/* allocate it */
			af->length_para = (uint16_t)((sz+0xFUL) >> 4UL);
			if (_dos_allocmem(af->length_para,&tseg)) continue;
			af->segment = tseg;
			p = MK_FP(tseg,0);

			/* now if disk data is involved, read it */
			if (rd != 0) {
				unsigned long o = ((unsigned long)(df->offset_sectors)) <<
					(unsigned long)n->ne_header.logical_sector_shift_count;

				if (lseek(n->fd,o,SEEK_SET) == o) {
					/* FIXME: How do we handle a full 64KB read here? */
					/* FIXME: Various flags in the FLAGS fields are modified by the loader
					 *        to indicate that the segment is loaded, etc. we should apply
					 *        them as well */
					if (_dos_read(n->fd,p,(unsigned)rd,&trd) || trd != (unsigned)rd) {
						_dos_freemem(af->segment);
						af->segment = 0;
						continue;
					}
				}
			}
		}
	}

	return 0;
}

int ne_module_load_segmentinfo(struct ne_module *n) {
	unsigned int x;

	if (n->ne_segd != NULL) return 0;
	if (n->ne_header.segment_table_entries == 0) return 0;
	if (n->ne_header.segment_table_entries > 512) return 1;

	n->ne_segd = malloc(n->ne_header.segment_table_entries * 8);
	if (n->ne_segd == NULL) return 1;

	if (lseek(n->fd,n->ne_header_offset+(uint32_t)n->ne_header.segment_table_rel_offset,SEEK_SET) !=
		(n->ne_header_offset+(uint32_t)n->ne_header.segment_table_rel_offset)) {
		free(n->ne_segd); n->ne_segd = NULL;
		return 1;
	}
	if (_dos_read(n->fd,n->ne_segd,n->ne_header.segment_table_entries * 8UL,&x) ||
		x != (n->ne_header.segment_table_entries * 8UL)) {
		free(n->ne_segd); n->ne_segd = NULL;
		return 1;
	}

	return 0;
}

void ne_module_dump_segmentinfo(struct ne_module *n,FILE *fp) {
	struct ne_segment_assign *af;
	struct ne_segment_def *df;
	unsigned int x;

	fprintf(fp,"NE(%Fp) segment info. %u segments\n",(void far*)n,(unsigned int)n->ne_header.segment_table_entries);
	if (n == NULL) return;

	for (x=0;x < n->ne_header.segment_table_entries;x++) {
		df = n->ne_segd + x;
		fprintf(fp,"Segment #%d\n",(int)(x+1));
		fprintf(fp,"    offset=%lu\n",(unsigned long)df->offset_sectors << (unsigned long)n->ne_header.logical_sector_shift_count);
		fprintf(fp,"    length=%lu\n",df->length == 0 && df->offset_sectors != 0 ? 0x10000UL : df->length);
		fprintf(fp,"    flags=0x%04x\n",df->flags);
		fprintf(fp,"    minalloc=%lu\n",df->minimum_allocation_size == 0 ? 0x10000UL : df->minimum_allocation_size);

		if (n->ne_sega != NULL) {
			af = n->ne_sega + x;
			if (af->segment != 0) {
				fprintf(fp,"    assigned to realmode segment 0x%04x-0x%04x inclusive\n",af->segment,af->segment+af->length_para-1);
			}
			else {
				fprintf(fp,"    *not yet loaded/assigned a memory address\n");
			}
		}
	}
}

void ne_module_dump_header(struct ne_module *n,FILE *fp) {
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

void ne_module_free(struct ne_module *n) {
	unsigned int x;

	if (n->ne_sega != NULL) {
		struct ne_segment_assign *af;

		for (x=0;x < n->ne_header.segment_table_entries;x++) {
			af = n->ne_sega + x;
			if (af->segment != 0) {
				_dos_freemem(af->segment);
				af->segment = 0;
				af->length_para = 0;
			}
		}

		free(n->ne_sega);
		n->ne_sega = NULL;
	}
	if (n->ne_segd != NULL) {
		free(n->ne_segd);
		n->ne_segd = NULL;
	}
}

int main(int argc,char **argv,char **envp) {
	struct ne_module ne;
	int fd;

	/* validate */
	assert(sizeof(struct ne_header) == 0x40);
	assert(sizeof(struct ne_segment_def) == 0x08);

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
	if (ne_module_load_segmentinfo(&ne)) {
		fprintf(stderr,"Failed to load segment info\n");
		return 1;
	}
	if (ne_module_load_segments(&ne)) {
		fprintf(stderr,"Failed to load segment\n");
		ne_module_dump_segmentinfo(&ne,stdout);
		return 1;
	}
	ne_module_dump_segmentinfo(&ne,stdout);
	/* TODO: Read relocation data and apply relocations, if applicable */
	ne_module_free(&ne);
	close(fd);

	return 0;
}

