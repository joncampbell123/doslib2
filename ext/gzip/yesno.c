/* yesno.c -- read a yes/no response from stdin

   Copyright (C) 1990, 1998, 2001, 2003-2012 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

#include <config.h>

#include "yesno.h"

#include <stdlib.h>
#include <stdio.h>

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

/* Return true if we read an affirmative line from standard input.

   Since this function uses stdin, it is suggested that the caller not
   use STDIN_FILENO directly, and also that the line
   atexit(close_stdin) be added to main().  */

bool
yesno (void)
{
  bool yes;

#if ENABLE_NLS
  char *response = NULL;
  size_t response_size = 0;
  ssize_t response_len = getline (&response, &response_size, stdin);

  if (response_len <= 0)
    yes = false;
  else
    {
      response[response_len - 1] = '\0';
      yes = (0 < rpmatch (response));
    }

  free (response);
#else
  /* Test against "^[yY]", hardcoded to avoid requiring getline,
     regex, and rpmatch.  */
  int c = getchar ();
  yes = (c == 'y' || c == 'Y');
  while (c != 13 && c != 10 && c != EOF)
    c = getchar ();
#endif

  return yes;
}
