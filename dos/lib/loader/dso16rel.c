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

int ne_module_load_and_apply_relocations(struct ne_module *n) {
	struct ne_segment_assign *af;
	struct ne_segment_def *df;
	unsigned int x;

	if (n == NULL) return 0;
	if (n->ne_header.segment_table_entries == 0) return 0;
	if (n->ne_sega == NULL) return 0;
	if (n->ne_segd == NULL) return 0;

	for (x=0;x < n->ne_header.segment_table_entries;x++) {
		df = n->ne_segd + x;
		af = n->ne_sega + x;

		if (af->segment != 0 && (df->flags & 0x100)) {
			/* relocation data immediately follows the segment on disk */
			unsigned long o = (((unsigned long)(df->offset_sectors)) <<
				(unsigned long)n->ne_header.logical_sector_shift_count) +
				(unsigned long)df->length;

			if (lseek(n->fd,o,SEEK_SET) == o) {
				uint16_t offset,src_offset,src_segn;
				unsigned char far *modp;
				unsigned char tmp[8];
				uint16_t entries;

				if (read(n->fd,&entries,2) == 2) {
					while ((entries--) > 0 && read(n->fd,tmp,8) == 8) {
						offset = *((uint16_t*)(tmp+2));

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

						/* TODO: range check */
						modp = MK_FP(af->segment,offset);

						if (tmp[0] == 3) { /* 16:16 fixup */
							*((uint16_t far*)modp) = src_offset;
							*((uint16_t far*)(modp+2)) = src_segn;
						}
						else {
							fprintf(stdout,"WARNING: Reloc fixup type %u not yet supported\n",tmp[0]);
						}
					}
				}
			}

			df->flags &= ~(0x100); /* no more relocation data */
		}
	}

	return 0;
}

#endif

