
#include <efi.h>
#include <efilib.h>
#include <efistdarg.h>

void _assert(int c,const char *c_str);

#define assert(x) _assert(((int)(x)) != 0,__STRING(x))

