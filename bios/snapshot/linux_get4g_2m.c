/* ROM capture, Linux style */
#include <string.h>

/* capture 0xFFE00000-0xFFFFFFFF */
#define CAPTURE_SPRINTF "%08llX.ROM"
static const size_t ROM_size = (2UL << 20UL); /* 2MB */
static const unsigned long long ROM_offset = 0xFFE00000ULL;
static const size_t ROM_blocksize = (64UL << 10UL);

#define HELLO	"This program will write the 4GB-2MB adapter ROM region to disk in\n"\
		"64KB fragments. Disk space required: 2MB\n"\
		"\n"

#include "linux_getcommon.c"

