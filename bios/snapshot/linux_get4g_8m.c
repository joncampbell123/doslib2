/* ROM capture, Linux style */
#include <string.h>

/* capture 0xFF800000-0xFFFFFFFF */
#define CAPTURE_SPRINTF "%08llX.ROM"
static const size_t ROM_size = (8UL << 20UL); /* 8MB */
static const unsigned long long ROM_offset = 0xFF800000ULL;
static const size_t ROM_blocksize = (64UL << 10UL);

#define HELLO	"This program will write the 4GB-8MB adapter ROM region to disk in\n"\
		"64KB fragments. Disk space required: 8MB\n"\
		"\n"

#include "linux_getcommon.c"

