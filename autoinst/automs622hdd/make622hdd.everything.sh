#!/bin/bash
for i in 2.1 3.2epson 3.3 3.3nec 4.01 5.0 6.0 6.20 6.21 6.22; do
	./make622hdd.pl $* --ver $i || break
done

