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
	uint16_t		entry_table_offset;			/* +0x04 relative to header */
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

struct ne_entry_point {
	uint8_t			flags;
	uint8_t			segment_index;
	uint16_t		offset;
};
#pragma pack(pop)

struct ne_module {
	int				fd;
	uint32_t			ne_header_offset;
	struct ne_header		ne_header;
	struct ne_segment_def*		ne_segd;
	struct ne_segment_assign*	ne_sega;
	uint16_t			ne_entry_points;		/* indices count from 1, from entry #0 */
	struct ne_entry_point*		ne_entry;
	unsigned char*			ne_resident_names;
	uint16_t			ne_resident_names_length;
	unsigned char*			ne_nonresident_names;
	uint16_t			ne_nonresident_names_length;
};

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

int ne_module_load_resident_name_table(struct ne_module *n) {
	unsigned int rd;

	if (n == NULL) return 0;
	if (n->ne_resident_names != NULL) return 0;
	if (n->ne_header.resident_name_table_rel_offset == 0) return 0;

	/* the "length" is implied by the distance from the resident table to the module ref table */
	if (n->ne_header.resident_name_table_rel_offset >= n->ne_header.module_reference_table_rel_offset) return 0;

	n->ne_resident_names_length = n->ne_header.module_reference_table_rel_offset - n->ne_header.resident_name_table_rel_offset;
	if (n->ne_resident_names_length > 32768) return 0;

	n->ne_resident_names = malloc(n->ne_resident_names_length);
	if (n->ne_resident_names == NULL) return 1;

	if (lseek(n->fd,n->ne_header.resident_name_table_rel_offset+n->ne_header_offset,SEEK_SET) !=
		(n->ne_header.resident_name_table_rel_offset+n->ne_header_offset)) {
		free(n->ne_resident_names);
		n->ne_resident_names = NULL;
		return 1;
	}
	if (_dos_read(n->fd,n->ne_resident_names,n->ne_resident_names_length,&rd) || rd != n->ne_resident_names_length) {
		free(n->ne_resident_names);
		n->ne_resident_names = NULL;
		return 1;
	}

	return 0;
}

int ne_module_load_nonresident_name_table(struct ne_module *n) {
	unsigned int rd;

	if (n == NULL) return 0;
	if (n->ne_nonresident_names != NULL) return 0;
	if (n->ne_header.nonresident_name_table_rel_offset == 0) return 0;

	n->ne_nonresident_names_length = n->ne_header.nonresident_table_size;
	if (n->ne_nonresident_names_length > 32768) return 0;

	n->ne_nonresident_names = malloc(n->ne_nonresident_names_length);
	if (n->ne_nonresident_names == NULL) return 1;

	if (lseek(n->fd,n->ne_header.nonresident_name_table_rel_offset,SEEK_SET) != n->ne_header.nonresident_name_table_rel_offset) {
		free(n->ne_nonresident_names);
		n->ne_nonresident_names = NULL;
		return 1;
	}
	if (_dos_read(n->fd,n->ne_nonresident_names,n->ne_nonresident_names_length,&rd) || rd != n->ne_nonresident_names_length) {
		free(n->ne_nonresident_names);
		n->ne_nonresident_names = NULL;
		return 1;
	}

	return 0;
}

