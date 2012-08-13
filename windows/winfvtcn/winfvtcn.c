/* winfcon.c
 *
 * Fake console for Windows applications where a console is not available.
 * This version emulates DEC VT100 "ANSI" terminal.
 * (C) 2011-2012 Jonathan Campbell.
 * Hackipedia DOS library.
 *
 * This code is licensed under the LGPL.
 * <insert LGPL legal text here>
 *
 * This code allows the DOS/CPU test code to print to a console despite the
 * fact that Windows 3.0/3.1 and Win32s do not provide a console. For this
 * code to work, the program must include specific headers and #define a
 * macro. The header will then redefine various standard C functions to
 * redirect their use into this program. This code is not used for targets
 * that provide a console.
 */

/* TODO: When "doublewide" is active... what happens to the cursor commands <ESC>[C, <ESC>[D, etc.? */

/* TODO: New double wide/high mode codec while distracted, clean up later to catch leaks */

/* TODO: For arrow keys, function keys, etc. generate VT100 keyboard sequences */

/* TODO: Extended color codes described by KDE doc:
 * https://github.com/robertknight/konsole/blob/master/user-doc/README.moreColors */

#define WINFVCTN_ENABLE
#define WINFVCTN_SELF

#ifdef TARGET_WINDOWS
# include <windows.h>
# include <windows/apihelp.h>
# include <windows/w32imphk/compat.h>
# include <windows/winfvtcn/winfvtcn.h>
#else
# error what
#endif

#include <setjmp.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <ctype.h>
#include <stdio.h>
#include <conio.h>
#include <fcntl.h>
#include <dos.h>

#ifdef WIN_STDOUT_CONSOLE

#undef read
#undef write
#undef getch
#undef isatty

#define KBSIZE		256

static char		_winvt_WindowProcClass[128];

#pragma pack(push,1)
typedef struct _winvt_char_s {
	uint16_t	chr:8;		/* 0-7 */

	uint16_t	bold:1;		/* [1m */ /* 8-15 */
	uint16_t	dim:1;		/* [2m */
	uint16_t	underscore:1;	/* [4m */
	uint16_t	blink:1;	/* [5m */
	uint16_t	reverse:1;	/* [7m */
	uint16_t	hidden:1;	/* [8m */
	uint16_t	_unused1_:1;
	uint16_t	_unused2_:1;

	uint16_t	foreground_set:1;	/* 16-19 */
	uint16_t	foreground:3;

	uint16_t	background_set:1;	/* 20-23 */
	uint16_t	background:3;

	uint16_t	doublewide:1;		/* 24-31 */
	uint16_t	doublehigh:1;
	uint16_t	doublehigh_bottomhalf:1;
	uint16_t	_unused3_:5;
} _winvt_char_s;

typedef union _winvt_char {
	uint32_t		raw;
	_winvt_char_s		f;
} _winvt_char;
#pragma pack(pop)

#define MAX_ESC_ARG		10

enum {
	ESC_NONE=0,
	ESC_ALONE,
	ESC_POUND,
	ESC_LSQUARE
};

/* If we stick all these variables in the data segment and reference
 * them directly, then we'll work from a single instance, but run into
 * problems with who's data segment to use once we run in multiple
 * instances. The problem, is that when an application creates a
 * window of our class, the Window Proc is not guaranteed to be called
 * with our DS segment/selector. In fact, it often seems to be the
 * data segment of the first instance by which the window class was
 * created. And under Windows 3.0, unless you used __loadds and
 * MakeProcInstance, the DS segment could be any random segment
 * that happened to be there when you were called.
 *
 * Our Window Proc below absolves itself of these problems by storing
 * the pointer to the context in the Window data associated with the
 * window (GetWindowLong/SetWindowLong), then using only that context
 * pointer for maintaining itself.
 *
 * This DS segment limitation only affects the Window procedure and
 * any functions called by the Window procedure. Other parts, like
 * WinMain, do not have to worry about whether DS is correct and the
 * data segment will always be the current instance running.
 *
 * Note that the above limitations are only an issue for the Win16
 * world. The Win32 world is free from this hell and so we only
 * have to maintain one context structure. */
typedef struct _winvt_console_ctx {
	_winvt_char		console[80*25];
	char			_winvt_kb[KBSIZE];
	int			conHeight,conWidth;
	int			_winvt_kb_i,_winvt_kb_o;
	int			monoSpaceFontHeight;
#if TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386)
	short int		monoSpaceFontWidth;
#else
	int			monoSpaceFontWidth;
#endif
	HFONT			monoSpaceFont;
	HFONT			monoSpaceFontUnderline;
	int			pendingSigInt;
	int			userReqClose;
	int			allowClose;
	int			conX,conY;
	jmp_buf			exit_jmp;
	HWND			hwndMain;
	_winvt_char		cursor_state;
	unsigned char		escape_mode;
	unsigned char		escape_cmd;
	unsigned char		escape_argv[MAX_ESC_ARG];
	unsigned char		escape_argc;
	unsigned char		escape_arg_accum;
	unsigned char		escape_arg_digits;

	/* scroll region */
	unsigned char		scroll_top,scroll_bottom; /* inclusive */

	/* NTS: DEC reference sites never said anything about being able to save & restore in levels,
	 *      so we assume the terminal had only enough memory for one save */
	unsigned char		saved_cx,saved_cy;
	_winvt_char		saved_cattr;

	unsigned char		line_wrap:1;
	unsigned char		scroll_mode:1;		/* <ESC>[?4h (set) or <ESC>[?4l (reset) */
	unsigned char		myCaret:1;
	unsigned char		myCaretDoubleWide:1;
	unsigned char		_unused1_:4;

	/* compatible DC and bitmap used for double-wide and double-high modes */
	HBITMAP			tmpBMP,tmpBMPold;
	HDC			tmpDC;
};

#define ROWFLAG_DOUBLEWIDE		0x01
#define ROWFLAG_DOUBLEHIGH		0x02
#define ROWFLAG_DOUBLEHIGH_BOTTOMHALF	0x04

HINSTANCE				_winvt_hInstance;
static struct _winvt_console_ctx	_this_console;
static char				temprintf[1024];

#if TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386)
# define USER_GWW_CTX			0
# define USER_GWW_MAX			6
#elif TARGET_BITS == 16
# define USER_GWW_CTX			0
# define USER_GWW_MAX			4
#else
# define USER_GWW_MAX			0
#endif
#define USER_GCW_MAX			0

#if TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386)
/* TODO: Move to other library, perhaps a windows-specific one? */
void far *win386_help_MapAliasToFlat(DWORD farptr) {
	/* FIXME: This only works by converting a 16:16 pointer directly to 16:32.
	 *        It works perfectly fine in QEMU and DOSBox, but I seem to remember something
	 *        about the x86 architecture and possible ways you can screw up using 16-bit
	 *        data segments with 32-bit code. Are those rumors true? Am I going to someday
	 *        load up Windows 3.1/95 on an ancient PC and find out this code crashes
	 *        horribly or has random problems?
	 *
	 *        We need this alternate path for Windows NT/2000/XP/Vista/7 because NTVDM.EXE
	 *        grants Watcom386 a limited ~2GB limit for the flat data segment (usually
	 *        0x7B000000 or something like that) instead of the full 4GB limit the 3.x/9x/ME
	 *        kernels usually grant. This matters because without the full 4GB limit we can't
	 *        count on overflow/rollover to reach below our data segment base. Watcom386's
	 *        MapAliasToFlat() unfortunately assumes just that. If we were to blindly rely
	 *        on it, then we would work just fine under 3.x/9x/ME but crash under
	 *        NT/2000/XP/Vista/7 the minute we need to access below our data segment (such as,
	 *        when handling the WM_GETMINMAXINFO message the LPARAM far pointer usually
	 *        points somewhere into NTVDM.EXE's DOS memory area when we're usually located
	 *        at the 2MB mark or so) */
	return MK_FP(farptr>>16,farptr&0xFFFF);
}
#endif

