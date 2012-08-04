#!/bin/bash
./cleantree
echo >NEWS
echo >AUTHORS
echo >ChangeLog
(autoheader && aclocal -I m4 --install && libtoolize && autoconf && automake --add-missing) || exit 1
mkdir -p m4 || exit 1
# ./configure --prefix=/usr || exit 1

