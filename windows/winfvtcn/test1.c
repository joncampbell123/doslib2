#if defined(TARGET_WINDOWS)
# include <windows.h>
# include <windows/w32imphk/compat.h>
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

#if defined(TARGET_LINUX) && defined(__GNUC__)
static int getch() {
	char c;

	if (read(0/*STDIN*/,&c,1) == 1)
		return (int)((unsigned char)c);

	return -1;
}

static int kbhit() {
	struct timeval tv={0,0};
	fd_set f;
	int n;

	FD_ZERO(&f);
	FD_SET(0,&f);
	n = select(1/*STDIN+1*/,&f,NULL,NULL,&tv);
	return n > 0;
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
	char chr;
	int c;
	int i;

#if defined(TARGET_LINUX) && defined(__GNUC__)
	termios_save();
	termios_immediate_mode();
#endif

/* TEST 1----------------------------------------------------------*/
	printf("You shouldn't see this text\n");
	printf(VT_ESC "c");
	printf("Normal text out\n");
	printf(VT_ESC "[1m" "Bright" VT_ESC "[0m" "\n");
	printf(VT_ESC "[2m" "Dim" VT_ESC "[0m" "\n");
	printf(VT_ESC "[4m" "Underscore" VT_ESC "[0m" "\n");
	printf(VT_ESC "[5m" "Blink" VT_ESC "[0m" "\n");
	printf(VT_ESC "[7m" "Reverse" VT_ESC "[0m" "\n");
	printf(VT_ESC "[8m" "Hidden" VT_ESC "[0m" "\n");
	printf(VT_ESC "[31m" "Red FG " VT_ESC "[1m" "Bright" VT_ESC "[0m" "\n");
	printf(VT_ESC "[41m" "Red BG " VT_ESC "[1m" "Bright" VT_ESC "[0m" "\n");

	/* our emulation even includes the double wide and double high modes */
	printf(VT_ESC "#6" "Double wide text\n");
	printf(VT_ESC "#3" "Double high text\n");
	printf(VT_ESC "#4" "Double high text\n");
	printf(VT_ESC "#5" "Normal text\n");

	/* wait for user's conformation */
	printf("Hit ENTER to continue, 'x' to stop\n");
	do { c = getch(); } while (!(c == 13 || c == 10 || c == 'x'));
	if (c == 'x') goto done;

/* TEST 2----------------------------------------------------------*/
	printf(VT_ESC "c");

	printf(VT_ESC "[?7l"); /* <- disable line wrap */
	printf("Line wrap enable/disable test. No wrap:"); fflush(stdout);
	chr = '-'; for (i=0;i < 400;i++) write(1/*STDOUT*/,"-",1);
	printf("\n");

	printf(VT_ESC "[?7h"); /* <- enable line wrap */
	printf("With wrap:"); fflush(stdout);
	chr = '-'; for (i=0;i < (160-11);i++) write(1/*STDOUT*/,"-",1);
	printf("*\n");

	printf("\n");
	printf("Normal text: " VT_ESC "(B" "abcdefghijklmnopqrstuvwxyz123456789\n");
	printf("Graphics:    " VT_ESC "(0" "abcdefghijklmnopqrstuvwxyz123456789\n");
	printf(VT_ESC "(B"); fflush(stdout);

	/* wait for user's conformation */
	printf("Hit ENTER to continue, 'x' to stop\n");
	do { c = getch(); } while (!(c == 13 || c == 10 || c == 'x'));
	if (c == 'x') goto done;

/* TEST 3----------------------------------------------------------*/
	printf(VT_ESC "c");

	i = 0;
	printf("Your terminal should be flashing now\n");
	printf("Hit ENTER to continue, 'x' to stop\n");
	do {
		c = 0;
		if (kbhit()) c = getch();
#if defined(TARGET_LINUX)
		usleep(100000);
#elif defined(TARGET_WINDOWS)
		{
			DWORD a,b,delta;

			b = GetCurrentTime();
			do {
# ifdef WIN_STDOUT_CONSOLE
				_winvt_pump();
				_gdivt_pause();
# endif
				a = GetCurrentTime();
				delta = (a - b);
			} while (delta < 100);
		}
#endif

		if (i == 0) {
			printf(VT_ESC "[?5h");
			fflush(stdout);
		}
		else if (i == 10) {
			printf(VT_ESC "[?5l");
			fflush(stdout);
		}

		if ((++i) >= 20) i = 0;
	} while (!(c == 13 || c == 10 || c == 'x'));
	if (c == 'x') goto done;
	printf(VT_ESC "[?5l");

/* TEST 4----------------------------------------------------------*/
	printf(VT_ESC "c");

	printf("Hit ENTER to continue, 'x' to stop\n");
	for (i=0;i < 25;i++) printf("Test row test row test row\n");
	printf(VT_ESC "[4H");
	printf(VT_ESC "[1L"); /* insert line at cursor */
	printf(VT_ESC "-- INSERTED ROW --\n");

	/* wait for user's conformation */
	do { c = getch(); } while (!(c == 13 || c == 10 || c == 'x'));
	if (c == 'x') goto done;

/* TEST 5----------------------------------------------------------*/
	printf(VT_ESC "c");

	printf(VT_ESC "[1;1H"  "------------ Scrolling region test ---------------\n");
	printf(VT_ESC "[24;1H" "^^^^^^^^^^^^ Scrolling region test ^^^^^^^^^^^^^^^\n");
	printf(VT_ESC "[2;23r");
	printf(VT_ESC "[2;1H");
	for (i=0;i < 100;i++) printf("Line %d\n",i);
	printf("The top and bottom lines should still be there"); fflush(stdout);

	/* wait for user's conformation */
	do { c = getch(); } while (!(c == 13 || c == 10 || c == 'x'));
	if (c == 'x') goto done;

/* TEST 5b----------------------------------------------------------*/
	printf(VT_ESC "c");

	printf(VT_ESC "[1;1H"  "-------Smooth Scrolling region test ---------\n");
	printf(VT_ESC "[24;1H" "^^^^^^^Smooth Scrolling region test ^^^^^^^^^\n");
	printf(VT_ESC "[2;23r");
	printf(VT_ESC "[2;1H");
	printf(VT_ESC "[?4h"); /* enable smooth scroll */
	for (i=0;i < 100;i++) printf("Line %d\n",i);
	printf("The top and bottom lines should still be there,\n");
	printf("and the text should have scrolled by at 6 lines/second"); fflush(stdout);
	printf(VT_ESC "[?4l"); /* disable smooth scroll */

	/* wait for user's conformation */
	do { c = getch(); } while (!(c == 13 || c == 10 || c == 'x'));
	if (c == 'x') goto done;

/* TEST 6----------------------------------------------------------*/
	printf(VT_ESC "c");

	printf(VT_ESC "[?25l" "You should NOT see the cursor now. Hit ENTER to continue\n");

	/* wait for user's conformation */
	do { c = getch(); } while (!(c == 13 || c == 10 || c == 'x'));
	if (c == 'x') goto done;

	printf(VT_ESC "[?25h" "Now you should see the cursor now.\n");

	/* wait for user's conformation */
	do { c = getch(); } while (!(c == 13 || c == 10 || c == 'x'));
	if (c == 'x') goto done;

done:	printf("Test program finished\n");
#ifdef WIN_STDOUT_CONSOLE
	_winvt_endloop_user_echo();
#endif

#if defined(TARGET_LINUX) && defined(__GNUC__)
	termios_restore();
#endif

	return 0;
}

