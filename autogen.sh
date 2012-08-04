#!/bin/bash
./cleantree
echo >NEWS
echo >AUTHORS
echo >ChangeLog
(aclocal && autoheader && libtoolize && automake --add-missing && autoconf) || exit 1
mkdir -p m4 || exit 1
# ./configure --prefix=/usr || exit 1

