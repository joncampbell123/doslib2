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

