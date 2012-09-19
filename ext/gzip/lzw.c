/* lzw.c -- compress files in LZW format.
 * This is a dummy version avoiding patent problems.
 */

#include <config.h>
#include "tailor.h"
#include "gzip.h"
#include "lzw.h"

/* we must map stdin reading to winfcon.
 * NOTE: This fixes the bug where running this program under Windows 3.1 Win32s
 *       causes the screen to suddenly go blank. Apparently reading STDIN from
 *       a Win386 32-bit app causes the Watcom extender to flip out */
#if defined(TARGET_WINDOWS)
# include <windows.h>
# include <windows/w32imphk/compat.h>
# include <windows/apihelp.h>
# if defined(TARGET_WINDOWS_GUI) && !defined(TARGET_WINDOWS_CONSOLE)
#  define WINFCON_ENABLE 1
#  include <windows/winfcon/winfcon.h>
# endif
#endif

static int msg_done = 0;

/* Compress in to out with lzw method. */
int lzw(in, out)
    int in, out;
{
    if (msg_done) return 1;
    msg_done = 1;
    fprintf(stderr,"output in compress .Z format not supported\n");
    if (in != out) { /* avoid warnings on unused variables */
        exit_code = 1;
    }
    return 1;
}
