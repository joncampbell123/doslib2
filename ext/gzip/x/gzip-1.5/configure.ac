# Configure template for gzip.

# Copyright (C) 1999-2002, 2006-2007, 2009-2012 Free Software Foundation, Inc.

# Copyright (C) 1992-1993 Jean-loup Gailly

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

AC_PREREQ([2.60])
AC_INIT([gzip],
        m4_esyscmd([build-aux/git-version-gen .tarball-version]),
        [bug-gzip@gnu.org])

AC_CONFIG_SRCDIR(gzip.c)
AC_CONFIG_AUX_DIR(build-aux)
AC_CONFIG_HEADERS([lib/config.h:lib/config.hin])
AM_INIT_AUTOMAKE([1.11 dist-xz color-tests parallel-tests])
AM_SILENT_RULES([yes]) # make --enable-silent-rules the default.

AC_PROG_CC_STDC
AM_PROG_CC_C_O
AC_PROG_CPP
AC_CHECK_TOOL([NM], [nm], [nm])
AC_PROG_LN_S
AC_PROG_RANLIB
AC_PROG_SHELL

gl_EARLY

gl_INIT

AC_ARG_ENABLE([gcc-warnings],
  [AS_HELP_STRING([--enable-gcc-warnings],
                  [turn on lots of GCC warnings (for developers)])],
  [case $enableval in
     yes|no) ;;
     *)      AC_MSG_ERROR([bad value $enableval for gcc-warnings option]) ;;
   esac
   gl_gcc_warnings=$enableval],
  [gl_gcc_warnings=no]
)

if test "$gl_gcc_warnings" = yes; then
  gl_WARN_ADD([-Werror], [WERROR_CFLAGS])
  AC_SUBST([WERROR_CFLAGS])

  nw=
  # This, $nw, is the list of warnings we disable.
  nw="$nw -Wdeclaration-after-statement" # too useful to forbid
  nw="$nw -Waggregate-return"       # anachronistic
  nw="$nw -Wlong-long"              # C90 is anachronistic (lib/gethrxtime.h)
  nw="$nw -Wc++-compat"             # We don't care about C++ compilers
  nw="$nw -Wundef"                  # Warns on '#if GNULIB_FOO' etc in gnulib
  nw="$nw -Wtraditional"            # Warns on #elif which we use often
  nw="$nw -Wcast-qual"              # Too many warnings for now
  nw="$nw -Wconversion"             # Too many warnings for now
  nw="$nw -Wsystem-headers"         # Don't let system headers trigger warnings
  nw="$nw -Wsign-conversion"        # Too many warnings for now
  nw="$nw -Wtraditional-conversion" # Too many warnings for now
  nw="$nw -Wunreachable-code"       # Too many warnings for now
  nw="$nw -Wpadded"                 # Our structs are not padded
  nw="$nw -Wredundant-decls"        # openat.h declares e.g., mkdirat
  nw="$nw -Wlogical-op"             # any use of fwrite provokes this
  nw="$nw -Wformat-nonliteral"      # who.c and pinky.c strftime uses
  nw="$nw -Wvla"                    # warnings in gettext.h
  nw="$nw -Wnested-externs"         # use of XARGMATCH/verify_function__
  nw="$nw -Wswitch-enum"            # Too many warnings for now
  nw="$nw -Wswitch-default"         # Too many warnings for now
  nw="$nw -Wstack-protector"        # not worth working around
  # things I might fix soon:
  nw="$nw -Wfloat-equal"            # sort.c, seq.c
  nw="$nw -Wmissing-format-attribute" # copy.c
  nw="$nw -Wunsafe-loop-optimizations" # a few src/*.c
  nw="$nw -Winline"                 # system.h's readdir_ignoring_dot_and_dotdot
  nw="$nw -Wstrict-overflow"        # expr.c, pr.c, tr.c, factor.c
  # initial problems in gzip
  nw="$nw -Wold-style-definition"
  nw="$nw -Wshadow"
  nw="$nw -Wunused-macros"
  # ?? -Wstrict-overflow

  gl_MANYWARN_ALL_GCC([ws])
  gl_MANYWARN_COMPLEMENT([ws], [$ws], [$nw])
  for w in $ws; do
    gl_WARN_ADD([$w])
  done
  gl_WARN_ADD([-Wno-missing-field-initializers]) # We need this one
  gl_WARN_ADD([-Wno-sign-compare])     # Too many warnings for now
  gl_WARN_ADD([-Wno-pointer-sign])     # Too many warnings for now
  gl_WARN_ADD([-Wno-unused-parameter]) # Too many warnings for now
  gl_WARN_ADD([-Wno-overflow])         # util.c
  gl_WARN_ADD([-Wno-type-limits])      # util.c
  gl_WARN_ADD([-Wno-format-nonliteral])
  gl_WARN_ADD([-Wno-unsuffixed-float-constants])

  # In spite of excluding -Wlogical-op above, it is enabled, as of
  # gcc 4.5.0 20090517, and it provokes warnings in cat.c, dd.c, truncate.c
  gl_WARN_ADD([-Wno-logical-op])

  gl_WARN_ADD([-fdiagnostics-show-option])
  gl_WARN_ADD([-funit-at-a-time])

  AC_SUBST([WARN_CFLAGS])

  AC_DEFINE([lint], [1], [Define to 1 if the compiler is checking for lint.])
  AC_DEFINE([_FORTIFY_SOURCE], [2],
    [enable compile-time and run-time bounds-checking, and some warnings])
  AC_DEFINE([GNULIB_PORTCHECK], [1], [enable some gnulib portability checks])

  # We use a slightly smaller set of warning options for lib/.
  # Remove the following and save the result in GNULIB_WARN_CFLAGS.
  nw=
  nw="$nw -Wuninitialized"
  nw="$nw -Wmissing-prototypes"
  nw="$nw -Wold-style-definition"
  gl_MANYWARN_COMPLEMENT([GNULIB_WARN_CFLAGS], [$WARN_CFLAGS], [$nw])
  AC_SUBST([GNULIB_WARN_CFLAGS])
