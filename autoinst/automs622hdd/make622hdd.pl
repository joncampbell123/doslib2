#!/usr/bin/perl
#
# Use MS-DOS 6.22 installation disks to construct a bootable hard drive image
#
# requires:
#     mtools
#     fdisk
#     dd
#     mkdosfs
#     qemu-img
#
# in-tree requirements:
#     ../../download-item.pl

my $rel = "../..";
my $diskbase = "$rel/build/msdos622hdd";

sub shellesc($) {
	my $a = shift @_;
	$a =~ s/([^0-9a-zA-Z\.\-])/\\$1/g;
	return $a;
}

# download images, Disk 1, Disk 2, Disk 3
system("../../download-item.pl --rel $rel --as msdos.622.install.1.disk.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 1.img.xz")) == 0 || die;
system("../../download-item.pl --rel $rel --as msdos.622.install.2.disk.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 2.img.xz")) == 0 || die;
system("../../download-item.pl --rel $rel --as msdos.622.install.3.disk.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 3.img.xz")) == 0 || die;

# construct the disk image
system("mkdir -p $rel/build") == 0 || die;

my $cyls = 1020;
my $heads = 16;
my $sects = 63;

sub unpack_dos_tmp() {
# unpack the compressed files
	my @l = (
		"SY_","SYS",
		"EX_","EXE",
		"TX_","TXT",
		"CP_","CPI",
		"HL_","HLP",
		"OV_","OVL",
		"DL_","DLL",
		"CO_","COM",
		"GR_","GRP",
		"LS_","LST",
		"38_","386",
		"IN_","INI",
		"PR_","PRG"
	);
	for ($i=0;($i+2) <= @l;$i += 2) {
		my $old = $l[$i],$new = $l[$i+1],$nname;

		opendir(DIR,"dos.tmp") || die;
		while (my $n = readdir(DIR)) {
			next if $n =~ m/^\./;
			next unless -f "dos.tmp/$n";
			next unless $n =~ m/\.$old$/;
			$nname = $n;
			$nname =~ s/\.$old$/.$new/;

			print "$n -> $nname\n";
			system("./expand dos.tmp/$n dos.tmp/$nname") == 0 || die;
			unlink("dos.tmp/$n") || die;
		}
		closedir(DIR);
	}
}

print "Constructing HDD image: C/H/S $cyls/$heads/$sects\n";
system("rm -v $diskbase; dd if=/dev/zero of=$diskbase bs=512 count=1 seek=".(($cyls*$heads*$sects)-1-$sects));

print "Formatting disk image: \n";
system("mkdosfs -f 2 -F 16 $diskbase") == 0 || die;

print "Unpacking disk 1:\n";
system("xz -c -d $rel/web.cache/msdos.622.install.1.disk.xz >tmp.dsk") == 0 || die;

# copy the boot sector of the install disk, being careful not to overwrite the BPB written by mkdosfs
print "Sys'ing the disk:\n";
system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=0 skip=0 count=11") == 0 || die;
system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=62 skip=62 count=".(512-62)) == 0 || die;

# and copy IO.SYS and MSDOS.SYS over, assuming that mkdosfs has left the root directory completely empty
# so that our copy operation puts them FIRST in the root directory.
system("mcopy -i tmp.dsk ::IO.SYS tmp.sys") == 0 || die;
system("mcopy -i $diskbase tmp.sys ::IO.SYS") == 0 || die;
system("mattrib -a +r +s +h -i $diskbase ::IO.SYS") == 0 || die;
unlink("tmp.sys");

system("mcopy -i tmp.dsk ::MSDOS.SYS tmp.sys") == 0 || die;
system("mcopy -i $diskbase tmp.sys ::MSDOS.SYS") == 0 || die;
system("mattrib -a +r +s +h -i $diskbase ::MSDOS.SYS") == 0 || die;
unlink("tmp.sys");

system("mcopy -i tmp.dsk ::DRVSPACE.BIN tmp.sys") == 0 || die;
system("mcopy -i $diskbase tmp.sys ::DRVSPACE.BIN") == 0 || die;
system("mattrib -a +r +s +h -i $diskbase ::DRVSPACE.BIN") == 0 || die;
unlink("tmp.sys");

