#if defined(TARGET_WINDOWS)
# include <windows.h>
# include <windows/w32imphk/compat.h>
# include <windows/apihelp.h>
# if defined(TARGET_WINDOWS_GUI) && !defined(TARGET_WINDOWS_CONSOLE)
#  define WINFCON_ENABLE 1
#  define WINFCON_STOCK_WIN_MAIN 1
#  include <windows/winfcvtn/winfcvtn.h>
# endif
#endif

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <misc/useful.h>

int main() {
	printf("Normal text out\n");
	printf(VT_ESC "[1m" "Bright" VT_ESC "[0m" "\n");
	printf(VT_ESC "[2m" "Dim" VT_ESC "[0m" "\n");
	printf(VT_ESC "[4m" "Underscore" VT_ESC "[0m" "\n");
	printf(VT_ESC "[5m" "Blink" VT_ESC "[0m" "\n");
	printf(VT_ESC "[7m" "Reverse" VT_ESC "[0m" "\n");
	printf(VT_ESC "[31m" "Red FG" VT_ESC "[0m" "\n");
	printf(VT_ESC "[41m" "Red BG" VT_ESC "[0m" "\n");

#ifdef WIN_STDOUT_CONSOLE
	_winvt_endloop_user_echo();
#endif
	return 0;
}

