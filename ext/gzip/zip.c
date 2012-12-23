/* zip.c -- compress files to the gzip or pkzip format

   Copyright (C) 1997-1999, 2006-2007, 2009-2012 Free Software Foundation, Inc.
   Copyright (C) 1992-1993 Jean-loup Gailly

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software Foundation,
   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.  */

#include <config.h>
#include <ctype.h>

#include "tailor.h"
#include "gzip.h"

#include <unistd.h>
#include <fcntl.h>

/* we must map stdin reading to winfcon.
 * NOTE: This fixes the bug where running this program under Windows 3.1 Win32s
 *       causes the screen to suddenly go blank. Apparently reading STDIN from
 *       a Win386 32-bit app causes the Watcom extender to flip out */
#if defined(TARGET_WINDOWS)
# include <windows.h>
# include <windows/apihelp.h>
# if defined(TARGET_WINDOWS_GUI) && !defined(TARGET_WINDOWS_CONSOLE)
#  define WINFCON_ENABLE 1
#  include <windows/winfcon/winfcon.h>
# endif
#endif

local ulg crc;       /* crc on uncompressed file data */
off_t header_bytes;   /* number of bytes in gzip header */

/* ===========================================================================
 * Deflate in to out.
 * IN assertions: the input and output buffers are cleared.
 *   The variables time_stamp and save_orig_name are initialized.
 */
int zip(in, out)
    int in, out;            /* input and output file descriptors */
{
    uch  flags = 0;         /* general purpose bit flags */
    ush  attr = 0;          /* ascii/binary flag */
    ush  deflate_flags = 0; /* pkzip -es, -en or -ex equivalent */
    ulg  stamp;

    ifd = in;
    ofd = out;
    outcnt = 0;

    /* Write the header to the gzip file. See algorithm.doc for the format */

    method = DEFLATED;
    put_byte(GZIP_MAGIC[0]); /* magic header */
    put_byte(GZIP_MAGIC[1]);
    put_byte(DEFLATED);      /* compression method */

    if (save_orig_name) {
        flags |= ORIG_NAME;
    }
    put_byte(flags);         /* general flags */
    stamp = (ulg) 0;
    put_long (stamp);

    /* Write deflated file to zip file */
    crc = updcrc(0, 0);

    bi_init(out);
    ct_init(&attr, &method);
    lm_init(level, &deflate_flags);

    put_byte((uch)deflate_flags); /* extra flags */
    put_byte(OS_CODE);            /* OS identifier */

    if (save_orig_name) {
        char *p = gzip_base_name (ifname); /* Don't save the directory part. */
        do {
            put_byte (*p);
        } while (*p++);
    }
    header_bytes = (off_t)outcnt;

    (void)deflate();

#ifndef NO_SIZE_CHECK
  /* Check input size (but not in VMS -- variable record lengths mess it up)
   * and not on MSDOS -- diet in TSR mode reports an incorrect file size)
   */
    if (ifile_size != -1L && bytes_in != ifile_size) {
        fprintf(stderr, "%s: %s: file size changed while zipping\n",
                "gzip", ifname);
    }
#endif

    /* Write the crc and uncompressed size */
    put_long(crc);
    put_long((ulg)bytes_in);
    header_bytes += 2*4;

    flush_outbuf();
    return 0;
}


/* ===========================================================================
 * Read a new buffer from the current input file, perform end-of-line
 * translation, and update the crc and input file size.
 * IN assertion: size >= 2 (for end-of-line translation)
 */
int file_read(buf, size)
    char *buf;
    unsigned size;
{
    unsigned len;

    Assert(insize == 0, "inbuf not empty");

    len = read_buffer (ifd, buf, size);
    if (len == 0) return (int)len;
    if (len == (unsigned)-1) {
        read_error();
        return EOF;
    }

    crc = updcrc((uch*)buf, len);
    bytes_in += (off_t)len;
    return (int)len;
}
