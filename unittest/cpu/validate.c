/* validation program for unittest/cpu. must be run in the same directly as test results. */

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>
#ifndef TARGET_LINUX
# include <conio.h>
#endif
#include <errno.h>
#include <stdio.h>
#include <fcntl.h>

#include <traplog/dos/traplog.h>

#ifndef O_BINARY
#define O_BINARY 0
#endif

static int logging_mode = 1;
static int logging_headers = 1;
static int logging_passfail = 1;
static const char tf_null_log[] = "tf_null.log\0";
static const char str_err_missing_logfile[] = "Log file of test is missing\0";

#ifdef TARGET_LINUX
/* GNU C provides a pause() that doesn't seem to exit when you hit ENTER */
# define pause __my_pause
static void pause() {
	unsigned char c;

	/* GNU C does not provide getch(). And STDIN is probably a terminal
	 * in cooked mode. But it will return data (CR or LF) when the user
	 * hits ENTER, so... good enough I suppose. */
	do {
		if (read(0,&c,1) < 1) break;
	} while (c != 13 && c != 10);
}
#else
static void pause() {
	int c;

	/* wait for ENTER. MS-DOS CONIO usage ensures CTRL+C works. */
	do {
		c=getch();
	} while (c != 13 && c != 10);
}
#endif

static int read8086(struct tf8086_record *rec,int fd) {
	int rd;

	rd = read(fd,rec,sizeof(*rec));
	if (rd < sizeof(*rec)) {
		fprintf(stderr,"[8086 read: Record read failed %d/%d]\n",rd,(int)sizeof(*rec));
		return -1;
	}
	if (rec->r_recid != 0x8086 || rec->r_reclen != sizeof(*rec)) {
		fprintf(stderr,"[8086 read: wrong record type (ID=0x%04x LEN=0x%04x)\n",rec->r_recid,rec->r_reclen);
		return -1;
	}

	return 0;
}

static void log_test_begin(const char *name) {
	if (!logging_mode || !logging_headers) return;
	printf("-%s\n",name);
}

static void log_test_error(const char *error) {
	if (!logging_mode) return;
	printf("!%s\n",error);
}

static void log_test_warning(const char *msg) {
	if (!logging_mode) return;
	printf("?%s\n",msg);
}

static void log_test_explanation(const char *msg) {
	if (!logging_mode) return;
	printf(">>%s\n",msg);
}

static void log_test_note(const char *msg) {
	if (!logging_mode) return;
	printf(".%s\n",msg);
}

static void log_passfail(unsigned char pass) {
	if (!logging_mode || !logging_passfail) return;
	printf("=%s\n",pass?"PASS":"FAIL");
}

#define log_pass() log_passfail(1)
#define log_fail() log_passfail(0)

