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

struct ne_entry_point* ne_module_get_ordinal_entry_point(struct ne_module *n,unsigned int ordinal) {
	if (n == NULL) return NULL;
	if (ordinal == 0) return NULL;
	if (n->ne_entry == NULL) return NULL;
	ordinal--;
	if (ordinal >= n->ne_entry_points) return NULL;
	return n->ne_entry + ordinal;
}

void far *ne_module_entry_point_by_ordinal(struct ne_module *n,unsigned int ordinal) {
	struct ne_segment_assign *sega;
	struct ne_entry_point *nent;
	
	nent = ne_module_get_ordinal_entry_point(n,ordinal);
	if (nent == NULL) return NULL;
	if (!(nent->flags & 1)) return NULL; /* not "exported" */
	if (nent->segment_index == 0) return NULL;
	if (n->ne_segd == NULL || n->ne_sega == NULL) return NULL;
	if (nent->segment_index > n->ne_header.segment_table_entries) return NULL;
	sega = n->ne_sega + nent->segment_index - 1;
	if (sega->segment == 0) return NULL;
	if ((nent->offset>>4UL) >= sega->length_para) return NULL;
	return MK_FP(sega->segment,nent->offset);
}

int ne_module_load_entry_points(struct ne_module *n) {
	unsigned char far *p;
	unsigned int i,rd,count,segn,ordinal_count=0;

	if (n == NULL) return 0;
	if (n->ne_entry != NULL) return 0;
	if (n->ne_header.entry_table_length <= 2) return 0;
	if (n->ne_header.entry_table_offset == 0) return 0;
	if (n->ne_header.entry_table_length > 32768U) return 0;

	p = _fmalloc(n->ne_header.entry_table_length);
	if (p == NULL) return 1;

	if (lseek(n->fd,n->ne_header_offset+(unsigned long)n->ne_header.entry_table_offset,SEEK_SET) !=
		(n->ne_header_offset+(unsigned long)n->ne_header.entry_table_offset)) {
		_ffree(p);
		return 1;
	}
	if (_dos_read(n->fd,p,n->ne_header.entry_table_length,&rd) || rd != n->ne_header.entry_table_length) {
		_ffree(p);
		return 1;
	}

	/* OK. table loaded. parse it first time to count the number of exported symbols */
	for (i=0;i < n->ne_header.entry_table_length;) {
		count = p[i++]; if (count == 0) break;
		segn = p[i++]; if (segn == 0) break;
		ordinal_count += count;

		if (segn == 0xFF)
			i += (6 * count);/* moveable segment */
		else /* fixed/constant */
			i += (3 * count);
	}

	if (ordinal_count != 0) {
		n->ne_entry_points = ordinal_count;
		n->ne_entry = malloc(n->ne_entry_points * sizeof(struct ne_entry_point));
		if (n->ne_entry != NULL) {
			ordinal_count = 0;

			/* second pass: actually parse the struct */
			for (i=0;i < n->ne_header.entry_table_length;) {
				count = p[i++]; if (count == 0) break;
				segn = p[i++]; if (segn == 0) break;

				if (segn == 0xFF) {
					while (ordinal_count < n->ne_header.entry_table_length && count != 0) {
						struct ne_entry_point *xx = n->ne_entry + (ordinal_count++);
						xx->flags = p[i++];
						i += 2; /* skip "INT 3F" */
						xx->segment_index = p[i++];
						xx->offset = *((uint16_t*)(p+i)); i += 2;
						count--;
					}
				}
				else {
					while (ordinal_count < n->ne_header.entry_table_length && count != 0) {
						struct ne_entry_point *xx = n->ne_entry + (ordinal_count++);
						xx->flags = p[i++];
						xx->segment_index = segn;
						xx->offset = *((uint16_t*)(p+i)); i += 2;
						count--;
					}
				}
			}

			while (ordinal_count < n->ne_entry_points) {
				struct ne_entry_point *xx = n->ne_entry + (ordinal_count++);
				memset(xx,0,sizeof(*xx));
			}
		}
	}

	_ffree(p);
	return 0;
}

#endif