int _winvt_init_tmp(struct _winvt_console_ctx FAR *c) {
	HDC hdc;

	if (c->tmpBMP == NULL) {
		hdc = GetDC(c->hwndMain);
		if (hdc == NULL) return -1;
		c->tmpBMP = CreateCompatibleBitmap(hdc,c->monoSpaceFontWidth*c->conWidth,c->monoSpaceFontHeight);
		ReleaseDC(c->hwndMain,hdc);
		if (c->tmpBMP == NULL) return -1;
	}
	if (c->tmpDC == NULL) {
		hdc = GetDC(c->hwndMain);
		if (hdc == NULL) return -1;
		c->tmpDC = CreateCompatibleDC(hdc);
		ReleaseDC(c->hwndMain,hdc);
		if (c->tmpDC == NULL) return -1;
		c->tmpBMPold = (HBITMAP)SelectObject(c->tmpDC,c->tmpBMP);
		SetBkMode(c->tmpDC,OPAQUE);
	}

	return 0;
}

void _winvt_free_tmp(struct _winvt_console_ctx FAR *c) {
	if (c->tmpDC) {
		SelectObject(c->tmpDC,c->tmpBMPold);
		DeleteDC(c->tmpDC);
		c->tmpDC = NULL;
	}
	if (c->tmpBMP) {
		DeleteObject(c->tmpBMP);
		c->tmpBMP = NULL;
	}
}

HWND _winvt_hwnd() {
	return _this_console.hwndMain;
}

int _winvt_kb_insert(struct _winvt_console_ctx FAR *ctx,char c) {
	if ((ctx->_winvt_kb_i+1)%KBSIZE == ctx->_winvt_kb_o) {
		MessageBeep(-1);
		return -1;
	}

	ctx->_winvt_kb[ctx->_winvt_kb_i] = c;
	if (++ctx->_winvt_kb_i >= KBSIZE) ctx->_winvt_kb_i = 0;
	return 0;
}

void _winvt_sigint() {
	void (*sig)(int x) = signal(SIGINT,SIG_DFL);
	if (sig != SIG_IGN && sig != SIG_DFL) sig(SIGINT);
	signal(SIGINT,sig);
	/* TODO: Win16 Windows 3.0 real mode compatibility:
	 *       Examine Watcom C runtime source code and figure out
	 *       how we can patch values in the setjmp buffer so that
	 *       longjmp() works even if Windows moved our code segment.
	 *       Note that the potential to move our code segment vs.
	 *       Watcom's setjmp/longjmp in real mode is the whole
	 *       reason the main routine uses LockCode()/UnlockCode()
	 *       in the first place. It works... but then Windows memory
	 *       management has less to work with if it needs more memory.
	 *
	 *       UPDATE: Examination of Watcom C code shows it stores the
	 *               segment register at offset +18 of the jmpbuf. */
	if (sig == SIG_DFL) longjmp(_this_console.exit_jmp,1);
}

void _winvt_sigint_post(struct _winvt_console_ctx FAR *ctx) {
	/* because doing a longjmp() out of a Window proc is very foolish */
	ctx->pendingSigInt = 1;
}

void _vt_erasescreen() {
	unsigned int i;

	_this_console.cursor_state.f.chr = ' ';
	for (i=0;i < (80*25);i++) _this_console.console[i] = _this_console.cursor_state;
}

void _vt_terminal_reset() { /* <ESC>c */
	_vt_erasescreen();
	/* clear the console */
	_this_console.scroll_top = 0;
	_this_console.scroll_bottom = _this_console.conHeight - 1;
	_this_console.saved_cattr.raw = 0;
	_this_console.saved_cattr.f.chr = ' ';
	_this_console.saved_cx = 0;
	_this_console.saved_cy = 0;
	_this_console.line_wrap = 1;
	_this_console.conX = 0;
	_this_console.conY = 0;
}

static DWORD _vt_palette16[24] = {
	/* normal */
	RGB(0  ,0  ,0  ),
	RGB(170,0  ,0  ),
	RGB(0  ,170,0  ),
	RGB(170,170,0  ),
	RGB(0  ,0  ,170),
	RGB(170,0  ,170),
	RGB(170,170,0  ),
	RGB(192,192,192),
	/* bold */
	RGB(0  ,0  ,0  ),
	RGB(255,0  ,0  ),
	RGB(0  ,255,0  ),
	RGB(255,255,0  ),
	RGB(0  ,0  ,255),
	RGB(255,0  ,255),
	RGB(255,255,0  ),
	RGB(255,255,255),
	/* dim */
	RGB(0  ,0  ,0  ),
	RGB(128,0  ,0  ),
	RGB(0  ,128,0  ),
	RGB(128,128,0  ),
	RGB(0  ,0  ,128),
	RGB(128,0  ,128),
	RGB(128,128,0  ),
	RGB(128,128,128)
};

static DWORD _vt_bgcolor(_winvt_char FAR *c) {
	if (c->f.background_set)
		return _vt_palette16[c->f.background/* + (c->f.bold ? 8 : (c->f.dim ? 16 : 0))*/];

	return RGB(0,0,0);
}

static DWORD _vt_fgcolor(_winvt_char FAR *c) {
	if (c->f.foreground_set)
		return _vt_palette16[c->f.foreground + (c->f.bold ? 8 : (c->f.dim ? 16 : 0))];
	else if (c->f.bold)
		return RGB(255,255,255);
	else if (c->f.dim)
		return RGB(128,128,128);

	return RGB(192,192,192);
}

void _winvt_free_caret(struct _winvt_console_ctx FAR *c) {
	if (c->myCaret) {
		HideCaret(c->hwndMain);
		DestroyCaret();
		c->myCaret = 0;
	}
}

void _winvt_setup_caret(struct _winvt_console_ctx FAR *c) {
	if (!c->myCaret) {
		c->myCaretDoubleWide = (c->console[(c->conY*c->conWidth)+c->conX].f.doublewide) ? 1 : 0;
		if (c->myCaretDoubleWide)
			CreateCaret(c->hwndMain,NULL,c->monoSpaceFontWidth * 2,c->monoSpaceFontHeight);
		else
			CreateCaret(c->hwndMain,NULL,c->monoSpaceFontWidth,c->monoSpaceFontHeight);

		SetCaretPos(c->conX * c->monoSpaceFontWidth,c->conY * c->monoSpaceFontHeight);
		ShowCaret(c->hwndMain);
		c->myCaret = 1;
	}
}

