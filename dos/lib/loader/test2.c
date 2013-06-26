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

struct ne_module ne;
struct ne_module ne2;

/* for EXAMDLL3.DSO: Lookup callback. We check for references to examdll2.dso.
 * This is assigned such that:
 *
 * ne = examdll2.dso
 * ne2 = examdll3.dso */
static struct ne_module* dso3_mod_lookup(struct ne_module *to_mod,const char *modname) {
	if (!strcasecmp(modname,"examdll2.dso"))
		return &ne;
	if (!strcasecmp(modname,"examdll2")) /* <- NTS: If only the 'IMPORT' directive allowed the file name AND extension >:( */
		return &ne;

	return NULL;
}

/* intercept */
static const char far *intercepted_message = "This message is not the original. It was intercepted successfully.";

/* intercept HELLO2 */
static int far __stdcall int_hello2(const char far *msg) {
	fprintf(stdout,"Surprise! HELLO2 has been intercepted! You tried to say:\n%Fs",msg);
	return (int)(0xA5A5U);
}

static void far* dso3_lookup_ordinal_hook(struct ne_module *to_mod,struct ne_module *from_mod,unsigned int ordinal) {
	if (from_mod == &ne) {
		if (ordinal == 2) {
			fprintf(stdout," :) Intercepting hello (#%d)\n",ordinal);
			return int_hello2;
		}
		else if (ordinal == 3) {
			fprintf(stdout," :) Intercepting message (#%d)\n",ordinal);
			return (void far*)(&intercepted_message);
		}
	}

	return ne_module_entry_point_by_ordinal(from_mod,ordinal);
}

static void far* dso3_lookup_name_hook(struct ne_module *to_mod,struct ne_module *from_mod,const char *name) {
	if (from_mod == &ne) {
		if (!strcasecmp(name,"HELLO2")) {
			fprintf(stdout," :) Intercepting hello %s\n",name);
			return int_hello2;
		}
		else if (!strcasecmp(name,"MESSAGE")) {
			fprintf(stdout," :) Intercepting %s\n",name);
			return (void far*)(&intercepted_message);
		}
	}

	return ne_module_entry_point_by_name(from_mod,name);
}

