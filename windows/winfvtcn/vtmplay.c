#if defined(TARGET_WINDOWS)
# include <windows.h>
# include <windows/apihelp.h>
# if defined(TARGET_WINDOWS_GUI) && !defined(TARGET_WINDOWS_CONSOLE)
#  define WINFVCTN_ENABLE 1
#  define WINFVCTN_STOCK_WIN_MAIN 1
#  include <windows/winfvtcn/winfvtcn.h>
# endif
#endif
#if defined(TARGET_LINUX) && defined(__GNUC__)
# include <termios.h>
#endif

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <misc/useful.h>

#ifndef VT_ESC
# define VT_ESC "\x1B"
#endif

#define INTERVAL (50)

#if defined(TARGET_LINUX) && defined(__GNUC__)
static int getch() {
	char c;

	if (read(0/*STDIN*/,&c,1) == 1)
		return (int)((unsigned char)c);

	return -1;
}

static struct termios termios_orig,termios_now;

static void termios_save() {
	tcgetattr(0/*STDIN*/,&termios_orig);
	termios_now = termios_orig;
}

static void termios_immediate_mode() {
	termios_now.c_lflag &= ~(ICANON|ECHO|ECHOE|ECHOK|ECHONL|ECHOCTL);
	tcsetattr(0/*STDIN*/,TCSANOW,&termios_now);
}

static void termios_restore() {
	tcsetattr(0/*STDIN*/,TCSANOW,&termios_orig);
}
#endif

int main() {
#if defined(TARGET_WINDOWS)
	DWORD basetime;
#endif
	const char *anim = NULL;
	int bytes_per_sec;
	char blk[256];
	int blksz;
	FILE *fp;
	char c;
	int rd;

#if defined(TARGET_LINUX) && defined(__GNUC__)
	termios_save();
	termios_immediate_mode();
#endif

	printf("Select animation:\n");
	printf("1. test.vtm [Alice in Wonderland-esque ANSI animation]\n");
	printf("2. startrek.vtm\n");
	printf("3. firework.vtm\n");
	printf("4. firewor2.vtm\n");
	printf("5. fishy.vtm\n");
	printf("6. dirty.vtm\n");
	printf("7. trek.vtm\n");
	printf("8. turkey.vtm\n");
	printf("9. hell01.vtm\n");
	printf("a. shadowgt.vtm\n");
	printf("b. xmas1.vtm\n");
	printf("ESC to quit\n");

	do {
		c = getch();
		if (c == 27) return 0;
		else if (c == '1') {
			bytes_per_sec = 2400/8;
			anim = "test.vtm";
			break;
		}
		else if (c == '2') {
			bytes_per_sec = 14400/8;
			anim = "startrek.vtm";
			break;
		}
		else if (c == '3') {
			bytes_per_sec = 4800/8;
			anim = "firework.vtm";
			break;
		}
		else if (c == '4') {
			bytes_per_sec = 2400/8;
			anim = "firewor2.vtm";
			break;
		}
		else if (c == '5') {
			bytes_per_sec = 19200/8;
			anim = "fishy.vtm";
			break;
		}
		else if (c == '6') {
			bytes_per_sec = 2400/8;
			anim = "dirty.vtm";
			break;
		}
		else if (c == '7') {
			bytes_per_sec = 2400/8;
			anim = "trek.vtm";
			break;
		}
		else if (c == '8') {
			bytes_per_sec = 9600/8;
			anim = "turkey.vtm";
			break;
		}
		else if (c == '9') {
			bytes_per_sec = 28800/8;
			anim = "hell01.vtm";
			break;
		}
		else if (c == 'a') {
			bytes_per_sec = 28800/8;
			anim = "shadowgt.vtm";
			break;
		}
		else if (c == 'b') {
			bytes_per_sec = 14400/8;
			anim = "xmas1.vtm";
			break;
		}
	} while (1);

	blksz = (((unsigned long)bytes_per_sec * (unsigned long)INTERVAL) + 500UL) / 1000UL;
	assert(blksz <= sizeof(blk));

	if (anim == NULL) {
		printf("Failed to choose animation\n");
#ifdef WIN_STDOUT_CONSOLE
		_winvt_endloop_user_echo();
#endif
		return 1;
	}

	printf(VT_ESC "c"); /* reset terminal */
	printf(VT_ESC "[H"); /* home */

	fp = fopen(anim,"r");
	if (fp == NULL) {
		printf("Failed to open animation\n");
#ifdef WIN_STDOUT_CONSOLE
		_winvt_endloop_user_echo();
#endif
		return 1;
	}

#if defined(TARGET_WINDOWS)
	basetime = GetCurrentTime();
#endif

	while ((rd = fread(blk,1,blksz,fp)) > 0) {
		write(1/*stdout*/,blk,rd);
		fflush(stdout);

		/* wait */
#if defined(TARGET_LINUX)
		usleep(INTERVAL * 1000);
#elif defined(TARGET_WINDOWS)
		{
			DWORD a,delta;

			do {
				_winvt_pump();
				_gdivt_pause();
				a = GetCurrentTime();
				delta = (a - basetime);
			} while (delta < INTERVAL);
			basetime += INTERVAL;
		}
#else
# error unknown target
#endif
	}

	fclose(fp);
#if defined(TARGET_LINUX) && defined(__GNUC__)
	termios_restore();
#endif
#ifdef WIN_STDOUT_CONSOLE
	_winvt_endloop_user_echo();
#endif
	return 0;
}

