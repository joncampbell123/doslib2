/* WARNING: This code assumes 16-bit real mode */

#include <sys/types.h>
#include <sys/stat.h>
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

static struct ne_module *nem1,*nem2;

static void call1() {
	{
		int (far __stdcall *hello1)() = (int (far __stdcall *)())
			ne_module_entry_point_by_name(nem1,"HELLO1");

		if (hello1 != NULL)
			fprintf(stdout,"HELLO1 function call worked, returned 0x%04x\n",hello1());
		else
			fprintf(stdout,"FAILED to get HELLO1\n");
	}
	{
		int (far __stdcall *hello2)(const char far *msg) = (int (far __stdcall *)(const char far *))
			ne_module_entry_point_by_name(nem1,"HELLO2");

		if (hello2 != NULL)
			fprintf(stdout,"HELLO2 function call worked, returned 0x%04x\n",hello2("This is a test string. I passed this to the function. Test GOOD\r\n"));
		else
			fprintf(stdout,"FAILED to get HELLO2\n");
	}
}

int main(int argc,char **argv,char **envp) {
	/* validate */
	assert(sizeof(struct ne_header) == 0x40);
	assert(sizeof(struct ne_segment_def) == 0x08);

	ne_mod_debug = 1;
	if ((nem1=ne_module_loadlibrary("examdll2")) == NULL) {
		fprintf(stdout,"Cannot open EXAMDLL2.DSO\n");
		return 1;
	}
	if ((nem2=ne_module_loadlibrary("examdll3")) == NULL) {
		fprintf(stdout,"Cannot open EXAMDLL3.DSO\n");
		return 1;
	}
	ne_module_freelibrary(nem1);
	ne_module_freelibrary(nem2);
	ne_module_gclibrary();


	if ((nem2=ne_module_loadlibrary("examdll3")) == NULL) {
		fprintf(stdout,"Cannot open EXAMDLL3.DSO\n");
		return 1;
	}
	ne_module_freelibrary(nem2);
	ne_module_gclibrary();


	if ((nem2=ne_module_loadlibrary("examdll3")) == NULL) {
		fprintf(stdout,"Cannot open EXAMDLL3.DSO\n");
		return 1;
	}
	if ((nem1=ne_module_getmodulehandle("examdll2")) == NULL) { /* EXAMDLL3.DSO depends on EXAMDLL2.DSO */
		fprintf(stdout,"Cannot get EXAMDLL2.DSO\n");
		return 1;
	}
	call1();
	ne_module_freelibrary(nem2);
	ne_module_gclibrary();


	if ((nem2=ne_module_loadlibrary("examdll4")) == NULL) {
		fprintf(stdout,"Cannot open EXAMDLL4.DSO\n");
		return 1;
	}
	if ((nem1=ne_module_getmodulehandle("examdll2")) == NULL) { /* EXAMDLL4.DSO depends on EXAMDLL2.DSO */
		fprintf(stdout,"Cannot get EXAMDLL2.DSO\n");
		return 1;
	}
	call1();
	ne_module_freelibrary(nem2);
	ne_module_gclibrary();

	ne_module_free_all();
	return 0;
}