int main(int argc,char **argv,char **envp) {
	struct ne_entry_point* nent;
	void far *entry;
	unsigned int xx;
	int fd;

	/* validate */
	assert(sizeof(struct ne_header) == 0x40);
	assert(sizeof(struct ne_segment_def) == 0x08);

	ne_module_zero(&ne);
	ne.enable_debug = 1;
	ne_module_zero(&ne2);
	ne2.enable_debug = 1;
	ne2.import_module_lookup = dso3_mod_lookup;
	ne2.import_lookup_by_name = dso3_lookup_name_hook;
	ne2.import_lookup_by_ordinal = dso3_lookup_ordinal_hook;

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

	/* the library must NOT match the module name in the first slot */
	entry = ne_module_entry_point_by_name(&ne,"EXAMDLL2");
	if (entry != NULL)
		fprintf(stdout,"BUG: entry_point_by_name will match module name\n");

	/* try to load imported name table */
	if (ne_module_load_imported_name_table(&ne))
		fprintf(stdout,"Failed to load imp. name table\n");

	if (ne.ne_imported_names != NULL)
		fprintf(stdout,"Imported names: %Fp len=%u\n",
			ne.ne_imported_names,ne.ne_imported_names_length);
	if (ne.ne_module_reference_table != NULL)
		fprintf(stdout,"Module ref table:%Fp ents=%u\n",
			ne.ne_module_reference_table,ne.ne_header.module_reference_table_entries);

	fprintf(stdout,"External modules\n");
	ne_module_dump_imported_module_names(&ne);
	ne_module_release_fd(&ne); /* we're closing the file descriptor, let it know */
	close(fd);

/* ====================================================== */

	fprintf(stdout,"=== NOW TESTING EXAMDLL3.DSO === \n");

	/* examdll3. This time use struct ne2 */
	if ((fd=open("examdll3.dso",O_RDONLY|O_BINARY)) < 0) {
		fprintf(stdout,"Cannot open EXAMDLL3.DSO\n");
		return 1;
	}
	if (ne_module_load_header(&ne2,fd)) {
		fprintf(stdout,"Failed to load header\n");
		return 1;
	}
	ne_module_dump_header(&ne2,stdout);
	if (ne_module_load_segmentinfo(&ne2)) {
		fprintf(stdout,"Failed to load segment info\n");
		return 1;
	}
	if (ne_module_load_segments(&ne2)) {
		fprintf(stdout,"Failed to load segment\n");
		ne_module_dump_segmentinfo(&ne2,stdout);
		return 1;
	}
	ne_module_dump_segmentinfo(&ne2,stdout);

	/* try to load imported name table */
	if (ne_module_load_imported_name_table(&ne2))
		fprintf(stdout,"Failed to load imp. name table\n");

	if (ne2.ne_imported_names != NULL)
		fprintf(stdout,"Imported names: %Fp len=%u\n",
			ne2.ne_imported_names,ne2.ne_imported_names_length);
	if (ne2.ne_module_reference_table != NULL)
		fprintf(stdout,"Module ref table:%Fp ents=%u\n",
			ne2.ne_module_reference_table,ne2.ne_header.module_reference_table_entries);

	fprintf(stdout,"External modules\n");
	ne_module_dump_imported_module_names(&ne2);

	if (ne_module_load_and_apply_relocations(&ne2))
		fprintf(stdout,"Failed to load and apply relocation data\n");
	if (ne_module_load_entry_points(&ne2)) {
		fprintf(stdout,"Failed to load entry points\n");
		return 1;
	}
	fprintf(stdout,"%u entry points\n",ne2.ne_entry_points);
	for (xx=1;xx <= ne2.ne_entry_points;xx++) {
		nent = ne_module_get_ordinal_entry_point(&ne2,xx);
		entry = ne_module_entry_point_by_ordinal(&ne2,xx);
		if (nent != NULL) {
			fprintf(stdout,"  [%u] flags=0x%02x segn=%u offset=0x%04x entry=%Fp\n",
				xx,nent->flags,nent->segment_index,nent->offset,entry);
		}
	}

	/* Load Resident Name Table */
	if (ne_module_load_name_table(&ne2))
		fprintf(stdout,"Failed to load name table\n");

	/* dump the resident/nonresident tables */
	fprintf(stdout,"Resident names:\n");
	ne_module_dump_resident_table(ne2.ne_resident_names,ne2.ne_resident_names_length,stdout);
	fprintf(stdout,"Nonresident names:\n");
	ne_module_dump_resident_table(ne2.ne_nonresident_names,ne2.ne_nonresident_names_length,stdout);

	/* NTS: HOLY CRAP, THIS WORKS! */
	/* This function would not work properly nor get the strings correct (it calls into EXAMDLL2.DSO)
	 * if relocations were not applied correctly. */
	{
		int (far __stdcall *hello3)(const char far *msg) = (int (far __stdcall *)(const char far *))
			ne_module_entry_point_by_name(&ne2,"HELLO3");

		if (hello3 != NULL)
			fprintf(stdout,"HELLO3 function call worked, returned 0x%04x\n",hello3("This is a test string. I passed this to the function. Test GOOD TOO\r\n"));
		else
			fprintf(stdout,"FAILED to get HELLO3\n");
	}

	ne_module_free(&ne2);
	close(fd);

/* ====================================================== */

	fprintf(stdout,"=== NOW TESTING EXAMDLL4.DSO === \n");

	/* examdll3. This time use struct ne2 */
	if ((fd=open("examdll4.dso",O_RDONLY|O_BINARY)) < 0) {
		fprintf(stdout,"Cannot open EXAMDLL4.DSO\n");
		return 1;
	}
	if (ne_module_load_header(&ne2,fd)) {
		fprintf(stdout,"Failed to load header\n");
		return 1;
	}
	ne_module_dump_header(&ne2,stdout);
	if (ne_module_load_segmentinfo(&ne2)) {
		fprintf(stdout,"Failed to load segment info\n");
		return 1;
	}
	if (ne_module_load_segments(&ne2)) {
		fprintf(stdout,"Failed to load segment\n");
		ne_module_dump_segmentinfo(&ne2,stdout);
		return 1;
	}
	ne_module_dump_segmentinfo(&ne2,stdout);

	/* try to load imported name table */
	if (ne_module_load_imported_name_table(&ne2))
		fprintf(stdout,"Failed to load imp. name table\n");

	if (ne2.ne_imported_names != NULL)
		fprintf(stdout,"Imported names: %Fp len=%u\n",
			ne2.ne_imported_names,ne2.ne_imported_names_length);
	if (ne2.ne_module_reference_table != NULL)
		fprintf(stdout,"Module ref table:%Fp ents=%u\n",
			ne2.ne_module_reference_table,ne2.ne_header.module_reference_table_entries);

	fprintf(stdout,"External modules\n");
	ne_module_dump_imported_module_names(&ne2);

	if (ne_module_load_and_apply_relocations(&ne2))
		fprintf(stdout,"Failed to load and apply relocation data\n");
	if (ne_module_load_entry_points(&ne2)) {
		fprintf(stdout,"Failed to load entry points\n");
		return 1;
	}
	fprintf(stdout,"%u entry points\n",ne2.ne_entry_points);
	for (xx=1;xx <= ne2.ne_entry_points;xx++) {
		nent = ne_module_get_ordinal_entry_point(&ne2,xx);
		entry = ne_module_entry_point_by_ordinal(&ne2,xx);
		if (nent != NULL) {
			fprintf(stdout,"  [%u] flags=0x%02x segn=%u offset=0x%04x entry=%Fp\n",
				xx,nent->flags,nent->segment_index,nent->offset,entry);
		}
	}

	/* Load Resident Name Table */
	if (ne_module_load_name_table(&ne2))
		fprintf(stdout,"Failed to load name table\n");

	/* dump the resident/nonresident tables */
	fprintf(stdout,"Resident names:\n");
	ne_module_dump_resident_table(ne2.ne_resident_names,ne2.ne_resident_names_length,stdout);
	fprintf(stdout,"Nonresident names:\n");
	ne_module_dump_resident_table(ne2.ne_nonresident_names,ne2.ne_nonresident_names_length,stdout);

	/* NTS: HOLY CRAP, THIS WORKS! */
	/* This function would not work properly nor get the strings correct (it calls into EXAMDLL2.DSO)
	 * if relocations were not applied correctly. */
	{
		int (far __stdcall *hello3)(const char far *msg) = (int (far __stdcall *)(const char far *))
			ne_module_entry_point_by_name(&ne2,"HELLO3");

		if (hello3 != NULL)
			fprintf(stdout,"HELLO3 function call worked, returned 0x%04x\n",hello3("This is a test string. I passed this to the function. Test GOOD TOO\r\n"));
		else
			fprintf(stdout,"FAILED to get HELLO3\n");
	}

	ne_module_free(&ne2);
	close(fd);
	ne_module_free(&ne);

	return 0;
}

