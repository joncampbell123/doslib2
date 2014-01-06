
#include <efi.h>
#include <efilib.h>
#include <efistdarg.h>

#ifndef __STRING
#define __STRING(x)     #x
#endif

void _assert(int c,const char *c_str);

#define assert(x) _assert((int)(x),__STRING(x))

