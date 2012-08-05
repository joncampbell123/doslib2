#if defined(TARGET_WINDOWS) && defined(TARGET_WINDOWS_GUI)
# include <windows.h>

/* Problem: Watcom C runtime will call our WinMain according to memory model.
 *          If we blindly use the "WINAPI" or "STDCALL" types the function
 *          will be defined as FAR regardless, and therefore the runtime will
 *          call it wrong and crash on shutdown for small/compact memory model
 *          builds */
# if defined(__SMALL__) || defined(__COMPACT__)
#  define WINMAINPROC __pascal near
# else
#  define WINMAINPROC __pascal far
# endif
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char desc[1024];

void do_desc() {
	char *p = desc;

	*p = 0;
#ifdef TARGET_MSDOS
	p += sprintf(p,"TARGET_MSDOS=%d\n",TARGET_MSDOS);
#endif
#ifdef TARGET_WINDOWS
	p += sprintf(p,"TARGET_WINDOWS=%d\n",TARGET_WINDOWS);
#endif
#ifdef TARGET_WINDOWS_GUI
	p += sprintf(p,"TARGET_WINDOWS_GUI=%d\n",TARGET_WINDOWS_GUI);
#endif
#ifdef TARGET_WINDOWS_WIN16
	p += sprintf(p,"TARGET_WINDOWS_WIN16=%d\n",TARGET_WINDOWS_WIN16);
#endif
#ifdef TARGET_WINDOWS_WIN386
	p += sprintf(p,"TARGET_WINDOWS_WIN386=%d\n",TARGET_WINDOWS_WIN386);
#endif
#ifdef TARGET_WINDOWS_VERSION
	p += sprintf(p,"TARGET_WINDOWS_VERSION=%d\n",TARGET_WINDOWS_VERSION);
#endif
#ifdef TARGET_BITS
	p += sprintf(p,"TARGET_BITS=%d\n",TARGET_BITS);
#endif
#ifdef TARGET_REALMODE
	p += sprintf(p,"TARGET_REALMODE=%d\n",TARGET_REALMODE);
#endif
#ifdef TARGET_PROTMODE
	p += sprintf(p,"TARGET_PROTMODE=%d\n",TARGET_PROTMODE);
#endif
#ifdef TARGET_AUTOMODE
	p += sprintf(p,"TARGET_AUTOMODE=%d\n",TARGET_AUTOMODE);
#endif
#ifdef TARGET_CPU
	p += sprintf(p,"TARGET_CPU=%d\n",TARGET_CPU);
#endif
#ifdef TARGET_CPUONLY
	p += sprintf(p,"TARGET_CPUONLY=%d\n",TARGET_CPUONLY);
#endif
#ifdef TARGET_EXTLIB
	p += sprintf(p,"TARGET_EXTLIB=%d\n",TARGET_EXTLIB);
#endif
#ifdef TARGET_DEBUG
	p += sprintf(p,"TARGET_DEBUG=%d\n",TARGET_DEBUG);
#endif
#ifdef __COMPACT__
	p += sprintf(p,"__COMPACT__\n");
#endif
#ifdef __SMALL__
	p += sprintf(p,"__SMALL__\n");
#endif
#ifdef __MEDIUM__
	p += sprintf(p,"__MEDIUM__\n");
#endif
#ifdef __LARGE__
	p += sprintf(p,"__LARGE__\n");
#endif
#ifdef __HUGE__
	p += sprintf(p,"__HUGE__\n");
#endif
#ifdef __386__ /* This is Watcom C's way of indicating the use of the 32-bit compiler */
	p += sprintf(p,"__386__\n");
#endif
}

#if defined(TARGET_WINDOWS) && defined(TARGET_WINDOWS_GUI)
int WINMAINPROC WinMain(HINSTANCE hInstance,HINSTANCE hPrevInstance,LPSTR lpCmdLine,int nCmdShow) {
	do_desc();
	MessageBox(NULL,desc,"",MB_OK);
	return 0;
}
#else
int main() {
	do_desc();
	printf("%s",desc);
	return 0;
}
#endif

