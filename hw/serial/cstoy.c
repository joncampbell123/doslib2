#if defined(TARGET_WINDOWS) && defined(TARGET_WINDOWS_GUI)
# include <windows.h>
# include <windows/apihelp.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(TARGET_LINUX)
# include <sys/ioctl.h>
# include <sys/stat.h>
# include <unistd.h>
# include <stdlib.h>
# include <fcntl.h>
# include <termios.h> /* for serial TTY control functions */
#endif

#if defined(TARGET_WINDOWS) && defined(TARGET_WINDOWS_GUI)
# error NOOOOOOOOOO Im not a GUI program
#else
int main() {
	printf("Hello\n");
	return 0;
}
#endif

