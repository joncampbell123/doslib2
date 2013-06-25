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

#include <dos/lib/loader/dso16.h>

#if defined(TARGET_MSDOS) && TARGET_BITS == 16 && defined(TARGET_REALMODE)

int ne_module_allocate_segment(struct ne_module *n,unsigned int idx/*NTS: Segments in NE executables are 1-based NOT zero-based*/) {
	struct ne_segment_assign *af;
	struct ne_segment_def *df;
	unsigned long sz,rd;

	if (n == NULL || idx == 0) return 1;
	if (idx > n->ne_header.segment_table_entries) return 1;

	if (n->ne_sega == NULL) {
		if (n->ne_header.segment_table_entries == 0) return 0;
		if (n->ne_header.segment_table_entries > 512) return 1;

		n->ne_sega = malloc(n->ne_header.segment_table_entries * sizeof(struct ne_segment_assign));
		if (n->ne_sega == NULL) return 1;
		_fmemset(n->ne_sega,0,n->ne_header.segment_table_entries * sizeof(struct ne_segment_assign));
	}

	df = n->ne_segd + idx - 1;
	af = n->ne_sega + idx - 1;
	if (af->segment == 0) {
		unsigned tseg=0;

		rd = df->length;
		sz = df->minimum_allocation_size;
		if (sz == 0UL) sz = 0x10000UL;
		if (df->length == 0 && df->offset_sectors != 0U) rd = 0x10000UL;
		if (sz < rd) sz = rd;
		assert(sz != 0UL);

		/* allocate it */
		af->length_para = (uint16_t)((sz+0xFUL) >> 4UL);
		if (_dos_allocmem(af->length_para,&tseg)) return 1;
		af->segment = tseg;

		/* mark as allocated */
		df->flags |= 0x0002;
	}

	return 0;
}

int ne_module_load_segment(struct ne_module *n,unsigned int idx/*NTS: Segments in NE executables are 1-based NOT zero-based*/) {
	struct ne_segment_assign *af;
	struct ne_segment_def *df;
	unsigned char far *p;
	unsigned long rd;
	unsigned int trd;

	if (n == NULL || idx == 0) return 1;
	if (ne_module_allocate_segment(n,idx)) return 1;

	df = n->ne_segd + idx - 1;
	af = n->ne_sega + idx - 1;
	if (af->segment == 0) return 1;

	/* now if disk data is involved, read it */
	p = MK_FP(af->segment,0);
	if (df->length == 0 && df->offset_sectors != 0U) rd = 0x10000UL;
	else rd = df->length;

	if (rd != 0) {
		unsigned long o = ((unsigned long)(df->offset_sectors)) <<
			(unsigned long)n->ne_header.logical_sector_shift_count;

		if (lseek(n->fd,o,SEEK_SET) == o) {
			if (rd == 0x10000UL) {
				/* special case: full 64KB load.
				 * the REASON this is a special case is that typeof(unsigned) is 16 bits
				 * and 65536 is +1 too large for a 16-bit byte count.
				 * compensate then by loading 2 x 32KB chunks */
				if (_dos_read(n->fd,p,(unsigned)0x8000U,&trd) || trd != (unsigned)0x8000U) {
					_dos_freemem(af->segment);
					af->segment = 0;
					return 1;
				}
				if (_dos_read(n->fd,p+0x8000UL,(unsigned)0x8000U,&trd) || trd != (unsigned)0x8000U) {
					_dos_freemem(af->segment);
					af->segment = 0;
					return 1;
				}
			}
			else {
				if (_dos_read(n->fd,p,(unsigned)rd,&trd) || trd != (unsigned)rd) {
					_dos_freemem(af->segment);
					af->segment = 0;
					return 1;
				}
			}

			/* mark as loaded */
			df->flags |= 0x0004;
		}
	}

	return 0;
}

int ne_module_load_segments(struct ne_module *n) {
	unsigned int x;

	for (x=1;x <= n->ne_header.segment_table_entries;x++)
		ne_module_load_segment(n,x);

	return 0;
}

int ne_module_load_segmentinfo(struct ne_module *n) {
	struct ne_segment_def *df;
	unsigned int x;

	if (n->ne_segd != NULL || n->ne_sega != NULL) return 0;
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

	/* filter the flags fields */
	for (x=0;x < n->ne_header.segment_table_entries;x++) {
		df = n->ne_segd + x;
		df->flags &= ~(0x0006);
		/* ^ clear:
		 *      bit 1: if set, loader has allocated memory for segment
		 *      bit 2: if set, loader has loaded the segment into memory */
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

#endif

