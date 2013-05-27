#!/bin/bash
for i in 2.1 3.2epson 3.3 3.3nec 4.01 5.0 6.0 6.20 6.21 6.22 7.0 7.0sp1 7.1osr2 7.1win98 7.1win98se 8.0winme; do
	./make622hdd.pl $* --ver $i || break
done