void _winvt_do_drawline(struct _winvt_console_ctx FAR *ctx,HDC hdc,unsigned int y,unsigned int x1,unsigned int x2) {
	_winvt_char FAR *srow;
	_winvt_char cur;
	unsigned int x,i;
	char tmp[80];

#define _this_console EVIL

	if (x1 != 0) {
		/* we need to step back if we land in the middle of a double-wide char */
		srow = ctx->console + (ctx->conWidth * y) + x1;
		if (srow->raw == 0) { /* our double-wide code writes one char + one NULL */
			srow--;
			if (srow->f.doublewide) {
				x1--;
			}
		}
	}

	for (x=x1;x < x2;) {
		srow = ctx->console + (ctx->conWidth * y) + x;
		cur = *srow;
		tmp[0] = cur.f.chr;
		i = 1;

		if (cur.f.doublewide) {
			srow += 2;
			while ((x+(i*2)) < x2 && i < sizeof(tmp) && (srow->raw & 0xFFFFFF00UL) == (cur.raw & 0xFFFFFF00UL)) {
				tmp[i++] = srow->f.chr;
				srow += 2;
			}

			if (_winvt_init_tmp(ctx) == 0) {
				HFONT of;

				of = (HFONT)SelectObject(ctx->tmpDC,cur.f.underscore ? ctx->monoSpaceFontUnderline : ctx->monoSpaceFont);
				SetBkColor(ctx->tmpDC,cur.f.reverse ? _vt_fgcolor(&cur) : _vt_bgcolor(&cur));
				SetTextColor(ctx->tmpDC,(cur.f.reverse || cur.f.hidden) ? _vt_bgcolor(&cur) : _vt_fgcolor(&cur));

				/* use the memory DC to draw, then stretchblt */
				/* FIXME: This actually causes quite a slowdown in rendering! Is there a faster way? Is there a 24-pt high Terminal font we can use? */
				TextOut(ctx->tmpDC,0,0,tmp,i);
				StretchBlt(
					/* dest */
					hdc,
					x * ctx->monoSpaceFontWidth,y * ctx->monoSpaceFontHeight,
					i * ctx->monoSpaceFontWidth * 2,ctx->monoSpaceFontHeight,
					/* source */
					ctx->tmpDC,
					0,cur.f.doublehigh_bottomhalf ? (ctx->monoSpaceFontHeight/2) : 0,
					i * ctx->monoSpaceFontWidth,
					cur.f.doublehigh ? (ctx->monoSpaceFontHeight/2) : ctx->monoSpaceFontHeight,
					/* rop */
					SRCCOPY);

				SelectObject(ctx->tmpDC,of);
			}

			x += i * 2;
		}
		else {
			srow++;
			while ((x+i) < x2 && i < sizeof(tmp) && (srow->raw & 0xFFFFFF00UL) == (cur.raw & 0xFFFFFF00UL)) {
				tmp[i++] = srow->f.chr;
				srow++;
			}

			SelectObject(hdc,cur.f.underscore ? ctx->monoSpaceFontUnderline : ctx->monoSpaceFont);
			SetBkColor(hdc,cur.f.reverse ? _vt_fgcolor(&cur) : _vt_bgcolor(&cur));
			SetTextColor(hdc,(cur.f.reverse || cur.f.hidden) ? _vt_bgcolor(&cur) : _vt_fgcolor(&cur));

			TextOut(hdc,x * ctx->monoSpaceFontWidth,y * ctx->monoSpaceFontHeight,tmp,i);
			x += i;
		}
	}

#undef _this_console
}

/* WARNING: To avoid crashiness in the Win16 environment:
 *    - Make sure the window proc is NOT using __loadds. Multiple-instance
 *      scenarios will crash if you do because the "DS" value will become
 *      invalid when the initial instance terminates.
 *    - Make sure you compile with Watcom's -zu and -zw compiler switches.
 *      Enabling them resolves a LOT of crashiness and generates the correct
 *      prologue and epilogue code to make things work. */
#if TARGET_BITS == 16 || (TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386))
FARPROC _winvt_WindowProc_MPI;
#endif
WindowProcType_NoLoadDS _export _winvt_WindowProc(HWND hwnd,UINT message,WPARAM wparam,LPARAM lparam) {
#if TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386)
# define _this_console EVIL
	struct _winvt_console_ctx FAR *_ctx_console;
	{
		unsigned short s = GetWindowWord(hwnd,USER_GWW_CTX);
		unsigned int o = GetWindowLong(hwnd,USER_GWW_CTX+2);
		_ctx_console = (void far *)MK_FP(s,o);
	}
	if (_ctx_console == NULL) return DefWindowProc(hwnd,message,wparam,lparam);
#elif TARGET_BITS == 16
# define _this_console EVIL
	struct _winvt_console_ctx FAR *_ctx_console =
		(struct _winvt_console_ctx FAR *)GetWindowLong(hwnd,USER_GWW_CTX);
	if (_ctx_console == NULL) return DefWindowProc(hwnd,message,wparam,lparam);
#else
# define _ctx_console (&_this_console)
#endif

	if (message == WM_GETMINMAXINFO) {
#if TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386) /* Watcom Win386 does NOT translate LPARAM for us */
		MINMAXINFO FAR *mm = (MINMAXINFO FAR*)win386_help_MapAliasToFlat(lparam);
		if (mm == NULL) return DefWindowProc(hwnd,message,wparam,lparam);
#else
		MINMAXINFO FAR *mm = (MINMAXINFO FAR*)(lparam);
#endif
		mm->ptMaxSize.x = (_ctx_console->monoSpaceFontWidth * _ctx_console->conWidth) +
			(2 * GetSystemMetrics(SM_CXFRAME));
		mm->ptMaxSize.y = (_ctx_console->monoSpaceFontHeight * _ctx_console->conHeight) +
			(2 * GetSystemMetrics(SM_CYFRAME)) + GetSystemMetrics(SM_CYCAPTION);
		mm->ptMinTrackSize.x = mm->ptMaxSize.x;
		mm->ptMinTrackSize.y = mm->ptMaxSize.y;
		mm->ptMaxTrackSize.x = mm->ptMaxSize.x;
		mm->ptMaxTrackSize.y = mm->ptMaxSize.y;
		return 0;
	}
	else if (message == WM_CLOSE) {
		if (_ctx_console->allowClose) DestroyWindow(hwnd);
		else _winvt_sigint_post(_ctx_console);
		_ctx_console->userReqClose = 1;
	}
	else if (message == WM_DESTROY) {
		_ctx_console->allowClose = 1;
		_ctx_console->userReqClose = 1;
		_winvt_free_caret(_ctx_console);
		PostQuitMessage(0);
		_ctx_console->hwndMain = NULL;
		return 0; /* OK */
	}
	else if (message == WM_SETCURSOR) {
		if (LOWORD(lparam) == HTCLIENT) {
			SetCursor(LoadCursor(NULL,IDC_ARROW));
			return 1;
		}
		else {
			return DefWindowProc(hwnd,message,wparam,lparam);
		}
	}
	else if (message == WM_ACTIVATE) {
		if (wparam)	_winvt_setup_caret(_ctx_console);
		else		_winvt_free_caret(_ctx_console);

		/* BUGFIX: Microsoft Windows 3.1 SDK says "return 0 if we processed the message".
		 *         Yet if we actually do, we get funny behavior. Like if I minimize another
		 *         application's window and then activate this app again, every keypress
		 *         causes Windows to send WM_SYSKEYDOWN/WM_SYSKEYUP. Somehow passing it
		 *         down to DefWindowProc() solves this. */
		return DefWindowProc(hwnd,message,wparam,lparam);
	}
	else if (message == WM_CHAR) {
		if (wparam > 0 && wparam <= 126) {
			if (wparam == 3) {
				/* CTRL+C */
				if (_ctx_console->allowClose) DestroyWindow(hwnd);
				else _winvt_sigint_post(_ctx_console);
			}
			else {
				_winvt_kb_insert(_ctx_console,(char)wparam);
			}
		}
	}
	else if (message == WM_ERASEBKGND) {
		RECT um;

		if (GetUpdateRect(hwnd,&um,FALSE)) {
			HBRUSH oldBrush,newBrush;
			HPEN oldPen,newPen;

			newPen = (HPEN)GetStockObject(NULL_PEN);
			newBrush = (HBRUSH)GetStockObject(BLACK_BRUSH);

			oldPen = SelectObject((HDC)wparam,newPen);
			oldBrush = SelectObject((HDC)wparam,newBrush);

			Rectangle((HDC)wparam,um.left,um.top,um.right+1,um.bottom+1);

			SelectObject((HDC)wparam,oldBrush);
			SelectObject((HDC)wparam,oldPen);
		}

		return 1; /* Important: Returning 1 signals to Windows that we processed the message. Windows 3.0 gets really screwed up if we don't! */
	}
	else if (message == WM_PAINT) {
		RECT um;

		if (GetUpdateRect(hwnd,&um,TRUE)) {
			PAINTSTRUCT ps;
			HFONT of;
			int y;

			if (BeginPaint(hwnd,&ps) != NULL) {
				SetBkMode(ps.hdc,OPAQUE);
				of = (HFONT)SelectObject(ps.hdc,_ctx_console->monoSpaceFont);
				for (y=0;y < _ctx_console->conHeight;y++) _winvt_do_drawline(_ctx_console,ps.hdc,y,0,_ctx_console->conWidth);
				SelectObject(ps.hdc,of);
				EndPaint(hwnd,&ps);
			}
		}

		return 0; /* Return 0 to signal we processed the message */
	}
	else {
		return DefWindowProc(hwnd,message,wparam,lparam);
	}

	return 0;
#undef _ctx_console
#undef _ctx_console_unlock

#if TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386)
# undef _this_console
#elif TARGET_BITS == 16
# undef _this_console
#endif
}