static int v_tf_null() {
	struct tf8086_record rec;
	int fd,i;

	log_test_begin("TF_NULL Trap flag NOP test");

	/* this is called when invoked as "VALIDATE TF_NULL" */
	/* our job is to let execution run through if OK, or to
	 * pause and wait for user input if anything is wrong or
	 * funny about the traplog. the pause routing uses getch()
	 * which the C runtime maps to MS-DOS CONIO calls, giving
	 * MS-DOS the time to properly interpret CTRL+C if the
	 * user wants the test to stop. */
	if ((fd=open(tf_null_log,O_RDONLY|O_BINARY)) < 0) {
		log_test_error(str_err_missing_logfile);
		fprintf(stderr,"Failed to open %s\n",tf_null_log);
		return 0;
	}

#if 0
typedef struct tf8086_record {
	uint16_t			r_recid;
	uint16_t			r_reclen;
	uint16_t			r_di;
	uint16_t			r_si;
	uint16_t			r_bp;
	uint16_t			r_sp;
	uint16_t			r_bx;
	uint16_t			r_dx;
	uint16_t			r_cx;
	uint16_t			r_ax;
	uint16_t			r_flags;
	uint16_t			r_ip;
	uint16_t			r_cs;
	uint16_t			r_ss;
	uint16_t			r_ds;
	uint16_t			r_es;
	unsigned char			r_csip_capture[4];
	unsigned char			r_sssp_capture[4];
} tf8086_record; /* 40 bytes */
#endif

	/* TF_NULL.ASM sequence
	 *
	 *    CLI    <- Because of the way the trap flag works, this executes first before the CPU traps,
	 *              and is not logged by TFL8086.COM. If it IS logged then the CPU is weird and the
	 *              fact needs to be noted.
	 *    NOP    <- Should normally be first entry in traplog
	 *    NOP
	 *    NOP
	 *    NOP
	 *    NOP
	 *    NOP
	 *    NOP
	 *    NOP
	 *    RET
	 */
	if (read8086(&rec,fd)) goto fail;

	if (rec.r_ip == 0x0100) {
		log_test_warning("First CPU trap at 1st instruction, not 2nd, which is unusual");
		log_test_explanation("When a program or OS sets the trap flag and IRETs to the program,");
		log_test_explanation("the CPU will normally one instruction THEN honor the trap flag.");
		log_test_explanation("A normal trap log will show the first CPU trap occuring at the 2nd");
		log_test_explanation("instruction in the program.");

		/* validate: what was executed was the CLI at the start of the program */
		if (rec.r_csip_capture[0] != 0xFA) {
			log_test_error("But the first instruction is NOT a CLI! Did the right binary execute??");
			goto fail;
		}

		/* read the next record, which should be the first NOP */
		if (read8086(&rec,fd)) goto fail;
	}
	if (rec.r_ip != 0x0101) {
		log_test_error("First instruction did not execute at 0x101");
		log_test_explanation("The first TF log entry should indicate execution of a NOP at 0x101");
		goto fail;
	}
	if (rec.r_csip_capture[0] != 0x90) {
		log_test_error("First instruction at 0x101 is not a NOP");
		log_test_explanation("The first TF log entry should indicate execution of a NOP at 0x101");
		goto fail;
	}

	/* and then we should see 7 more NOPs */
	for (i=1;i < 8;i++) {
		if (read8086(&rec,fd)) goto fail;
		if (rec.r_ip != (0x0101+i)) {
			log_test_error("Unexpected instruction pointer value for Nth occurrence of NOP (should be 8)");
			goto fail;
		}
		if (rec.r_csip_capture[0] != 0x90) {
			log_test_error("Nth instruction is not a NOP (should be 8)");
			goto fail;
		}
	}

	/* one more instruction: a RET to exit to DOS */
	if (read8086(&rec,fd)) goto fail;
	if (rec.r_csip_capture[0] != 0xC3) {
		log_test_error("RET expected after 8 NOPs");
		goto fail;
	}
	if (rec.r_ip != 0x0109) {
		log_test_error("Unexpected instruction pointer value for RET");
		goto fail;
	}

	/* normal behavior: RET returns to IP=0x0000 within the PSP segment, which contains 0xCD 0x20 (INT 20h) */
	if (read8086(&rec,fd)) goto pass; /* at this point we don't care anymore if the log ends early */
	if (rec.r_ip != 0x0000)
		log_test_warning("Unusual return to DOS via RET. Instruction pointer should have changed to PSP segment start (0x0000)");
	if (rec.r_csip_capture[0] != 0xCD && rec.r_csip_capture[1] != 0x20)
		log_test_warning("Unusual code sequence in PSP segment (should be 0xCD 0x20 aka INT 20h)");

pass:	log_pass();
	close(fd);
	return 1; /* PASS */
fail:	log_fail();
	close(fd);
	return 0;
}

static int sv_tf_null() {
	if (!v_tf_null()) {
		fprintf(stderr,"\x07" "* TF_NULL trap log validation failed.\n");
		fprintf(stderr,"  Further tests based on trap logs may not be valid.\n");
		fprintf(stderr,"  Hit ENTER to continue, CTRL+C to stop now.\n");
		pause();
		return 1;
	}

	return 0;
}

int main(int argc,char **argv) {
	/* runtest.bat will call this program after tf_null.com execution to
	 * validate that the NOPs executed correctly. the file is TF_NULL.LOG */
	if (argc > 1) {
		if (!strcmp(argv[1],"tf_null")) {
			logging_headers = 0;
			logging_passfail = 0;
			return sv_tf_null();
		}
		else {
			fprintf(stderr,"Unknown special case validation\n");
			return 1;
		}
	}

	return 0;
}

