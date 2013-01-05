
#if defined(TARGET_WINDOWS)
# include <windows.h>
#endif
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* useful macros */
#define cpp_stringify_l2(x) #x
#define cpp_stringify(x) cpp_stringify_l2(x)

#define _cpp_stringify(x) #x
#define _cpp_stringify_num(x) _cpp_stringify(x)

/* useful FAR definition */
#ifndef FAR
# if TARGET_MSDOS == 16
#  if defined(__COMPACT__) || defined(__LARGE__) || defined(__HUGE__)
#   define FAR __far
#  else
#   define FAR
#  endif
# else
#  define FAR
# endif
#endif /* FAR */

/* Stupid watcom inline assembler */
#if TARGET_BITS == 16
# define TARGET_BITS_16 1
#elif TARGET_BITS == 32
# define TARGET_BITS_32 1
#endif

/* It's not safe to use cli/sti unless from MS-DOS or Win16 environments.
 * It's OK to use them as a Win32 program under Windows 9x/ME but NT will trap and throw an exception */
#if defined(TARGET_BITS_16) || (defined(TARGET_BITS_32) && (defined(TARGET_MSDOS) || defined(TARGET_WINDOWS_WIN386)))
# define TARGET_CLI_STI_IS_SAFE
#endif