int _winvt_kbhit() {
	_winvt_pump();
	return _this_console._winvt_kb_i != _this_console._winvt_kb_o;
}

int _winvt_getch() {
	do {
		if (_winvt_kbhit()) {
			int c = (int)((unsigned char)_this_console._winvt_kb[_this_console._winvt_kb_o]);
			if (++_this_console._winvt_kb_o >= KBSIZE) _this_console._winvt_kb_o = 0;
			return c;
		}

		_winvt_pump_wait();
	} while (1);

	return -1;
}

int _winvt_kb_read(char *p,int sz) {
	int cnt=0;

	while (sz-- > 0)
		*p++ = _winvt_getch();

	return cnt;
}

int _winvt_kb_write(const char *p,int sz) {
	int cnt=0;

	while (sz-- > 0)
		_winvt_putc(*p++);

	return cnt;
}

int _winvt_read(int fd,void *buf,int sz) {
	if (fd == 0) return _winvt_kb_read((char*)buf,sz);
	else if (fd == 1 || fd == 2) return -1;
	else return read(fd,buf,sz);
}

int _winvt_write(int fd,const void *buf,int sz) {
	if (fd == 0) return -1;
	else if (fd == 1 || fd == 2) return _winvt_kb_write(buf,sz);
	else return write(fd,buf,sz);
}

int _winvt_isatty(int fd) {
	if (fd == 0 || fd == 1 || fd == 2) return 1; /* we're emulating one, so, yeah */
	return isatty(fd);
}

void _winvt_pump_wait() {
	MSG msg;

	if (GetMessage(&msg,NULL,0,0)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
		while (PeekMessage(&msg,NULL,0,0,PM_REMOVE)) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}

	if (_this_console.pendingSigInt) {
		_this_console.pendingSigInt = 0;
		_winvt_sigint();
	}
}

void _winvt_pump() {
	MSG msg;

#if TARGET_BITS == 16 || (TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386))
	/* Hack: Windows has this nice "GetTickCount()" function that has serious problems
	 *       maintaining a count if we don't process the message pump! Doing this
	 *       prevents portions of this code from getting stuck in infinite loops
	 *       waiting for the damn timer to advance. Note that this is a serious
	 *       problem that only plagues Windows 3.1 and earlier. Windows 95 doesn't
	 *       have this problem.  */
	PostMessage(_this_console.hwndMain,WM_USER,0,0);
#endif
	if (PeekMessage(&msg,NULL,0,0,PM_REMOVE)) {
		do {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		} while (PeekMessage(&msg,NULL,0,0,PM_REMOVE));
	}

	if (_this_console.pendingSigInt) {
		_this_console.pendingSigInt = 0;
		_winvt_sigint();
	}
}

void _winvt_update_cursor() {
	if (_this_console.myCaret) {
		if (_this_console.console[(_this_console.conY*_this_console.conWidth)+_this_console.conX].f.doublewide != _this_console.myCaretDoubleWide) {
			_winvt_free_caret(&_this_console);
			_winvt_setup_caret(&_this_console);
		}

		SetCaretPos(_this_console.conX * _this_console.monoSpaceFontWidth,
			_this_console.conY * _this_console.monoSpaceFontHeight);
	}
}

void _winvt_redraw_a_line_row(int y,int x1,int x2) {
	if (x1 >= x2) return;

	if (y >= 0 && y < _this_console.conHeight) {
		HDC hdc = GetDC(_this_console.hwndMain);
		HFONT of;

		SetBkMode(hdc,OPAQUE);
		of = (HFONT)SelectObject(hdc,_this_console.monoSpaceFont);
		if (_this_console.myCaret) HideCaret(_this_console.hwndMain);
		_winvt_do_drawline(&_this_console,hdc,y,x1,x2);
		if (_this_console.myCaret) ShowCaret(_this_console.hwndMain);
		SelectObject(hdc,of);
		ReleaseDC(_this_console.hwndMain,hdc);
	}
}

void _winvt_redraw_line_row_partial(int x1,int x2) {
	if (x1 >= x2) return;

	if (_this_console.conY >= 0 && _this_console.conY < _this_console.conHeight) {
		HDC hdc = GetDC(_this_console.hwndMain);
		HFONT of;

		SetBkMode(hdc,OPAQUE);
		of = (HFONT)SelectObject(hdc,_this_console.monoSpaceFont);
		if (_this_console.myCaret) HideCaret(_this_console.hwndMain);
		_winvt_do_drawline(&_this_console,hdc,_this_console.conY,x1,x2);
		if (_this_console.myCaret) ShowCaret(_this_console.hwndMain);
		SelectObject(hdc,of);
		ReleaseDC(_this_console.hwndMain,hdc);
	}
}

