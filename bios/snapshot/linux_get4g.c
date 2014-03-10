/* ROM capture, Linux style */
#include <string.h>

/* capture 0xFFF00000-0xFFFFFFFF */
#define CAPTURE_SPRINTF "%08llX.ROM"
static const size_t ROM_size = (1UL << 20UL); /* 1MB */
static const unsigned long long ROM_offset = 0xFFF00000ULL;
static const size_t ROM_blocksize = (64UL << 10UL);

#define HELLO	"This program will write the 4GB-1MB adapter ROM region to disk in\n"\
		"64KB fragments. Disk space required: 1MB\n"\
		"\n"

#include "linux_getcommon.c"