system("mcopy -i tmp.dsk ::COMMAND.COM tmp.sys") == 0 || die;
system("mcopy -i $diskbase tmp.sys ::COMMAND.COM") == 0 || die;
system("mattrib -a +r +s -i $diskbase ::COMMAND.COM") == 0 || die;
unlink("tmp.sys");

# create DOS subdirectory
system("mmd -i $diskbase DOS") == 0 || die;
system("rm -Rfv dos.tmp; mkdir -p dos.tmp") == 0 || die;

# copy the other contents of the floppy (disk 1) to the DOS subdirectory
system("mcopy -b -Q -n -m -v -s -i tmp.dsk ::. dos.tmp/") == 0 || die;
unlink("tmp.dsk");

# copy the other contents of the floppy (disk 2) to the DOS subdirectory
print "Unpacking disk 2:\n";
system("xz -c -d $rel/web.cache/msdos.622.install.2.disk.xz >tmp.dsk") == 0 || die;
system("mcopy -b -Q -n -m -v -s -i tmp.dsk ::. dos.tmp/") == 0 || die;
unlink("tmp.dsk");

# copy the other contents of the floppy (disk 3) to the DOS subdirectory
print "Unpacking disk 3:\n";
system("xz -c -d $rel/web.cache/msdos.622.install.3.disk.xz >tmp.dsk") == 0 || die;
system("mcopy -b -Q -n -m -v -s -i tmp.dsk ::. dos.tmp/") == 0 || die;
unlink("tmp.dsk");

# unpack the compressed files
unpack_dos_tmp();

# copy them back into the hard disk image
system("mcopy -b -Q -n -m -v -s -i $diskbase dos.tmp/. ::DOS/") == 0 || die;

# remove dos.tmp
system("rm -Rfv dos.tmp; mkdir -p dos.tmp") == 0 || die;

# next, add the OAK IDE CD-ROM driver
system("mcopy -i $diskbase oakcdrom.sys ::DOS/OAKCDROM.SYS") == 0 || die;

# and the default CONFIG.SYS and AUTOEXEC.BAT files
system("mcopy -i $diskbase config.sys.init ::CONFIG.SYS") == 0 || die;
system("mcopy -i $diskbase autoexec.bat.init ::AUTOEXEC.BAT") == 0 || die;

# ugh... and it turns out mkdosfs leaves byte 0x24 set to zero among other stupid things
open(BIN,"+<","$diskbase") || die
binmode(BIN);

seek(BIN,0x24,0); print BIN pack("c",0x80); # this is a hard disk

seek(BIN,0x18,0); print BIN pack("v",$sects); # let me tell you the TRUE sectors/track
seek(BIN,0x1A,0); print BIN pack("v",$heads); # and heads
seek(BIN,0x1C,0); print BIN pack("V",$sects); # and number of "hidden sectors" preceeding the partition

close(BIN);

# make a zero track and cat them together to make a full disk image
system("dd if=/dev/zero of=$diskbase.c0 bs=512 count=".($sects)) == 0 || die;
system("dd conv=notrunc,nocreat if=mbr.bin of=$diskbase.c0 bs=512 count=1") == 0 || die;
system("cat $diskbase.c0 $diskbase >$diskbase.raw") == 0 || die;

# and then edit the partition table directly. we WOULD use fdisk, but fdisk has this
# terrible fetish for forcing your first partition at least 2048 sectors away from the start
# of the disk, which is an utter waste of disk space. Fuck you fdisk.
open(BIN,"+<","$diskbase.raw") || die
binmode(BIN);
seek(BIN,0x1BE,0);
print BIN pack("cccccccc",
	0x80, # status/physical drive
	0x01, # head 1
	0x01 | (0 << 6), # sector 1 cylinder 0 (high 2 bits)
	0x00, # cylinder 0 (low 8 bits)
	0x06, # partition type (0x06 = MS-DOS FAT16 >= 32MB)
	$heads-1, # end head
	$sects | ((($cyls - 1) >> 8) << 6), # end sector/cylinder
	($cyls - 1) & 0xFF); # end cylinder
print BIN pack("VV",$sects,($sects*$cyls*$heads)-$sects);
close(BIN);

# ckeanup
unlink("$diskbase");
unlink("$diskbase.c0");

# make VDI for VirtualBox, QEMU, etc
system("qemu-img convert -f raw -O vdi $diskbase.raw $diskbase.vdi") == 0 || die;