void _winvt_redraw_line_row() {
	_winvt_redraw_line_row_partial(0,_this_console.conWidth);
}

void _winvt_redraw_all() {
	unsigned int y;
	HFONT of;
	HDC hdc;
	
	hdc = GetDC(_this_console.hwndMain);
	if (_this_console.myCaret) HideCaret(_this_console.hwndMain);
	of = (HFONT)SelectObject(hdc,_this_console.monoSpaceFont);
	for (y=0;y < _this_console.conHeight;y++) _winvt_do_drawline(&_this_console,hdc,y,0,_this_console.conWidth);
	SelectObject(hdc,of);
	if (_this_console.myCaret) ShowCaret(_this_console.hwndMain);
	ReleaseDC(_this_console.hwndMain,hdc);
}

void clip_cursor() {
	if (_this_console.conY < _this_console.scroll_top) _this_console.conY = _this_console.scroll_top;
	else if (_this_console.conY > _this_console.scroll_bottom) _this_console.conY = _this_console.scroll_bottom;

	if (_this_console.conX < 0) _this_console.conX = 0;
	else if (_this_console.conX >= _this_console.conWidth) _this_console.conX = _this_console.conWidth - 1;
}

void _winvt_scrolldown() {
	unsigned int i;
	HDC hdc;

	assert(_this_console.scroll_bottom >= (_this_console.scroll_top+1));

	hdc = GetDC(_this_console.hwndMain);
	if (_this_console.myCaret) HideCaret(_this_console.hwndMain);
	BitBlt(hdc,
		0,(_this_console.scroll_top + 1) * _this_console.monoSpaceFontHeight,
		_this_console.conWidth * _this_console.monoSpaceFontWidth,
		(_this_console.scroll_bottom - _this_console.scroll_top) * _this_console.monoSpaceFontHeight,
		hdc,0,_this_console.scroll_top * _this_console.monoSpaceFontHeight,SRCCOPY);
	if (_this_console.myCaret) ShowCaret(_this_console.hwndMain);
	ReleaseDC(_this_console.hwndMain,hdc);

	memmove(_this_console.console+(_this_console.conWidth*(_this_console.scroll_top+1)),
		_this_console.console+(_this_console.conWidth*_this_console.scroll_top),
		(_this_console.scroll_bottom-_this_console.scroll_top)*_this_console.conWidth*sizeof(_winvt_char));

	_this_console.cursor_state.f.chr = ' ';
	for (i=0;i < _this_console.conWidth;i++)
		_this_console.console[(_this_console.scroll_top*_this_console.conWidth)+i] =
			_this_console.cursor_state;
}

void _winvt_scrollup() {
	unsigned int i;
	HDC hdc;

	assert(_this_console.scroll_bottom >= (_this_console.scroll_top+1));

	hdc = GetDC(_this_console.hwndMain);
	if (_this_console.myCaret) HideCaret(_this_console.hwndMain);
	BitBlt(hdc,
		0,_this_console.scroll_top * _this_console.monoSpaceFontHeight,
		_this_console.conWidth * _this_console.monoSpaceFontWidth,
		(_this_console.scroll_bottom - _this_console.scroll_top) * _this_console.monoSpaceFontHeight,
		hdc,0,(_this_console.scroll_top + 1) * _this_console.monoSpaceFontHeight,SRCCOPY);
	if (_this_console.myCaret) ShowCaret(_this_console.hwndMain);
	ReleaseDC(_this_console.hwndMain,hdc);

	memmove(_this_console.console+(_this_console.conWidth*_this_console.scroll_top),
		_this_console.console+(_this_console.conWidth*(_this_console.scroll_top+1)),
		(_this_console.scroll_bottom-_this_console.scroll_top)*_this_console.conWidth*sizeof(_winvt_char));

	_this_console.cursor_state.f.chr = ' ';
	for (i=0;i < _this_console.conWidth;i++)
		_this_console.console[(_this_console.scroll_bottom*_this_console.conWidth)+i] =
			_this_console.cursor_state;
}

void _winvt_newline() {
	_this_console.conX = 0;
	_this_console.cursor_state.f.doublewide = 0;
	_this_console.cursor_state.f.doublehigh = 0;
	_this_console.cursor_state.f.doublehigh_bottomhalf = 0;
	if (_this_console.conY >= _this_console.scroll_bottom) {
		_this_console.conY = _this_console.scroll_bottom;
		_winvt_redraw_line_row();
		_winvt_scrollup();
		_winvt_redraw_line_row();
		_winvt_update_cursor();
		_gdivt_pause();
	}
	else {
		_winvt_redraw_line_row();
		_this_console.conY++;
	}
}

void _winvt_on_esc_ls_m() { /* <ESC>[m attribute */
	unsigned int i;
	unsigned char c;

	if (_this_console.escape_argc == 0) {
		_this_console.escape_argv[0] = 0;
		_this_console.escape_argc = 1;
	}

	for (i=0;i < _this_console.escape_argc;i++) {
		c = _this_console.escape_argv[i];

		switch (c) {
			case 0: /* reset attr */
				_this_console.cursor_state.raw = 0;
				break;
			case 1:
				_this_console.cursor_state.f.bold = 1;
				break;
			case 2:
				_this_console.cursor_state.f.dim = 1;
				break;
			case 4:
				_this_console.cursor_state.f.underscore = 1;
				break;
			case 5:
				_this_console.cursor_state.f.blink = 1;
				break;
			case 7:
				_this_console.cursor_state.f.reverse = 1;
				break;
			case 8:
				_this_console.cursor_state.f.hidden = 1;
				break;
			case 30: case 31: case 32: case 33: case 34: case 35: case 36: case 37:
				_this_console.cursor_state.f.foreground_set = 1;
				_this_console.cursor_state.f.foreground = c-30;
				break;
			case 40: case 41: case 42: case 43: case 44: case 45: case 46: case 47:
				_this_console.cursor_state.f.background_set = 1;
				_this_console.cursor_state.f.background = c-40;
				break;
		};
	}
}

void _winvt_on_esc_ls_hl(unsigned char set) {
	unsigned char what = 0;

	if (_this_console.escape_argc > 0)
		what = _this_console.escape_argv[0];

	switch (what) {
		case 7:	/* enable/disable line wrap */
			_this_console.line_wrap = set;
			break;
	};
}

void _winvt_on_esc_ls_H() {
	while (_this_console.escape_argc < 2)
		_this_console.escape_argv[_this_console.escape_argc++] = 1;

	_this_console.conY = _this_console.escape_argv[0] - 1;
	_this_console.conX = _this_console.escape_argv[1] - 1;
	_winvt_redraw_line_row();
	clip_cursor();
}

void _winvt_on_esc_ls_A() {
	if (_this_console.escape_argc < 1)
		_this_console.escape_argv[_this_console.escape_argc++] = 1;

	_this_console.conY -= _this_console.escape_argv[0];
	_winvt_redraw_line_row();
	clip_cursor();
}

void _winvt_on_esc_ls_B() {
	if (_this_console.escape_argc < 1)
		_this_console.escape_argv[_this_console.escape_argc++] = 1;

	_this_console.conY += _this_console.escape_argv[0];
	_winvt_redraw_line_row();
	clip_cursor();
}

