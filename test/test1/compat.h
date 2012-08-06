
#if TARGET_BITS == 32 && defined(TARGET_WINDOWS) && defined(TARGET_WINDOWS_WIN32s) && !defined(W32IMPHK_INTERNAL)
/* Another hack: Win95/98/ME/NT/etc. provide GetEnvironmentStringsA, but the Win32s only
 * provide GetEnvironmentStrings. Naturally since Open Watcom's C runtime is targeting NT,
 * we have to redirect GetEnvironmentStringsA() to GetEnvironmentStrings(). */
# undef GetEnvironmentStrings
# define GetEnvironmentStringsA GetEnvironmentStrings
#endif

