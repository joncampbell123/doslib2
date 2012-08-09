
#if defined(TARGET_WINDOWS)
# include <windows.h>
#endif
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* useful macros */
#define cpp_stringify_l2(x) #x
#define cpp_stringify(x) cpp_stringify_l2(x)

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

