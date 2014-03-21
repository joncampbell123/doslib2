#!/bin/bash
# WARNING: This code assumes your filesystem (probably ext3/ext4) supports sparse files
# WARNING: We generate disk images larger than 128GB, which *should* work with the DOS kernel,
#          but will have problems with disk I/O if you install Windows in the image. The
#          Windows IDE driver does not support drives >= 128GB (does not support LBA48).
for size in 1 2 4 5 8 10 15 16 20 24 31 32 48 63 80 120 160 210 240 320 400 480 504 620 800 960 1023 1200 1600 2000 2200 3000 4000 6000 8000 8600 11000 16000 24000 32000 40000 80000 120000 160000; do
	# run the generation script
	./make622hdd.everything.sh --size $size || exit 1

	# make the size directory
	rm -Rfv "../../build/$size"mb || exit 1
	mkdir -p "../../build/$size"mb || exit 1

	# now put the files in place
	for name in msdos210hdd msdos220tdhdd msdos320epsonhdd msdos330hdd msdos330nechdd msdos401hdd msdos500hdd msdos600hdd msdos620hdd msdos621hdd msdos622hdd msdos70hdd msdos70sp1hdd msdos710osr2hdd msdos710win98hdd msdos710win98sehdd msdos80winmehdd; do
		rm -v ../../build/$name || exit 1
		mv -vn ../../build/$name.vdi "../../build/$size"mb/"$name.$size"mb.vdi || exit 1
	done
done

for vdi in ../../build/*/*.vdi; do
	echo "Compressing $vdi..." || exit 1
	xz -6e "$vdi" || exit 1
done

