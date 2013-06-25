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

int ne_module_load_imported_name_table_list(struct ne_module *n) {
	unsigned int rd;

	if (n == NULL) return 0;
	if (n->ne_imported_names != NULL) return 0;
	if (n->ne_header.imported_name_table_rel_offset == 0) return 0;

	/* the "length" is implied by the distance from the imported name table to the entry table */
	if (n->ne_header.imported_name_table_rel_offset >= n->ne_header.entry_table_offset) return 0;

	n->ne_imported_names_length = n->ne_header.entry_table_offset - n->ne_header.imported_name_table_rel_offset;
	if (n->ne_imported_names_length > 32768) return 0;

	n->ne_imported_names = malloc(n->ne_imported_names_length);
	if (n->ne_imported_names == NULL) return 1;

	if (lseek(n->fd,n->ne_header.imported_name_table_rel_offset+n->ne_header_offset,SEEK_SET) !=
		(n->ne_header.imported_name_table_rel_offset+n->ne_header_offset)) {
		free(n->ne_imported_names);
		n->ne_imported_names = NULL;
		return 1;
	}
	if (_dos_read(n->fd,n->ne_imported_names,n->ne_imported_names_length,&rd) || rd != n->ne_imported_names_length) {
		free(n->ne_imported_names);
		n->ne_imported_names = NULL;
		return 1;
	}

	return 0;
}

int ne_module_load_module_reference_table_list(struct ne_module *n) {
	unsigned int rd;

	if (n == NULL) return 0;
	if (n->ne_module_reference_table != NULL) return 0;
	if (n->ne_header.module_reference_table_rel_offset == 0) return 0;
	if (n->ne_header.module_reference_table_entries == 0) return 0;
	if (n->ne_header.module_reference_table_entries > 256) return 0;

	n->ne_module_reference_table = malloc(sizeof(uint16_t) * n->ne_header.module_reference_table_entries);
	if (n->ne_module_reference_table == NULL) return 1;

	if (lseek(n->fd,n->ne_header.module_reference_table_rel_offset+n->ne_header_offset,SEEK_SET) !=
		(n->ne_header.module_reference_table_rel_offset+n->ne_header_offset)) {
		free(n->ne_module_reference_table);
		n->ne_module_reference_table = NULL;
		return 1;
	}
	if (_dos_read(n->fd,n->ne_module_reference_table,sizeof(uint16_t) * n->ne_header.module_reference_table_entries,&rd) ||
		rd != (sizeof(uint16_t) * n->ne_header.module_reference_table_entries)) {
		free(n->ne_module_reference_table);
		n->ne_module_reference_table = NULL;
		return 1;
	}

	return 0;
}

int ne_module_load_imported_name_table(struct ne_module *n) {
	if (ne_module_load_imported_name_table_list(n)) return 1;
	if (ne_module_load_module_reference_table_list(n)) return 1;
	return 0;
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

void ne_module_free_resident_name_table(struct ne_module *n) {
	if (n->ne_resident_names) {
		free(n->ne_resident_names);
		n->ne_resident_names = NULL;
		n->ne_resident_names_length = 0;
	}
}

void ne_module_free_nonresident_name_table(struct ne_module *n) {
	if (n->ne_nonresident_names) {
		free(n->ne_nonresident_names);
		n->ne_nonresident_names = NULL;
		n->ne_nonresident_names_length = 0;
	}
}

void ne_module_free_imported_name_table(struct ne_module *n) {
	if (n->ne_imported_names) {
		free(n->ne_imported_names);
		n->ne_imported_names = NULL;
		n->ne_imported_names_length = 0;
	}
	if (n->ne_module_reference_table) {
		free(n->ne_module_reference_table);
		n->ne_module_reference_table = NULL;
	}
}

void ne_module_free_name_table(struct ne_module *n) {
	ne_module_free_imported_name_table(n);
	ne_module_free_resident_name_table(n);
	ne_module_free_nonresident_name_table(n);
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

		/* NTS: do not match ordinal 0 because that is the module name */
		if (ord != 0 && match) return ord;
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

void ne_module_dump_imported_module_names(struct ne_module *n) {
	unsigned int x,len,o;
	char tmp[64];

	if (n == NULL) return;
	if (n->ne_module_reference_table == NULL) return;
	if (n->ne_imported_names == NULL) return;

	for (x=0;x < n->ne_header.module_reference_table_entries;x++) {
		o = n->ne_module_reference_table[x];
		if (o >= n->ne_imported_names_length) continue;

		len = n->ne_imported_names[o++];
		if ((o+len) > n->ne_imported_names_length) continue;

		if (len < 63) {
			if (len > 0) _fmemcpy(tmp,n->ne_imported_names+o,len);
			tmp[len] = 0;
		}
		else {
			tmp[0] = 0;
		}

		fprintf(stdout,"  #%d ofs=%u name=%s\n",x,o-1,tmp);
	}
}

#endif

