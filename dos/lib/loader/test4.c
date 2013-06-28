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

int main(int argc,char **argv,char **envp) {
	void far *entry;
	int fd;

	/* validate */
	assert(sizeof(struct ne_header) == 0x40);
	assert(sizeof(struct ne_segment_def) == 0x08);

	ne_module_zero(&ne);
	ne.enable_debug = 1;
	ne_module_zero(&ne2);
	ne2.enable_debug = 1;
	ne2.import_module_lookup = dso3_mod_lookup;

	fprintf(stdout,"=== NOW TESTING EXAMDLL2.DSO === \n");

	/* examdll2 */
	if ((fd=open("examdll2.dso",O_RDONLY|O_BINARY)) < 0) {
		fprintf(stdout,"Cannot open EXAMDLL2.DSO\n");
		return 1;
	}
	ne_module_set_fd_ownership(&ne,1);
	if (ne_module_general_load_fd(&ne,fd)) {
		fprintf(stdout,"Failed to load module\n");
		return 1;
	}
	fd = -1; /* forget the handle */

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

/* ====================================================== */

	fprintf(stdout,"=== NOW TESTING EXAMDLL3.DSO === \n");

	/* examdll3. This time use struct ne2 */
	if ((fd=open("examdll3.dso",O_RDONLY|O_BINARY)) < 0) {
		fprintf(stdout,"Cannot open EXAMDLL3.DSO\n");
		return 1;
	}
	ne_module_set_fd_ownership(&ne2,1);
	if (ne_module_general_load_fd(&ne2,fd)) {
		fprintf(stdout,"Failed to load module\n");
		return 1;
	}
	fd = -1; /* forget the handle */

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
	ne_module_free(&ne);

	return 0;
}

