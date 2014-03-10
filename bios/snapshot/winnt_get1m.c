/* ROM capture, Windows NT/2000/XP style */
#include <string.h>

/* capture 0xC0000-0xFFFFF */
#define CAPTURE_SPRINTF "PC_%05llX.ROM"
static const size_t ROM_size = (256UL << 10UL);
static const unsigned long long ROM_offset = 0xC0000ULL;
static const size_t ROM_blocksize = (64UL << 10UL);

#define HELLO	"This program will write the 1MB adapter ROM region to disk in\n"\
		"64KB fragments. Disk space required: 256KB\n"\
		"\n"

#include "winnt_getcommon.c"

