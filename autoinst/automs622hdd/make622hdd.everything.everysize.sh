#!/bin/bash
# WARNING: This code assumes your filesystem (probably ext3/ext4) supports sparse files
for size in 10 15 16 20 24 31 32 48 63 80 120 160 210 240 320 400 480 504 620 800 960 1023 1200 1600 2000 2200 3000 4000 6000 8000 8600 11000 16000 24000; do
	for i in 2.1 2.2td 3.2epson 3.3 3.3nec 4.01 5.0 6.0 6.20 6.21 6.22 7.0 7.0sp1 7.1osr2 7.1win98 7.1win98se 8.0winme; do
		./make622hdd.pl $* --ver $i --size $size || exit 1
	done

	for name in msdos210hdd msdos220tdhdd msdos320epsonhdd msdos330hdd msdos330nechdd msdos401hdd msdos500hdd msdos600hdd msdos620hdd msdos621hdd msdos622hdd msdos70hdd msdos70sp1hdd msdos710osr2hdd msdos710win98hdd msdos710win98sehdd msdos80winmehdd; do
		rm -v ../../build/$name || exit 1
		mv -vn ../../build/$name.vdi "../../build/$name.$size"mb.vdi || exit 1
	done
done