fi

# cc -E produces incorrect asm files on SVR4, so postprocess it.
ASCPPPOST="sed '/^ *\\#/d; s,//.*,,; s/% /%/g; s/\\. /./g'"
AC_SUBST([ASCPPPOST])

AC_CACHE_CHECK([for underline in external names], [gzip_cv_underline],
  [gzip_cv_underline=yes
   AC_TRY_COMPILE([int foo() {return 0;}], [],
     [$NM conftest.$OBJEXT | grep _foo >/dev/null 2>&1 ||
        gzip_cv_underline=no])])
ASCPPFLAGS=
if test $gzip_cv_underline = no; then
  ASCPPFLAGS='-DNO_UNDERLINE'
fi
AC_SUBST([ASCPPFLAGS])
AC_OBJEXT

# Try to assemble match.S.
# "gcc -E match.s" ignores -E, so we must use _match.S.
AC_CACHE_CHECK([for an assembler syntax supported by this package],
  [gzip_cv_assembler],
  [gzip_cv_assembler=no
   case " $DEFS " in
   *' NO_ASM '*) ;;
   *)
     if cp $srcdir/lib/match.c _match.S &&
        eval "$CPP $CPPFLAGS $ASCPPFLAGS _match.S > _match.i" &&
        eval "$ASCPPPOST < _match.i > match_.s"; then
       if test ! -s match_.s || grep error < match_.s > /dev/null; then
         :
       elif eval "$CC $CPPFLAGS $CFLAGS -c match_.s >/dev/null" &&
            test -f match_.$OBJEXT; then
         rm -f match_.$OBJEXT
         gzip_cv_assembler=yes
         if echo 'void foo (void) {}' > conftest.c &&
            eval "$CC $CPPFLAGS $CFLAGS -S conftest.c >/dev/null" &&
            grep '\.note\.GNU-stack' conftest.s >/dev/null &&
            eval "$CC $CPPFLAGS $CFLAGS -c -Wa,--noexecstack match_.s >/dev/null" &&
            test -f match_.$OBJEXT; then
           gzip_cv_assembler='yes, with -Wa,--noexecstack'
         fi
       fi
     fi
     rm -f conftest* _match.i _match.S match_.s match_.$OBJEXT;;
   esac])
if test "$gzip_cv_assembler" != no; then
  AC_DEFINE(ASMV, ,
    [Define if an assembler version of longest_match is available.])
  AC_LIBOBJ(match)
fi
if test "$gzip_cv_assembler" = 'yes, with -Wa,--noexecstack'; then
  ASFLAGS_config='-Wa,--noexecstack'
else
  ASFLAGS_config=
fi
AC_SUBST([ASFLAGS_config])

AC_ISC_POSIX
AC_C_CONST
AC_HEADER_STDC
AC_CHECK_HEADERS_ONCE(fcntl.h limits.h memory.h time.h)
AC_CHECK_FUNCS_ONCE([chown fchmod fchown lstat siginterrupt])
AC_HEADER_DIRENT
AC_TYPE_SIGNAL
AC_TYPE_SIZE_T
AC_TYPE_OFF_T

AC_CONFIG_FILES([Makefile doc/Makefile lib/Makefile tests/Makefile])
AC_OUTPUT