void _winvt_on_esc_ls_C() {
	if (_this_console.escape_argc < 1)
		_this_console.escape_argv[_this_console.escape_argc++] = 1;

	_this_console.conX += _this_console.escape_argv[0];
	_winvt_redraw_line_row();
	clip_cursor();
}

void _winvt_on_esc_ls_D() {
	if (_this_console.escape_argc < 1)
		_this_console.escape_argv[_this_console.escape_argc++] = 1;

	_this_console.conX -= _this_console.escape_argv[0];
	_winvt_redraw_line_row();
	clip_cursor();
}

void _winvt_erase_this_line() {
	unsigned int i,m;

	_this_console.cursor_state.f.chr = ' ';
	m = (_this_console.conY+1) * _this_console.conWidth;
	i = _this_console.conY * _this_console.conWidth;
	while (i < m) _this_console.console[i++] = _this_console.cursor_state;
	_winvt_redraw_all();
}

void _winvt_on_esc_ls_K() {
	unsigned int i,m;

	if (_this_console.escape_argc < 1)
		_this_console.escape_argv[_this_console.escape_argc++] = 0;

	switch (_this_console.escape_argv[0]) {
		case 0:	_this_console.cursor_state.f.chr = ' ';
			m = (_this_console.conY+1) * _this_console.conWidth;
			i = (_this_console.conY * _this_console.conWidth) + _this_console.conX;
			while (i < m) _this_console.console[i++] = _this_console.cursor_state;
			_winvt_redraw_all();
			break;
		case 1:	_this_console.cursor_state.f.chr = ' ';
			m = _this_console.conY * _this_console.conWidth;
			i = (_this_console.conY * _this_console.conWidth) + _this_console.conX;
			do { _this_console.console[i] = _this_console.cursor_state;
			} while ((i--) != m);
			_winvt_redraw_all();
			break;
		case 2:	_this_console.cursor_state.f.chr = ' ';
			m = (_this_console.conY+1) * _this_console.conWidth;
			i = _this_console.conY * _this_console.conWidth;
			while (i < m) _this_console.console[i++] = _this_console.cursor_state;
			_winvt_redraw_all();
			break;
	};
}

void _winvt_on_esc_ls_J() {
	unsigned int i,m;

	if (_this_console.escape_argc < 1)
		_this_console.escape_argv[_this_console.escape_argc++] = 0;

	i = (_this_console.conY * _this_console.conWidth) + _this_console.conX;
	switch (_this_console.escape_argv[0]) {
		case 0:	m = _this_console.conWidth * _this_console.conHeight;
			_this_console.cursor_state.f.chr = ' ';
			while (i < m) _this_console.console[i++] = _this_console.cursor_state;
			_winvt_redraw_all();
			break;
		case 1:	_this_console.cursor_state.f.chr = ' ';
			do { _this_console.console[i] = _this_console.cursor_state;
			} while ((i--) != 0);
			_winvt_redraw_all();
			break;
		case 2:
			_this_console.conX = 0;
			_this_console.conY = 0;
			_vt_erasescreen();
			_winvt_redraw_all();
			break;
	};
}

void _winvt_on_esc_ls_s() { /* save cursor */
	_this_console.saved_cx = _this_console.conX;
	_this_console.saved_cy = _this_console.conY;
}

void _winvt_on_esc_ls_u() { /* restore cursor */
	_this_console.conX = _this_console.saved_cx;
	_this_console.conY = _this_console.saved_cy;
	_winvt_redraw_all();
	_winvt_update_cursor();
}

void _winvt_on_esc_7() { /* save cursor & attrs */
	_this_console.saved_cattr = _this_console.cursor_state;
	_this_console.saved_cx = _this_console.conX;
	_this_console.saved_cy = _this_console.conY;
}

void _winvt_on_esc_8() { /* restore cursor & attr */
	_this_console.cursor_state = _this_console.saved_cattr;
	_this_console.conX = _this_console.saved_cx;
	_this_console.conY = _this_console.saved_cy;
	_winvt_redraw_all();
	_winvt_update_cursor();
}

void _winvt_on_esc_ls_l_c() { /* query device code */
	const char *s = "\x1B[?62;9;c"; /* <- FIXME: We're mimicking what Linux returns */
	while (*s) _winvt_kb_insert(&_this_console,*s++);
}

void _winvt_on_esc_ls_l_n() { /* query device status/cursor/etc. */
	const char *s;
	char tmp[48];

	if (_this_console.escape_argc < 1)
		_this_console.escape_argv[_this_console.escape_argc++] = 0;

	switch (_this_console.escape_argv[0]) {
		case 5: /* query device status */
			s = "\x1B[0n"; /* <- NTS: Device OK */
			while (*s) _winvt_kb_insert(&_this_console,*s++);
			break;
		case 6:	/* query cursor position */
			sprintf(tmp,"\x1B[%d;%dR",_this_console.conY+1,_this_console.conX+1);
			s = (const char*)tmp;
			while (*s) _winvt_kb_insert(&_this_console,*s++);
			break;
	};
}

void _winvt_on_esc_ls_r() {
	if (_this_console.escape_argc < 1)
		_this_console.escape_argv[_this_console.escape_argc++] = 1;
	if (_this_console.escape_argc < 2)
		_this_console.escape_argv[_this_console.escape_argc++] = _this_console.conHeight - 1;
	if (_this_console.escape_argv[1] <= _this_console.escape_argv[0])
		_this_console.escape_argv[1] = _this_console.escape_argv[0]+1;
	if (_this_console.escape_argv[0] == 0)
		_this_console.escape_argv[0] = 1;
	if (_this_console.escape_argv[1] >= _this_console.conHeight)
		_this_console.escape_argv[1] = _this_console.conHeight - 1;

	_winvt_redraw_line_row();
	_this_console.scroll_top = _this_console.escape_argv[0];
	_this_console.scroll_bottom = _this_console.escape_argv[1];
	clip_cursor();
}

void _winvt_on_esc_D() { /* scroll down one line (FIXME: Does it move the cursor too?) */
	_winvt_scrolldown();
	_winvt_redraw_a_line_row(_this_console.scroll_top,0,_this_console.conWidth);
	_winvt_update_cursor();
}

void _winvt_on_esc_M() { /* scroll up one line (FIXME: Does it move the cursor too?) */
	_winvt_scrollup();
	_winvt_redraw_a_line_row(_this_console.scroll_bottom,0,_this_console.conWidth);
	_winvt_update_cursor();
}

void _winvt_on_esc_lsquare(char c) {
	if (c == 'm')
		_winvt_on_esc_ls_m();
	else if (c == 'h')
		_winvt_on_esc_ls_hl(1);
	else if (c == 'l')
		_winvt_on_esc_ls_hl(0);
	else if (c == 'H' || c == 'f')
		_winvt_on_esc_ls_H();
	else if (c == 'A')
		_winvt_on_esc_ls_A();
	else if (c == 'B')
		_winvt_on_esc_ls_B();
	else if (c == 'C')
		_winvt_on_esc_ls_C();
	else if (c == 'D')
		_winvt_on_esc_ls_D();
	else if (c == 'K')
		_winvt_on_esc_ls_K();
	else if (c == 'J')
		_winvt_on_esc_ls_J();
	else if (c == 's')
		_winvt_on_esc_ls_s();
	else if (c == 'u')
		_winvt_on_esc_ls_u();
	else if (c == 'r')
		_winvt_on_esc_ls_r();
	else if (c == 'c')
		_winvt_on_esc_ls_l_c();
	else if (c == 'n')
		_winvt_on_esc_ls_l_n();
}

