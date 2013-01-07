#ifndef __DOSLIB2_WINDOWS_APIHELP_H
#define __DOSLIB2_WINDOWS_APIHELP_H

#if defined(TARGET_WINDOWS)
# include <windows.h>
#endif

/* Problem: Watcom C runtime will call our WinMain according to memory model.
 *          If we blindly use the "WINAPI" or "STDCALL" types the function
 *          will be defined as FAR regardless, and therefore the runtime will
 *          call it wrong and crash on shutdown for small/compact memory model
 *          builds */
# if defined(__SMALL__) || defined(__COMPACT__) || defined(TARGET_WINDOWS_WIN386) || defined(__386__)/*Watcom's internal way of saying "flat memory"*/
#  define WINMAINPROC __pascal near
# else
#  define WINMAINPROC __pascal far
# endif

#if defined(TARGET_WINDOWS)
# if TARGET_BITS == 16 || (TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386))
/* Win16 */
#  define WindowProcType		LRESULT PASCAL FAR __loadds
#  define WindowProcType_NoLoadDS	LRESULT PASCAL FAR
# elif defined(WIN386)
#  define WindowProcType		LRESULT PASCAL
#  define WindowProcType_NoLoadDS	LRESULT PASCAL
# else
/* Win32s/Win32/WinNT */
#  define WindowProcType		LRESULT WINAPI
#  define WindowProcType_NoLoadDS	LRESULT WINAPI
# endif

# if TARGET_BITS == 16 || (TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386))
/* Win16 */
#  define DialogProcType		BOOL PASCAL FAR __loadds 
#  define DialogProcType_NoLoadDS	BOOL PASCAL FAR
# elif defined(WIN386)
#  define DialogProcType		BOOL PASCAL
#  define DialogProcType_NoLoadDS	BOOL PASCAL
# else
/* Win32s/Win32/WinNT */
#  define DialogProcType		BOOL WINAPI
#  define DialogProcType_NoLoadDS	BOOL WINAPI
# endif

# if TARGET_BITS == 16 || (TARGET_BITS == 32 && defined(TARGET_WINDOWS_WIN386))
/* Win16 */
#  define DllEntryType			PASCAL FAR __loadds
#  define DllEntryType_NoLoadDS		PASCAL FAR
# elif defined(WIN386)
#  define DllEntryType			PASCAL
#  define DllEntryType_NoLoadDS		PASCAL
# else
/* Win32s/Win32/WinNT */
#  define DllEntryType			__stdcall
#  define DllEntryType_NoLoadDS		__stdcall
# endif
#endif

#if TARGET_BITS == 16
/* Microsoft provides a LockData()/UnlockData() macro in their SDK.
 * We take it one step further to provide functions to lock/unlock our code segment.
 * Functions are inline. If excessively used the inline function will bloat your code
 * segment. Use sparingly, only if necessary. You should only need this if at all
 * for code stability from within Windows real mode.
 *
 * TODO: This will obvously not work if the code segment is >= 64KB and the code
 *       calling the function is not within the first 64KB. Figure out how to get
 *       the base segment value of the entire code segment so this can do it's
 *       job properly. */
static inline WORD LockCode() {
	unsigned int s = 0;
	__asm {
		mov	ax,cs
		mov	s,ax
	}
	return LockSegment(s);
}

static inline void UnlockCode() {
	unsigned int s = 0;
	__asm {
		mov	ax,cs
		mov	s,ax
	}
	UnlockSegment(s);
}
#endif

#if defined(TARGET_WINDOWS_WIN16)
# if defined(TARGET_REALMODE) && TARGET_WINDOWS_VERSION < 20
	/* Windows 1.x builds target real mode because that's all Windows 1.x supports.
	 * it's also highly possible that Windows 1.x lacks GetWinFlags() */
#  define IsWindowsRealMode() (1)
# elif defined(TARGET_REALMODE) || defined(TARGET_AUTOMODE)
static inline unsigned int IsWindowsRealMode() {
	/* real or bi-modal modes: we *can* be run under Windows Real Mode */
	return (GetWinFlags() & (WF_ENHANCED|WF_STANDARD)) == 0;
}
# elif defined(TARGET_PROTMODE)
   /* Assume protected mode because Win NE images can be marked as protected-mode only */
#  define IsWindowsRealMode() (0)
# else
#  define IsWindowsRealMode() (0)
# endif
#else /* !TARGET_WINDOWS_WIN16 */
# define IsWindowsRealMode() (0)
#endif

#endif /* __DOSLIB2_WINDOWS_APIHELP_H */

