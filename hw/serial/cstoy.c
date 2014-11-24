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
# include <errno.h>
# include <dirent.h>
# include <signal.h>
# include <termios.h> /* for serial TTY control functions */
#endif

static int			DIE = 0;

#if defined(TARGET_LINUX) /* TODO: or other OSes that allow us to open the serial port by file handle */
static int			tty_fd = -1;

static int			ttyios_stdin = 0;
static struct termios		ttyios_old,ttyios_cur;

void sigma(int x) {
	if ((++DIE) >= 10) abort();
}
#endif

#if defined(TARGET_LINUX)
int prompt_open_serial() {
# define NAMES 64
	int ok = 0,choice = -1;
	struct dirent *d;
	char *name[64];
	int names=0;
	DIR *dir;

	if (tty_fd >= 0) return 1;

	/* enumerate serial ports using sysfs */
	dir = opendir("/sys/class/tty");
	if (!dir) {
		fprintf(stderr,"Cannot open /sys/class/tty/, %s\n",strerror(errno));
		return 0;
	}
	while ((d=readdir(dir)) != NULL) {
		struct stat st;

		if (d->d_name[0] == '.') continue;

		/* must be directory */
		if (fstatat(dirfd(dir),d->d_name,&st,0)) continue;
		if (!S_ISDIR(st.st_mode)) continue;

		/* must be named ttyS... or ttyUSB... */
		if (strncmp(d->d_name,"ttyS",4) != 0 && strncmp(d->d_name,"ttyUSB",6) != 0) continue;

		if (names < 64) {
			size_t l = strlen(d->d_name);
			name[names] = malloc(l+1);
			if (name[names] != NULL) {
				strcpy(name[names],d->d_name);
				names++;

				printf("%u: /dev/%s\n",names,name[names-1]);
			}
		}
	}
	closedir(dir);

	printf("Your choice? "); fflush(stdout); /* GLIBC will buffer per line on TTY */
	scanf("%d",&choice);
	if (choice >= 1 && choice <= names) {
		char npath[512];

		choice--;

		/* OK. open the device */
		snprintf(npath,sizeof(npath),"/dev/%s",name[choice]);
		tty_fd = open(npath,O_RDWR | O_NONBLOCK); /* O_NONBLOCK or else Linux will block in open() for modem control signals */
		if (tty_fd >= 0) {
			ok = 1;
			printf("Port open.\n");

			{
				struct termios x;

				/* please do it RAW */
				if (tcgetattr(tty_fd,&x) == 0) {
					cfmakeraw(&x);
					tcsetattr(tty_fd,TCSANOW,&x);
				}
			}
		}
		else {
			printf("Failed to open serial port, %s\n",strerror(errno));
		}
	}

	/* free strings */
	while (names > 0) {
		names--;
		free(name[names]);
	}

	return ok;
}
# undef NAMES
#else
int prompt_open_serial() {
	printf("Sorry, your OS is not supported\n");
	return 0;
}
#endif

void close_serial() {
#if defined(TARGET_LINUX)
	if (tty_fd >= 0) {
		printf("Closing serial port\n");
		close(tty_fd);
		tty_fd = -1;
	}
#endif
}

