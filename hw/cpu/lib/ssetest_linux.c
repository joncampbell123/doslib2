#if defined(TARGET_LINUX)
# include <signal.h>
# include <unistd.h>
# include <sys/mman.h>

# include <stdio.h>
# include <assert.h>
# include <stdlib.h>
# include <string.h>
# include <stdint.h>
# include <hw/cpu/cpu.h>
# include <hw/cpu/cpusse.h>
# include <misc/useful.h>

/* Uncomment this #define to have an illegal instruction execute to test Linux SIGILL trapping */
/*# define DEBUG_SIGILL*/

static volatile unsigned int linux_sigill_counter;

static void _linux_sigill(int x,siginfo_t *nfo,void *n) {
	void *pbase = (void*)((size_t)nfo->si_addr & (~((size_t)0xFFFUL)));
	unsigned int o = (size_t)nfo->si_addr & (size_t)0xFFF;
	unsigned char *p = (unsigned char*)(nfo->si_addr);

	/* NTS: If we change nfo->si_addr Linux won't actually apply it to the instruction pointer.
	 *      So instead, we have to use mprotect() to make that code region writeable and nop
	 *      out the XORPS instruction */
	if (mprotect(pbase,o+3,PROT_READ|PROT_WRITE|PROT_EXEC))
		_exit(-1);

	p[0] = p[1] = p[2] = 0x90; /* NOP it out */
	linux_sigill_counter++; /* count it */

	/* put the protection back. it's code, so it's likely readonly.
	 * FIXME: Does Linux have a way to READ a page's attributes so we can accurately restore them? */
	if (mprotect(pbase,o+3,PROT_READ|PROT_EXEC))
		_exit(-1);
}

unsigned int cpu_sse_linux_test() {
	/* execute instruction. if it causes a SIGILL (illegal instruction) exception then SSE is not enabled in the kernel */
	struct sigaction ac={0},oc={0};

	ac.sa_sigaction = _linux_sigill;
	ac.sa_flags = SA_SIGINFO;
	sigaction(SIGILL,&ac,&oc);
	linux_sigill_counter = 0;
# ifdef DEBUG_SIGILL
	__asm__ __volatile__ (".byte 0xFF,0xFF,0xFF"); /* Deliberate invalid instruction to ensure Invalid Opcode exception happens */
# else
	__asm__ __volatile__ ("xorps %%xmm0,%%xmm0" : /*out*/ : /*in*/ : /*clobber*/);
# endif
	sigaction(SIGILL,&oc,NULL);

	/* I have no reason to believe the Linux kernel devs would enable SSE without preparing for SSE exceptions */
	return (linux_sigill_counter == 0) ? (CPU_SSE_ENABLED | CPU_SSE_EXCEPTIONS_ENABLED) : 0;
}
#endif /* TARGET_LINUX */

