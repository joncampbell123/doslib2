/* ROM capture, Windows NT/2000/XP style */
/* NTS: This doesn't work. When Microsoft called it \Device\PhysMem they *REALLY*
 * meant it should be used ONLY for physical memory. So asking it to read 1MB off
 * the top of the 4GB limit is really asking too much. */
#include <string.h>

/* capture 0xFFF00000-0xFFFFFFFF */
#define CAPTURE_SPRINTF "%08llX.ROM"
static const size_t ROM_size = (1UL << 20UL); /* 1MB */
static const unsigned long long ROM_offset = 0xFFF00000ULL;
static const size_t ROM_blocksize = (64UL << 10UL);

#define HELLO	"This program will write the 4GB-1MB adapter ROM region to disk in\n"\
		"64KB fragments. Disk space required: 1MB\n"\
		"\n"

#include "winnt_getcommon.c"

