
#include <dos.h>
#include <stdio.h>
#include <fcntl.h>
#include <assert.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>

#if defined(TARGET_MSDOS) && TARGET_BITS == 16 && defined(TARGET_REALMODE)
/* TODO: ^ I believe this code is written in a generic enough fashion I *COULD* get it working
 *         in 16-bit protected mode as well. Then we could have 16-bit DPMI-enabled DOS programs
 *         using DSO's as well. */

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
	uint16_t		internal_flags;				/* internal flags */
#define NE_SEGMENT_ASSIGN_IF_RELOC_APPLIED			0x0001	/* relocation data has been applied */
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
	unsigned char*			ne_imported_names;
	uint16_t			ne_imported_names_length;
	uint16_t*			ne_module_reference_table;
	struct ne_module**		cached_imp_mod;
	uint16_t			reference_count;
	unsigned char			enable_debug:1;
	unsigned char			auto_free_on_release:1;
	unsigned char			auto_close_fd:1;
	unsigned char			must_resolve_dependencies:1;
	unsigned char			_reserved_:4;

	/* these callbacks are for the calling program to provide external modules so we can resolve import symbols */
	struct ne_module*		(*import_module_lookup)(struct ne_module *to_mod,const char *modname);
	/* these callbacks, if set, allows the program to intercept and redirect imports */
	void far*			(*import_lookup_by_ordinal)(struct ne_module *to_mod,struct ne_module *from_mod,unsigned int ordinal);
	void far*			(*import_lookup_by_name)(struct ne_module *to_mod,struct ne_module *from_mod,const char *name);
};

static inline ne_module_set_fd_ownership(struct ne_module *n,unsigned char x) {
	n->auto_close_fd = x?1:0;
}

struct ne_entry_point* ne_module_get_ordinal_entry_point(struct ne_module *n,unsigned int ordinal);
void far *ne_module_entry_point_by_ordinal(struct ne_module *n,unsigned int ordinal);
void ne_module_zero(struct ne_module *n);
int ne_module_load_header(struct ne_module *n,int fd);
int ne_module_load_and_apply_relocations(struct ne_module *n);
int ne_module_load_segments(struct ne_module *n);
int ne_module_load_segmentinfo(struct ne_module *n);
void ne_module_dump_segmentinfo(struct ne_module *n,FILE *fp);
int ne_module_load_resident_name_table(struct ne_module *n);
int ne_module_load_imported_name_table(struct ne_module *n);
int ne_module_load_nonresident_name_table(struct ne_module *n);
int ne_module_load_name_table(struct ne_module *n);
int ne_module_load_entry_points(struct ne_module *n);
unsigned int ne_module_raw_name_to_ordinal(unsigned char *p,unsigned int sz,const char *name);
unsigned int ne_module_name_to_ordinal(struct ne_module *n,const char *name);
void far *ne_module_entry_point_by_name(struct ne_module *n,const char *name);
void ne_module_dump_resident_table(unsigned char *p,unsigned int sz,FILE *fp);
void ne_module_dump_header(struct ne_module *n,FILE *fp);
void ne_module_free(struct ne_module *n);
int ne_module_load_segment(struct ne_module *n,unsigned int idx/*NTS: Segments in NE executables are 1-based NOT zero-based*/);
int ne_module_allocate_segment(struct ne_module *n,unsigned int idx/*NTS: Segments in NE executables are 1-based NOT zero-based*/);
int ne_module_load_and_apply_segment_relocations(struct ne_module *n,unsigned int idx/*NTS: 1-based, NOT zero-based*/);
int ne_module_free_segment(struct ne_module *n,unsigned int idx/*NTS: Segments in NE executables are 1-based NOT zero-based*/);
int ne_module_free_segments(struct ne_module *n);
void ne_module_free_resident_name_table(struct ne_module *n);
void ne_module_free_imported_name_table(struct ne_module *n);
void ne_module_free_nonresident_name_table(struct ne_module *n);
void ne_module_free_entry_points(struct ne_module *n);
void ne_module_free_name_table(struct ne_module *n);
void ne_module_free_segmentinfo(struct ne_module *n);
int ne_module_load_module_reference_table_list(struct ne_module *n);
int ne_module_load_imported_name_table_list(struct ne_module *n);
int ne_module_get_import_module_name(char *buf,int buflen,struct ne_module *n,unsigned int modidx);
void ne_module_dump_imported_module_names(struct ne_module *n);
void ne_module_flush_import_module_cache(struct ne_module *n);
uint16_t ne_module_addref(struct ne_module *n);
uint16_t ne_module_release(struct ne_module *n);
void ne_module_release_fd(struct ne_module *n);

#endif