int ne_module_load_name_table(struct ne_module *n) {
	int x;

	x  = (ne_module_load_resident_name_table(n) == 0);
	x |= (ne_module_load_nonresident_name_table(n) == 0);
	return !x;
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

unsigned int ne_module_raw_name_to_ordinal(unsigned char *p,unsigned int sz,const char *name) {
	unsigned int i=0,len,ord;
	unsigned int namel,match;

	namel = strlen(name);
	while (i < sz) {
		len = p[i++];
		if (len == 0) break;
		if ((i+len+2) > sz) break;

		match = 0;
		if (len == namel) match = (memcmp(p+i,name,namel) == 0);
		i += len;
		ord = *((uint16_t*)(p+i)); i += 2;

		if (match) return ord;
	}

	return 0;
}

unsigned int ne_module_name_to_ordinal(struct ne_module *n,const char *name) {
	unsigned int ord = 0;

	if (n->ne_resident_names != NULL)
		ord = ne_module_raw_name_to_ordinal(n->ne_resident_names,n->ne_resident_names_length,name);
	if (ord == 0 && n->ne_nonresident_names != NULL)
		ord = ne_module_raw_name_to_ordinal(n->ne_nonresident_names,n->ne_nonresident_names_length,name);

	return ord;
}

void far *ne_module_entry_point_by_name(struct ne_module *n,const char *name) {
	unsigned int ord;

	ord = ne_module_name_to_ordinal(n,name);
	if (ord == 0) return NULL;
	return ne_module_entry_point_by_ordinal(n,ord);
}

void ne_module_dump_resident_table(unsigned char *p,unsigned int sz,FILE *fp) {
	unsigned int i=0,len,ord;

	while (i < sz) {
		len = p[i++];
		if (len == 0) break;
		if ((i+len+2) > sz) break;

		fprintf(fp,"    ");
		fwrite(p+i,len,1,fp);
		i += len;

		ord = *((uint16_t*)(p+i)); i += 2;
		fprintf(fp," ord=%u\n",ord);
	}
}

void ne_module_dump_header(struct ne_module *n,FILE *fp) {
	fprintf(fp,"NE(%Fp) fd=%d hdr=%lu\n",(void far*)n,n->fd,(unsigned long)n->ne_header_offset);
	fprintf(fp,"         Linker ver: %u.%u\n",
		n->ne_header.linker_version,n->ne_header.linker_revision);
	fprintf(fp,"        Entry table: @%lu, %u bytes long\n",
		(unsigned long)n->ne_header.entry_table_offset+n->ne_header_offset,n->ne_header.entry_table_length);
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

	if (n->ne_nonresident_names) {
		free(n->ne_nonresident_names);
		n->ne_nonresident_names = NULL;
		n->ne_nonresident_names_length = 0;
	}
	if (n->ne_resident_names) {
		free(n->ne_resident_names);
		n->ne_resident_names = NULL;
		n->ne_resident_names_length = 0;
	}
	n->ne_entry_points = 0;
	if (n->ne_entry) {
		free(n->ne_entry);
		n->ne_entry = NULL;
	}
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
	n->fd = -1;
	ne_module_zero(n);
}

int main(int argc,char **argv,char **envp) {
	struct ne_entry_point* nent;
	struct ne_module ne;
	void far *entry;
	unsigned int xx;
	int fd;

	/* validate */
	assert(sizeof(struct ne_header) == 0x40);
	assert(sizeof(struct ne_segment_def) == 0x08);

	ne_module_zero(&ne);

	/* examdll1 */
	if ((fd=open("examdll1.dso",O_RDONLY|O_BINARY)) < 0) {
		fprintf(stdout,"Cannot open EXAMDLL1.DSO\n");
		return 1;
	}
	if (ne_module_load_header(&ne,fd)) {
		fprintf(stdout,"Failed to load header\n");
		return 1;
	}
	ne_module_dump_header(&ne,stdout);
	if (ne_module_load_segmentinfo(&ne)) {
		fprintf(stdout,"Failed to load segment info\n");
		return 1;
	}
	if (ne_module_load_segments(&ne)) {
		fprintf(stdout,"Failed to load segment\n");
		ne_module_dump_segmentinfo(&ne,stdout);
		return 1;
	}
	ne_module_dump_segmentinfo(&ne,stdout);
	if (ne_module_load_and_apply_relocations(&ne))
		fprintf(stdout,"Failed to load and apply relocation data\n");

	if (ne_module_load_entry_points(&ne)) {
		fprintf(stdout,"Failed to load entry points\n");
		return 1;
	}
	fprintf(stdout,"%u entry points\n",ne.ne_entry_points);
	for (xx=1;xx <= ne.ne_entry_points;xx++) {
		nent = ne_module_get_ordinal_entry_point(&ne,xx);
		entry = ne_module_entry_point_by_ordinal(&ne,xx);
		if (nent != NULL) {
			fprintf(stdout,"  [%u] flags=0x%02x segn=%u offset=0x%04x entry=%Fp\n",
				xx,nent->flags,nent->segment_index,nent->offset,entry);
		}
	}

	/* Load Resident Name Table */
	if (ne_module_load_name_table(&ne))
		fprintf(stdout,"Failed to load name table\n");

	/* dump the resident/nonresident tables */
	fprintf(stdout,"Resident names:\n");
	ne_module_dump_resident_table(ne.ne_resident_names,ne.ne_resident_names_length,stdout);
	fprintf(stdout,"Nonresident names:\n");
	ne_module_dump_resident_table(ne.ne_nonresident_names,ne.ne_nonresident_names_length,stdout);

	/* 3rd ordinal is MESSAGE data object */
	entry = ne_module_entry_point_by_ordinal(&ne,3);
	if (entry != NULL) {
		fprintf(stdout,"Got ordinal #3, which should be a string: %Fs\n",entry);
	}
	else {
		fprintf(stdout,"FAILED to get ordinal #3\n");
	}

	/* 1st and 2nd ordinals are functions */
	{
		int (far __stdcall *hello1)() = (int (far __stdcall *)())
			ne_module_entry_point_by_ordinal(&ne,1);

		if (hello1 != NULL)
			fprintf(stdout,"Ordinal #1 function call worked, returned 0x%04x\n",hello1());
		else
			fprintf(stdout,"FAILED to get ordinal #1\n");
	}
	{
		int (far __stdcall *hello2)(const char far *msg) = (int (far __stdcall *)(const char far *))
			ne_module_entry_point_by_ordinal(&ne,2);

		if (hello2 != NULL)
			fprintf(stdout,"Ordinal #2 function call worked, returned 0x%04x\n",hello2("This is a test string. I passed this to the function. Test GOOD\r\n"));
		else
			fprintf(stdout,"FAILED to get ordinal #2\n");
	}

	/* 4th ordinal does NOT exist */
	if (ne_module_entry_point_by_ordinal(&ne,4) != NULL)
		fprintf(stdout,"FAILURE: 4th ordinal should not exist\n");

	/* do it again, going by name */
	entry = ne_module_entry_point_by_name(&ne,"MESSAGE");
	if (entry != NULL)
		fprintf(stdout,"MESSAGE entry point: %Fs\n",entry);
	else
		fprintf(stdout,"FAILURE: Entry 'MESSAGE' does not exist\n");

	/* 1st and 2nd ordinals are functions */
	{
		int (far __stdcall *hello1)() = (int (far __stdcall *)())
			ne_module_entry_point_by_name(&ne,"HELLO1");

		if (hello1 != NULL)
			fprintf(stdout,"HELLO1 function call worked, returned 0x%04x\n",hello1());
		else
			fprintf(stdout,"FAILED to get HELLO1\n");
	}
	{
		int (far __stdcall *hello2)(const char far *msg) = (int (far __stdcall *)(const char far *))
			ne_module_entry_point_by_name(&ne,"HELLO2");

		if (hello2 != NULL)
			fprintf(stdout,"HELLO2 function call worked, returned 0x%04x\n",hello2("This is a test string. I passed this to the function. Test GOOD\r\n"));
		else
			fprintf(stdout,"FAILED to get HELLO2\n");
	}

	ne_module_free(&ne);
	close(fd);

/* ====================================================== */

	fprintf(stdout,"=== NOW TESTING EXAMDLL2.DSO === \n");

	/* examdll2 */
	if ((fd=open("examdll2.dso",O_RDONLY|O_BINARY)) < 0) {
		fprintf(stdout,"Cannot open EXAMDLL2.DSO\n");
		return 1;
	}
	if (ne_module_load_header(&ne,fd)) {
		fprintf(stdout,"Failed to load header\n");
		return 1;
	}
	ne_module_dump_header(&ne,stdout);
	if (ne_module_load_segmentinfo(&ne)) {
		fprintf(stdout,"Failed to load segment info\n");
		return 1;
	}
	if (ne_module_load_segments(&ne)) {
		fprintf(stdout,"Failed to load segment\n");
		ne_module_dump_segmentinfo(&ne,stdout);
		return 1;
	}
	ne_module_dump_segmentinfo(&ne,stdout);
	if (ne_module_load_and_apply_relocations(&ne))
		fprintf(stdout,"Failed to load and apply relocation data\n");
	if (ne_module_load_entry_points(&ne)) {
		fprintf(stdout,"Failed to load entry points\n");
		return 1;
	}
	fprintf(stdout,"%u entry points\n",ne.ne_entry_points);
	for (xx=1;xx <= ne.ne_entry_points;xx++) {
		nent = ne_module_get_ordinal_entry_point(&ne,xx);
		entry = ne_module_entry_point_by_ordinal(&ne,xx);
		if (nent != NULL) {
			fprintf(stdout,"  [%u] flags=0x%02x segn=%u offset=0x%04x entry=%Fp\n",
				xx,nent->flags,nent->segment_index,nent->offset,entry);
		}
	}

	/* Load Resident Name Table */
	if (ne_module_load_name_table(&ne))
		fprintf(stdout,"Failed to load name table\n");

	/* dump the resident/nonresident tables */
	fprintf(stdout,"Resident names:\n");
	ne_module_dump_resident_table(ne.ne_resident_names,ne.ne_resident_names_length,stdout);
	fprintf(stdout,"Nonresident names:\n");
	ne_module_dump_resident_table(ne.ne_nonresident_names,ne.ne_nonresident_names_length,stdout);

	/* 3rd ordinal is MESSAGE data object, which is actually now a far pointer (to test that our relocation code works) */
	entry = ne_module_entry_point_by_ordinal(&ne,3);
	if (entry != NULL) {
		fprintf(stdout,"Got ordinal #3, far ptr %Fp\n",entry);
		entry = *((unsigned char far**)entry);
		fprintf(stdout,"   Which gives %Fp, %s\n",entry,entry);
	}
	else {
		fprintf(stdout,"FAILED to get ordinal #3\n");
	}

	entry = ne_module_entry_point_by_ordinal(&ne,4);
	if (entry != NULL) {
		fprintf(stdout,"Got ordinal #4, far ptr %Fp\n",entry);
		entry = *((unsigned char far**)entry);
		fprintf(stdout,"   Which gives %Fp, %s\n",entry,entry);
	}
	else {
		fprintf(stdout,"FAILED to get ordinal #4\n");
	}

	/* 1st and 2nd ordinals are functions */
	{
		int (far __stdcall *hello1)() = (int (far __stdcall *)())
			ne_module_entry_point_by_ordinal(&ne,1);

		if (hello1 != NULL)
			fprintf(stdout,"Ordinal #1 function call worked, returned 0x%04x\n",hello1());
		else
			fprintf(stdout,"FAILED to get ordinal #1\n");
	}
	{
		int (far __stdcall *hello2)(const char far *msg) = (int (far __stdcall *)(const char far *))
			ne_module_entry_point_by_ordinal(&ne,2);

		if (hello2 != NULL)
			fprintf(stdout,"Ordinal #2 function call worked, returned 0x%04x\n",hello2("This is a test string. I passed this to the function. Test GOOD\r\n"));
		else
			fprintf(stdout,"FAILED to get ordinal #2\n");
	}

	/* do it again, going by name */
	entry = ne_module_entry_point_by_name(&ne,"MESSAGE");
	if (entry != NULL) {
		fprintf(stdout,"Got MESSAGE, far ptr %Fp\n",entry);
		entry = *((unsigned char far**)entry);
		fprintf(stdout,"   Which gives %Fp, %s\n",entry,entry);
	}
	else {
		fprintf(stdout,"FAILURE: Entry 'MESSAGE' does not exist\n");
	}

	entry = ne_module_entry_point_by_name(&ne,"MESSAGE2");
	if (entry != NULL) {
		fprintf(stdout,"Got MESSAGE2, far ptr %Fp\n",entry);
		entry = *((unsigned char far**)entry);
		fprintf(stdout,"   Which gives %Fp, %s\n",entry,entry);
	}
	else {
		fprintf(stdout,"FAILURE: Entry 'MESSAGE2' does not exist\n");
	}

	/* 1st and 2nd ordinals are functions */
	{
		int (far __stdcall *hello1)() = (int (far __stdcall *)())
			ne_module_entry_point_by_name(&ne,"HELLO1");

		if (hello1 != NULL)
			fprintf(stdout,"HELLO1 function call worked, returned 0x%04x\n",hello1());
		else
			fprintf(stdout,"FAILED to get HELLO1\n");
	}
	{
		int (far __stdcall *hello2)(const char far *msg) = (int (far __stdcall *)(const char far *))
			ne_module_entry_point_by_name(&ne,"HELLO2");

		if (hello2 != NULL)
			fprintf(stdout,"HELLO2 function call worked, returned 0x%04x\n",hello2("This is a test string. I passed this to the function. Test GOOD\r\n"));
		else
			fprintf(stdout,"FAILED to get HELLO2\n");
	}

	ne_module_free(&ne);
	close(fd);

	return 0;
}