#if defined(TARGET_WINDOWS) && defined(TARGET_WINDOWS_GUI)
# error NOOOOOOOOOO Im not a GUI program
#else
int main() {
	char in_line[41],c=0;
	int redraw = 0;
#if defined(TARGET_LINUX)
	struct timeval stdin_tv;
	fd_set stdin_fdset;
	int mctl = -1,i;
#endif

	printf("Serial status + control line toy\n");
	printf("(C) 2014 Jonathan Campbell\n");
	printf("\n");

#if defined(TARGET_LINUX)
	/* we need the terminal in cooked mode for prompting */
	ttyios_stdin = isatty(0);
	if (ttyios_stdin) {
		tcgetattr(0,&ttyios_old);
		ttyios_cur = ttyios_old;
		ttyios_cur.c_lflag |= ICANON;
		tcsetattr(0,TCSANOW,&ttyios_cur);
	}

	signal(SIGINT,sigma);
	signal(SIGQUIT,sigma);
	signal(SIGTERM,sigma);
#endif

	if (!prompt_open_serial()) {
		printf("Nothing to open\n");
		return 1;
	}

#if defined(TARGET_LINUX)
	/* now raw */
	ttyios_stdin = isatty(0);
	if (ttyios_stdin) {
		ttyios_cur.c_lflag &= ~(ICANON|ECHO|ECHOK|ECHOKE);
		tcsetattr(0,TCSANOW,&ttyios_cur);
	}
#endif

	printf("Inbound characters will appear on this line.\n");
	printf("D=toggle DTR  R=toggle RTS  CTRL+C to exit.\n");

	memset(in_line,' ',40);
	in_line[40] = 0;
	redraw = 1;
	while (!DIE) {
#if defined(TARGET_LINUX)
		if (read(tty_fd,&c,1) > 0) {
			memmove(in_line,in_line+1,40);
			if (c < 32) c = '.';
			in_line[39] = c;
			redraw = 1;
		}

		FD_ZERO(&stdin_fdset);
		FD_SET(0,&stdin_fdset);
		stdin_tv.tv_sec = 0;
		stdin_tv.tv_usec = 0;
		if (select(0+1,&stdin_fdset,NULL,NULL,&stdin_tv) > 0) {
			if (read(0/*STDIN*/,&c,1) > 0) { /* FIXME: does not consider Linux VT100 escapes */
				if (c == 'd' || c == 'D') {
					int mc = TIOCM_DTR;
					if (ioctl(tty_fd,!(mctl&mc) ? TIOCMBIS : TIOCMBIC,&mc) < 0)
						fprintf(stderr,"ioctl fail, %s\n",strerror(errno));
				}
				else if (c == 'r' || c == 'R') {
					int mc = TIOCM_RTS;
					if (ioctl(tty_fd,!(mctl&mc) ? TIOCMBIS : TIOCMBIC,&mc) < 0)
						fprintf(stderr,"ioctl fail, %s\n",strerror(errno));
				}
				else {
					/* meh, send it down the wire */
					do {
						int d = write(tty_fd,&c,1);
						if (d == 1) break;
						else if (c < 0 && !(errno == EAGAIN || errno == EWOULDBLOCK)) {
							printf("\nSend error, %s\n",strerror(errno));
						}
					} while (1);
				}
			}
		}
#else
		c = 1;
#endif

#if defined(TARGET_LINUX)
		{
			int n_mctl = -1;
			if (ioctl(tty_fd,TIOCMGET,&n_mctl) >= 0) {
				if (n_mctl != mctl) {
					mctl = n_mctl;
					redraw = 1;
				}
			}
		}
#endif

		if (redraw) {
			redraw = 0;

			printf("\x0D");
#if defined(TARGET_LINUX)
			printf("IN:LE=%u CTS=%u CD=%u RI=%u DSR=%u OUT:DTR=%u RTS=%u ",
					(mctl&TIOCM_LE)?1:0,
					(mctl&TIOCM_CTS)?1:0,
					(mctl&TIOCM_CD)?1:0,
					(mctl&TIOCM_RI)?1:0,
					(mctl&TIOCM_DSR)?1:0,
					(mctl&TIOCM_DTR)?1:0,
					(mctl&TIOCM_RTS)?1:0,
					mctl);
#endif
			printf("%s",in_line);
			fflush(stdout);
		}
	}
	printf("\n");

	close_serial();

#if defined(TARGET_LINUX)
	if (ttyios_stdin) {
		tcsetattr(0,TCSANOW,&ttyios_old);
	}
#endif

	return 0;
}
#endif

