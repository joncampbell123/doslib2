#!/bin/bash
./cleantree
echo >NEWS
echo >AUTHORS
echo >ChangeLog
mkdir -p m4 || exit 1
(autoheader && aclocal -I m4 --install && libtoolize && autoconf && automake --add-missing --foreign --copy) || exit 1
# ./configure --prefix=/usr || exit 1