/* write to the console. does NOT redraw the screen unless we get a newline or we need to scroll up */
int _winvt_putc(char c) {
	if (c == 10) {
		_winvt_newline();
	}
	else if (c == 8) {
		if (_this_console.conX > 0) {
			_this_console.conX -= _this_console.cursor_state.f.doublewide ? 2 : 1;
			if (_this_console.conX < 0) _this_console.conX = 0;
			_winvt_update_cursor();
		}
	}
	else if (c == 13) {
		_this_console.conX = 0;
		_winvt_redraw_line_row();
		_winvt_update_cursor();
		_gdivt_pause();
	}
	else if (c == 27) {
		_this_console.escape_mode = ESC_ALONE;
	}
	else if (_this_console.escape_mode == ESC_ALONE) {
		if (c == '[') {
			_this_console.escape_mode = ESC_LSQUARE;
			_this_console.escape_arg_accum = 0;
			_this_console.escape_arg_digits = 0;
			_this_console.escape_argc = 0;
		}
		else if (c == '#') {
			_this_console.escape_mode = ESC_POUND;
		}
		else {
			_this_console.escape_mode = 0;

			if (c == 'c') {
				_vt_terminal_reset();
				_winvt_redraw_all();
			}
			else if (c == '7')
				_winvt_on_esc_7();
			else if (c == '8')
				_winvt_on_esc_8();
			else if (c == 'D')
				_winvt_on_esc_D();
			else if (c == 'M')
				_winvt_on_esc_M();
		}
	}
	else if (_this_console.escape_mode == ESC_POUND) { /* <ESC> # <N> */
		_winvt_free_caret(&_this_console);

		if (c == '3') { /* change the current line to double high double wide top half */
			_this_console.cursor_state.f.doublewide = 1;
			_this_console.cursor_state.f.doublehigh = 1;
			_this_console.cursor_state.f.doublehigh_bottomhalf = 0;
			_this_console.conX = 0;
		}
		else if (c == '4') { /* change the current line to double high double wide bottom half */
			_this_console.cursor_state.f.doublewide = 1;
			_this_console.cursor_state.f.doublehigh = 1;
			_this_console.cursor_state.f.doublehigh_bottomhalf = 1;
			_this_console.conX = 0;
		}
		else if (c == '5') { /* change the current line to single width/height */
			_this_console.cursor_state.f.doublewide = 0;
			_this_console.cursor_state.f.doublehigh = 0;
			_this_console.cursor_state.f.doublehigh_bottomhalf = 0;
			_this_console.conX = 0;
		}
		else if (c == '6') { /* change the current line to single high double wide */
			_this_console.cursor_state.f.doublewide = 1;
			_this_console.cursor_state.f.doublehigh = 0;
			_this_console.cursor_state.f.doublehigh_bottomhalf = 0;
			_this_console.conX = 0;
		}

		_winvt_setup_caret(&_this_console);
		_this_console.escape_mode = ESC_NONE;
	}
	else if (_this_console.escape_mode == ESC_LSQUARE) {
		if (isdigit(c)) {
			_this_console.escape_arg_accum = (_this_console.escape_arg_accum * 10) + (c - '0');
			_this_console.escape_arg_digits++;
		}
		else {
			if (c == ';' || _this_console.escape_arg_digits != 0) {
				if (_this_console.escape_argc < MAX_ESC_ARG) {
					_this_console.escape_argv[_this_console.escape_argc++] =
						_this_console.escape_arg_accum;
				}
			}

			_this_console.escape_arg_accum = 0;
			_this_console.escape_arg_digits = 0;

			if (c == ';') {
				/* more args to come, keep scanning */
			}
			else if (c == 'R') {
				char tmp[32],*s = tmp;

				/* <ESC>[..R is supposed to be query cursor response. print it on the console if we get it back.
				 * NTS we cannot recursively call _winvt_printf() because this function is called by _winvt_printf() */
				_this_console.escape_mode = ESC_NONE;
				sprintf(tmp,"^[[%d;%dR",_this_console.escape_argv[0],_this_console.escape_argv[1]);
				while (*s) _winvt_putc(*s++);
			}
			else {
				/* handle the vtcode */
				_winvt_on_esc_lsquare(c);
				_this_console.escape_mode = ESC_NONE;
			}
		}
	}
	else {
		int step = _this_console.cursor_state.f.doublewide ? 2 : 1;

		if (_this_console.conX < _this_console.conWidth) {
			_this_console.cursor_state.f.chr = (unsigned char)c;
			_this_console.console[(_this_console.conY*_this_console.conWidth)+_this_console.conX] =
				_this_console.cursor_state;

			if (step == 2) {
				if ((_this_console.conX+1) < _this_console.conWidth) {
					_this_console.console[(_this_console.conY*_this_console.conWidth)+_this_console.conX+1].raw = 0;
				}
			}
		}
		if (_this_console.line_wrap) {
			if ((_this_console.conX += step) >= _this_console.conWidth)
				_winvt_newline();
		}
		else {
			if ((_this_console.conX+step) < _this_console.conWidth)
				_this_console.conX += step;
			else
				return 1;
		}
	}

	return 0;
}

void _winvt_fflush(FILE *f) {
	if (f == stdout) {
		_winvt_redraw_all(); /* TODO: Implement a more intelligent refresh mechanism! */
		_winvt_update_cursor();
	}
	else {
		fflush(f);
	}
}

size_t _winvt_printf(const char *fmt,...) {
	int fX = _this_console.conX,all=0;
	va_list va;
	char *t;

	va_start(va,fmt);
	vsnprintf(temprintf,sizeof(temprintf)-1,fmt,va);
	va_end(va);

	t = temprintf;
	if (*t != 0) {
		while (*t != 0) {
			if (*t == 13 || *t == 10) fX = 0;
			if (_winvt_putc(*t++)) { fX = 0; all = 1; }
		}
		if (fX <= _this_console.conX) {
			_winvt_redraw_line_row_partial(fX,all ? _this_console.conWidth : _this_console.conX);
		}
		_winvt_update_cursor();
	}

	_winvt_pump();
	return 0;
}

/* HACK: I don't know if real systems do this or QEMU is doing something wrong, but apparently if a program
 *       rapidly prints a lot of text under Windows 3.1 (like the RDTSC test program) it can cause the GDI
 *       to become 100% focused on TextOut() to the point not even the cursor updates when you move it, and
 *       keyboard events to become severely stalled. Our solution to this problem is to see if we're running
 *       under Windows 3.1 or earlier, and if so, purposely slow down our output with a software delay */
void _gdivt_pause() {
	/* TODO: delay routines appropriate for Windows 3.0, Windows 3.1, Windows NT, etc. */
}

