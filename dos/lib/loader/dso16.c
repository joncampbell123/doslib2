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

void ne_module_zero(struct ne_module *n) {
	_fmemset(n,0,sizeof(*n));
	n->must_resolve_dependencies = 1;
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
	if (n->enable_debug) {
		if (n->reference_count != 0)
			fprintf(stderr,"WARNING: Module %Fp is being freed when refcount=%u\n",
				(void far*)n,n->reference_count);
	}

	ne_module_release_fd(n);
	ne_module_free_segments(n);
	ne_module_free_name_table(n);
	ne_module_free_entry_points(n);
	ne_module_free_segmentinfo(n);
}

void ne_module_release_fd(struct ne_module *n) {
	if (n->auto_close_fd) {
		if (n->fd >= 0) {
			if (n->enable_debug) {
				fprintf(stderr,"Module %Fp closing file descriptor %d (we own it)\n",
					(void far*)n,n->fd);
			}
			close(n->fd);
		}
	}
	else {
		if (n->fd >= 0) {
			if (n->enable_debug) {
				fprintf(stderr,"Module %Fp forgetting file descriptor %d (we don't own it)\n",
					(void far*)n,n->fd);
			}
		}
	}

	n->fd = -1;
}

uint16_t ne_module_addref(struct ne_module *n) {
	return (++n->reference_count);
}

uint16_t ne_module_release(struct ne_module *n) {
	if (n->reference_count != 0) {
		if ((--n->reference_count) == 0) {
			if (n->auto_free_on_release) {
				if (n->enable_debug) fprintf(stderr,"Module %Fp refcount==0 and auto-free-on-release, freeing resources now.\n");
				ne_module_release_fd(n);
				ne_module_free_segments(n);
				ne_module_free_name_table(n);
				ne_module_free_entry_points(n);
				ne_module_free_segmentinfo(n);
			}
		}
	}
	else {
		if (n->enable_debug) fprintf(stderr,"WARNING: Module %Fp release() when module already has refcount==0\n");
	}

	return n->reference_count;
}

#endif

