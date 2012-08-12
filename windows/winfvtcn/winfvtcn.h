/* winfcon.h
 *
 * Fake console for Windows applications where a console is not available.
 * This one emulates a DEC VT100 "ANSI" terminal.
 * (C) 2011-2012 Jonathan Campbell.
 * Hackipedia DOS library.
 *
 * This code is licensed under the LGPL.
 * <insert LGPL legal text here>
 */

/* Windows 3.1 and earlier, even for Win32s: there is no system given console.
 * We either have to draw and maintain our own window, or find some other way to printf() and display it. */
#if defined(TARGET_WINDOWS) && defined(TARGET_WINDOWS_GUI) && !defined(TARGET_WINDOWS_CONSOLE) && defined(WINFVCTN_ENABLE)
# define WIN_STDOUT_CONSOLE

# include <windows.h>
# include <stddef.h>
# include <stdint.h>
# include <limits.h>
# include <stdlib.h>
# include <string.h>
# include <stdio.h>

#ifndef WINFVCTN_SELF
# define getch _winvt_getch
# define kbhit _winvt_kbhit
# define fprintf __XXX_TODO_fprintf
# define printf _winvt_printf
# define isatty _winvt_isatty
# define write _winvt_write
# define read _winvt_read
#endif

void _winvt_pump();
int _winvt_kbhit();
int _winvt_getch();
HWND _winvt_hwnd();
void _gdivt_pause();
void _winvt_pump_wait();
void _winvt_putc(char c);
int _winvt_isatty(int fd);
void _winvt_endloop_user_echo();
int _winvt_read(int fd,void *buf,int sz);
size_t _winvt_printf(const char *fmt,...);
int _winvt_write(int fd,const void *buf,int sz);
int _cdecl main(int argc,char **argv,char **envp);
int WINMAINPROC _winvt_main_vtcon_entry(HINSTANCE hInstance,HINSTANCE hPrevInstance,LPSTR lpCmdLine,int nCmdShow,int (_cdecl *_main_f)(int argc,char**,char**));

extern HINSTANCE _winvt_hInstance;

# ifdef WINFVCTN_STOCK_WIN_MAIN
int WINMAINPROC WinMain(HINSTANCE hInstance,HINSTANCE hPrevInstance,LPSTR lpCmdLine,int nCmdShow) {
	return _winvt_main_vtcon_entry(hInstance,hPrevInstance,lpCmdLine,nCmdShow,main);
}
# endif
#endif