int WINMAINPROC _winvt_main_vtcon_entry(HINSTANCE hInstance,HINSTANCE hPrevInstance,LPSTR lpCmdLine,int nCmdShow,int (_cdecl *_main_f)(int argc,char**,char**)) {
	WNDCLASS wnd;
	MSG msg;

	_winvt_hInstance = hInstance;
	snprintf(_winvt_WindowProcClass,sizeof(_winvt_WindowProcClass),"_HW_DOS_WINFVCTN_%lX",(DWORD)hInstance);
#if TARGET_BITS == 16 || (TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386))
	_winvt_WindowProc_MPI = MakeProcInstance((FARPROC)_winvt_WindowProc,hInstance);
#endif

	memset(&_this_console,0,sizeof(_this_console));
	_this_console.conHeight = 25;
	_this_console.conWidth = 80;
	_this_console._winvt_kb_i = _this_console._winvt_kb_o = 0;
	_vt_terminal_reset();

#if TARGET_BITS == 16
	/* Windows real mode: Lock our data segment. Real-mode builds typically set CODE and DATA segments
	 * to moveable because Windows 1.x and 2.x apparently demand it. */
	if (IsWindowsRealMode()) {
		LockData(); /* Lock data in place, so our FAR PTR remains valid */
		LockCode(); /* Lock code in place, so that Watcom setjmp/longjmp works properly */
	}
#endif

	/* we want each instance to have it's own WNDCLASS, even though Windows (Win16) considers them all instances
	 * coming from the same HMODULE. In Win32, there is no such thing as a "previous instance" anyway */
	wnd.style = CS_HREDRAW|CS_VREDRAW;
#if TARGET_BITS == 16 || (TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386))
	wnd.lpfnWndProc = (WNDPROC)_winvt_WindowProc_MPI;
#else
	wnd.lpfnWndProc = _winvt_WindowProc;
#endif
	wnd.cbClsExtra = USER_GCW_MAX;
	wnd.cbWndExtra = USER_GWW_MAX;
	wnd.hInstance = hInstance;
	wnd.hIcon = NULL;
	wnd.hCursor = NULL;
	wnd.hbrBackground = NULL;
	wnd.lpszMenuName = NULL;
	wnd.lpszClassName = _winvt_WindowProcClass;

	if (!RegisterClass(&wnd)) {
		MessageBox(NULL,"Unable to register Window class","Oops!",MB_OK);
		return 1;
	}

/* Use the full path of our EXE image by default */
	{
		char title[256];

		if (!GetModuleFileName(hInstance,title,sizeof(title)-1))
			strcpy(title,"<unknown>");

		_this_console.hwndMain = CreateWindow(_winvt_WindowProcClass,title,
			WS_OVERLAPPEDWINDOW,
			CW_USEDEFAULT,CW_USEDEFAULT,
			100,40,
			NULL,NULL,
			hInstance,NULL);
	}

	if (!_this_console.hwndMain) {
		MessageBox(NULL,"Unable to create window","Oops!",MB_OK);
		return 1;
	}

#if TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386)
	/* our Win386 hack needs the address of our console context */
	SetWindowWord(_this_console.hwndMain,USER_GWW_CTX,(WORD)FP_SEG(&_this_console));
	SetWindowLong(_this_console.hwndMain,USER_GWW_CTX+2,(DWORD)FP_OFF(&_this_console));
#elif TARGET_BITS == 16
	/* TODO: Windows 3.0 real mode: Obviously, if real-mode Windows demands indirection
	 *       because segments can move around, then this approach is not appropriate.
	 *       What else can we try other than locking our data segment into memory?
	 *       
	 *       Try: If compiled for Win16 real or bimodal mode, then _this_console is a
	 *            pointer to a global memory object allocated using GlobalAlloc(),
	 *            and USER_GWW_CTX is a WORD-sized slot to hold the GlobalAlloc()
	 *            handle. The window proc retrieves the handle, and uses GlobalLock().
	 *            Such a scheme would be far more compatible with Windows 3.0 real mode
	 *            than eating up what precious low memory is available locking our code
	 *            and data in place. */
	SetWindowLong(_this_console.hwndMain,USER_GWW_CTX,(DWORD)(&_this_console));
#endif

	/* Create the monospace font we use for terminal display */
	{
		_this_console.monoSpaceFont = CreateFont(-12,0,0,0,FW_NORMAL,FALSE,FALSE,FALSE,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,FIXED_PITCH | FF_DONTCARE,"Terminal");
		if (!_this_console.monoSpaceFont) {
			MessageBox(NULL,"Unable to create Font","Oops!",MB_OK);
			return 1;
		}

		{
			HWND hwnd = GetDesktopWindow();
			HDC hdc = GetDC(hwnd);
			_this_console.monoSpaceFontHeight = 12;
			if (!GetCharWidth(hdc,'A','A',&_this_console.monoSpaceFontWidth)) _this_console.monoSpaceFontWidth = 9;
			ReleaseDC(hwnd,hdc);
		}
	}

	{
		_this_console.monoSpaceFontUnderline = CreateFont(-12,0,0,0,FW_NORMAL,FALSE,TRUE,FALSE,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,FIXED_PITCH | FF_DONTCARE,"Terminal");
		if (!_this_console.monoSpaceFontUnderline) {
			MessageBox(NULL,"Unable to create Font (underline)","Oops!",MB_OK);
			return 1;
		}
	}

	ShowWindow(_this_console.hwndMain,nCmdShow);
	UpdateWindow(_this_console.hwndMain);
	SetWindowPos(_this_console.hwndMain,HWND_TOP,0,0,
		(_this_console.monoSpaceFontWidth * _this_console.conWidth) +
			(2 * GetSystemMetrics(SM_CXFRAME)),
		(_this_console.monoSpaceFontHeight * _this_console.conHeight) +
			(2 * GetSystemMetrics(SM_CYFRAME)) + GetSystemMetrics(SM_CYCAPTION),
		SWP_NOMOVE);

	if (setjmp(_this_console.exit_jmp) == 0)
		_main_f(0,NULL,NULL); /* <- FIXME: We need to take the command line and generate argv[]. Also generate envp[] */

	if (!_this_console.userReqClose) {
		_winvt_printf("\n<program terminated>");
		_this_console.allowClose = 1;
		while (GetMessage(&msg,NULL,0,0)) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}
	else {
		if (IsWindow(_this_console.hwndMain)) {
			DestroyWindow(_this_console.hwndMain);
			while (GetMessage(&msg,NULL,0,0)) {
				TranslateMessage(&msg);
				DispatchMessage(&msg);
			}
		}
	}

	_winvt_free_tmp(&_this_console);

	DeleteObject(_this_console.monoSpaceFont);
	_this_console.monoSpaceFont = NULL;

	DeleteObject(_this_console.monoSpaceFontUnderline);
	_this_console.monoSpaceFontUnderline = NULL;

#if TARGET_BITS == 16
	/* Real mode: undo our work above */
	if (IsWindowsRealMode()) {
		UnlockCode();
		UnlockData();
	}
#endif

	return 0;
}

void _winvt_endloop_user_echo() {
	int c;

	do {
		c = _winvt_getch();
		if (c == 27 && !_winvt_kbhit()) break;
		if (c == 13 || c == 10) _winvt_printf("\n");
		else if (c == 22) { /* CTRL-V */
			c = _winvt_getch();
			_winvt_printf("%c",c);
		}
		else _winvt_printf("%c",c);
	} while (1);
}
#endif

