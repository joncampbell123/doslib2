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

int ne_module_load_and_apply_segment_relocations(struct ne_module *n,unsigned int idx/*NTS: 1-based, NOT zero-based*/) {
	uint16_t offset,src_offset,src_segn;
	struct ne_segment_assign *af;
	struct ne_segment_def *df;
	unsigned char far *modp;
	unsigned char tmp[8];
	uint16_t entries;
	unsigned long o;

	if (n == NULL || idx == 0) return 1;
	if (n->ne_sega == NULL || n->ne_segd == NULL) return 1;

	df = n->ne_segd + idx - 1;
	af = n->ne_sega + idx - 1;
	if (af->segment == 0) return 1;
	if ((df->flags & 0x0006) != 0x0006) return 1; /* If not loaded or allocated, then don't apply relocations */
	if (!(df->flags & 0x100)) return 0; /* if no relocation data, bail out now */
	if (af->internal_flags & NE_SEGMENT_ASSIGN_IF_RELOC_APPLIED) return 0; /* if already applied, don't do it again */

	/* relocation data immediately follows the segment on disk */
	o = (((unsigned long)(df->offset_sectors)) << (unsigned long)n->ne_header.logical_sector_shift_count) +
		(unsigned long)df->length;

	if (lseek(n->fd,o,SEEK_SET) != o) return 1;
	if (read(n->fd,&entries,2) != 2) return 1;

	while ((entries--) > 0 && read(n->fd,tmp,8) == 8) {
		offset = *((uint16_t*)(tmp+2));
		if ((offset>>4UL) >= af->length_para) continue;

		if (tmp[1] == 0) { /* internal ref */
			src_segn = tmp[4];
			if (src_segn != 0xFF) {
				src_offset = *((uint16_t*)(tmp+6));
			}
			else {
				fprintf(stdout,"WARNING: movable relocation entries not yet supported\n");
				continue;
			}
		}
		else {
			fprintf(stdout,"WARNING: Reloc type %u not yet supported\n",tmp[1]);
			continue;
		}

		if (src_segn == 0 || src_segn > n->ne_header.segment_table_entries) continue;
		src_segn = n->ne_sega[src_segn-1].segment;
		modp = MK_FP(af->segment,offset);

		if (tmp[0] == 3) { /* 16:16 fixup */
			*((uint16_t far*)modp) = src_offset;
			*((uint16_t far*)(modp+2)) = src_segn;
		}
		else {
			fprintf(stdout,"WARNING: Reloc fixup type %u not yet supported\n",tmp[0]);
		}
	}

	af->internal_flags |= NE_SEGMENT_ASSIGN_IF_RELOC_APPLIED;
	return 0;
}

int ne_module_load_and_apply_relocations(struct ne_module *n) {
	unsigned int x;

	if (n == NULL) return 0;
	if (n->ne_header.segment_table_entries == 0) return 0;

	for (x=1;x <= n->ne_header.segment_table_entries;x++)
		ne_module_load_and_apply_segment_relocations(n,x);

	return 0;
}

#endif

