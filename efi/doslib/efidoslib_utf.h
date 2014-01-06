
#include <efi.h>
#include <efilib.h>
#include <efistdarg.h>

enum {
	UTF8ERR_INVALID=-1,
	UTF8ERR_NO_ROOM=-2
};

#ifndef UNICODE_BOM
#define UNICODE_BOM 0xFEFF
#endif

typedef char utf8_t;
typedef uint16_t utf16_t;

int utf8_encode(char **ptr,char *fence,uint32_t code);
int utf8_decode(const char **ptr,const char *fence);
int utf16le_encode(char **ptr,char *fence,uint32_t code);
int utf16le_decode(const char **ptr,const char *fence);

