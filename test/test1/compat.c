#if TARGET_BITS == 32 && defined(TARGET_WINDOWS) && defined(TARGET_WINDOWS_WIN32s) && !defined(W32IMPHK_INTERNAL)
# include <windows.h>
# include "compat.h"

/* Alrighty, Open Watcom will generate win32s executables, but due to shortsighted
 * coding within their C runtime the resulting binary would not actually run under
 * Win32s, and here's why: they use Wide char functions in KERNEL32.DLL. So to make
 * the EXE work in Win32s, we supply the functions ourself so the linker will link
 * to ours instead of to the default libraries.
 *
 * The cost is that the watcom linker will complain about linking to this version
 * instead of the one in KERNEL32.DLL, but that's just what it takes to make this work,
 * so the warning will have to just continue until Watcom devs resolve this. */
LPWSTR WINAPI GetCommandLineW(void) {
	return L"";
}

DWORD WINAPI GetModuleFileNameW(HMODULE meh,LPWSTR lpFilename,DWORD nSize) {
	return 0;
}

BOOL WINAPI SetEnvironmentVariableW(LPCWSTR lpName,LPCWSTR lpValue) {
	return FALSE;
}

/* Another hack: Win95/98/ME/NT/etc. provide GetEnvironmentStringsA, but the Win32s only
 * provide GetEnvironmentStrings. Naturally since Open Watcom's C runtime is targeting NT,
 * we have to redirect GetEnvironmentStringsA() to GetEnvironmentStrings(). */
# undef GetEnvironmentStringsA
# undef GetEnvironmentStrings
char *WINAPI GetEnvironmentStrings(void);
char *WINAPI GetEnvironmentStringsA(void) {
	return GetEnvironmentStrings();
}
#endif
