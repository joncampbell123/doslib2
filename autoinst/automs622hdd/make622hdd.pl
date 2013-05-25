#!/usr/bin/perl
#
# Use MS-DOS 6.22 installation disks to construct a bootable hard drive image.
# It is also designed to allow using similar versions of MS-DOS (prior to 6.22)
# that install the same way.
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
#
# params
#     --size <n> in MB
#     --supp                        install Supplementary Disk 4, if available
#     --dosshell-vid <n>            pre-configure DOSSHELL.EXE video. Valid values: none, vga [default], vgamono, ega, egamono, herc, cga, mono, 8514, 8514mono
#     --ver <n>
#      
#         where <n> is:
#             6.22       MS-DOS 6.22 (default)
#             6.21       MS-DOS 6.21
#             6.20       MS-DOS 6.20
#             6.0        MS-DOS 6.0
#             5.0        MS-DOS 5.0
#             4.01       MS-DOS 4.01
#             3.3nec     MS-DOS 3.3 [NEC version]
#             3.3        MS-DOS 3.3
#             3.2epson   MS-DOS 3.2 [SEIKO EPSON version]
#
#     Installed image is English language (US) version.
#
#     --geomemtry C/H/S             allows you to specify a custom disk geometry

my $dosshell_vid = "vga";
my $target_size = 0;
my $ver = "6.22";
my $do_supp = 0;
my $config_sys_file;
my $autoexec_bat_file;

my $part_type = 0x06;
my $cyls = 1020,$act_cyls;
my $heads = 16;
my $sects = 63;
my $clustersize = -1;
my $fat_len = -1;

for ($i=0;$i < @ARGV;) {
	my $a = $ARGV[$i++];

	if ($a =~ s/^-+//) {
		if ($a eq "size") {
			$target_size = $ARGV[$i++] + 0;
			$target_size *= 1024 * 1024;
			$target_size = 0 if $target_size < 1;
		}
		elsif ($a eq "ver") {
			$ver = $ARGV[$i++];
		}
		elsif ($a eq "supp") {
			$do_supp = 1;
		}
		elsif ($a eq "dosshell-vid") {
			$dosshell_vid = lc($ARGV[$i++]);
		}
		elsif ($a eq "geometry") {
			($cyls,$heads,$sects) = split(/[-\\\/]+/,$ARGV[$i++]);
			$cyls = $cyls + 0;
			$heads = $heads + 0;
			$sects = $sects + 0;

			die "Invalid geometry C/H/S $cyls/$heads/$sects" if $cyls < 1 || $cyls > 8192 ||
				$heads < 1 || $heads > 255 ||
				$sects < 1 || $sects > 63;

			$target_size = $cyls * $heads * $sects * 512;
		}
		else {
			die "Unknown switch $a\n";
		}
	}
	else {
		die "Unhandled arg $a\n";
	}
}

my $rel = "../..";
my $diskbase = "";
$dosshell_vid = "none" if $dosshell_vid eq '';

die unless $ver ne '';

system("make") == 0 || die;

sub shellesc($) {
	my $a = shift @_;
	$a =~ s/([^0-9a-zA-Z\.\-])/\\$1/g;
	return $a;
}

my $disk1,$disk2,$disk3,$disk4;
my $disk1_url,$disk2_url,$disk3_url,$disk4_url;

if ($ver eq "6.22") {
	$diskbase = "$rel/build/msdos622hdd";

	$config_sys_file = "config.sys.init";
	$autoexec_bat_file = "autoexec.bat.init";

	$disk1 = "msdos.622.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 1.img.xz";

	$disk2 = "msdos.622.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 2.img.xz";

	$disk3 = "msdos.622.install.3.disk.xz";
	$disk3_url = "Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 3.img.xz";

	# TODO: I have another disk set of MS-DOS 6.22 with the 4th Supplementary diskette,
	# I just have to unpack and organize the self-extracting EXEs they're contained in and verify them.
}
elsif ($ver eq "6.21") {
	$diskbase = "$rel/build/msdos621hdd";

	$config_sys_file = "config.sys.init";
	$autoexec_bat_file = "autoexec.bat.init";

	$disk1 = "msdos.621.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/6.21/1.44MB/DISK1.IMA.xz";

	$disk2 = "msdos.621.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/6.21/1.44MB/DISK2.IMA.xz";

	$disk3 = "msdos.621.install.3.disk.xz";
	$disk3_url = "Software/DOS/Microsoft MS-DOS/6.21/1.44MB/DISK3.IMA.xz";
}
elsif ($ver eq "6.20") {
	$diskbase = "$rel/build/msdos620hdd";

	$config_sys_file = "config.sys.init";
	$autoexec_bat_file = "autoexec.bat.init";

	$disk1 = "msdos.620.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/6.20/1.44MB/Install disk 1.ima.xz";

	$disk2 = "msdos.620.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/6.20/1.44MB/Install disk 2.ima.xz";

	$disk3 = "msdos.620.install.3.disk.xz";
	$disk3_url = "Software/DOS/Microsoft MS-DOS/6.20/1.44MB/Install disk 3.ima.xz";

	if ($do_supp) {
		$disk4 = "msdos.620.supplementary.4.disk.xz";
		$disk4_url = "Software/DOS/Microsoft MS-DOS/6.20/1.44MB/Supplemental Disk.ima.xz";
	}
}
elsif ($ver eq "6.0") {
	$diskbase = "$rel/build/msdos600hdd";

	$config_sys_file = "config.sys.init.v60";
	$autoexec_bat_file = "autoexec.bat.init";

	$disk1 = "msdos.600.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/6.0/1.44MB/disk1.ima.xz";

	$disk2 = "msdos.600.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/6.0/1.44MB/disk2.ima.xz";

	$disk3 = "msdos.600.install.3.disk.xz";
	$disk3_url = "Software/DOS/Microsoft MS-DOS/6.0/1.44MB/disk3.ima.xz";

	# Did MS-DOS 6.00 ever have a supplementary disk?
}
elsif ($ver eq "5.0") {
	$diskbase = "$rel/build/msdos500hdd";

	$config_sys_file = "config.sys.init.v50";
	$autoexec_bat_file = "autoexec.bat.init.v50";

	$disk1 = "msdos.500.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/5.0/720K install/disk1.img.xz";

	$disk2 = "msdos.500.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/5.0/720K install/disk2.img.xz";

	$disk3 = "msdos.500.install.3.disk.xz";
	$disk3_url = "Software/DOS/Microsoft MS-DOS/5.0/720K install/disk3.img.xz";
}
elsif ($ver eq "4.01") {
	# NTS: MS-DOS 4.01 doesn't boot (it hangs) when run in QEMU or Bochs
	$diskbase = "$rel/build/msdos401hdd";

	$config_sys_file = "config.sys.init.v401";
	$autoexec_bat_file = "autoexec.bat.init.v401";

	$disk1 = "msdos.401.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/4.01/1.44MB/Disco 1(Instal).IMA.xz";

	$disk2 = "msdos.401.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/4.01/1.44MB/Disco 2(Operating Disquette).IMA.xz";

	$disk3 = "msdos.401.install.3.disk.xz";
	$disk3_url = "Software/DOS/Microsoft MS-DOS/4.01/1.44MB/Disco 3 (Shell).IMA.xz";
}
elsif ($ver eq "3.3nec") {
	$part_type = 0x04; # FAT16 <= 32MB

	$diskbase = "$rel/build/msdos330nechdd";

	$config_sys_file = "config.sys.init.v330nec";
	$autoexec_bat_file = "autoexec.bat.init.v330nec";

	$disk1 = "msdos.330nec.boot.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/3.3 NEC Corporation/1.44MB/bootdisk.img.xz";
}
elsif ($ver eq "3.3") {
	$part_type = 0x04; # FAT16 <= 32MB

	$diskbase = "$rel/build/msdos330hdd";

	$config_sys_file = "config.sys.init.v330";
	$autoexec_bat_file = "autoexec.bat.init.v330";

	$disk1 = "msdos.330.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/3.3/1.44MB/disk1.ima.xz";

	$disk2 = "msdos.330.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/3.3/1.44MB/disk2.ima.xz";
}
elsif ($ver eq "3.2epson") {
	$part_type = 0x04; # FAT16 <= 32MB

	$diskbase = "$rel/build/msdos320epsonhdd";

	$config_sys_file = "config.sys.init.v320";
	$autoexec_bat_file = "autoexec.bat.init.v320";

	$disk1 = "msdos.320epson.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/3.2 Seiko Epson/360KB/DISK1.IMA.xz";

	$disk2 = "msdos.320epson.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/3.2 Seiko Epson/360KB/DISK2.IMA.xz";

	$disk3 = "msdos.320epson.install.3.disk.xz";
	$disk3_url = "Software/DOS/Microsoft MS-DOS/3.2 Seiko Epson/360KB/DISK3.IMA.xz";
}
else {
	die "Unknown MS-DOS version";
}

# sanity
die unless $diskbase ne '';

# download images, Disk 1, Disk 2, Disk 3
system("../../download-item.pl --rel $rel --as $disk1 --url ".shellesc($disk1_url)) == 0 || die;
if ($disk2 ne '') {
	system("../../download-item.pl --rel $rel --as $disk2 --url ".shellesc($disk2_url)) == 0 || die;
}
if ($disk3 ne '') {
	system("../../download-item.pl --rel $rel --as $disk3 --url ".shellesc($disk3_url)) == 0 || die;
}
if ($disk4 ne '') {
	system("../../download-item.pl --rel $rel --as $disk4 --url ".shellesc($disk4_url)) == 0 || die;
}

# construct the disk image
system("mkdir -p $rel/build") == 0 || die;

if ($target_size > 0) {
	$cyls = int(($target_size / 512 / $heads / $sects) + 0.5);
	$cyls = 1 if $cyls == 0;
}

# MS-DOS cannot handle >= 1024 cylinders
while ($cyls >= 1024 && $heads < 128) {
	$heads *= 2;
	$cyls /= 2;
}
# if we still need to reduce, try the 255 head trick
if ($cyls >= 1024) {
	$cyls *= $heads;
	$heads = 255;
	$cyls /= $heads;
}

$act_cyls = int($cyls);
$x = 512 * $cyls * $heads * $sects;
if ($x >= (2048*1024*1024)) {
	# limit the partition to keep within MS-DOS 6.22's capabilities.
	# A partition larger than 2GB is not supported.
	$x = (2047*1024*1024);
	$cyls = $x / 512 / $heads / $sects;
}

if ($ver eq "3.3nec" || $ver eq "3.3" || $ver eq "3.2epson") {
	# MS-DOS v3.3 and earlier cannot support >= 32MB partitions.
	if ($x >= (32*1024*1024)) {
		$x = (31*1024*1024);
		$cyls = $x / 512 / $heads / $sects;
	}
}

my $part_offset_sects = $sects;
my $part_offset = 0x200 * $part_offset_sects;

if ($ver eq "3.3nec" || $ver eq "3.3" || $ver eq "3.2epson") {
	# MS-DOS 3.3 hard disk support is apparently very picky.
	# If it's FAT16 formatted, then the cluster size must be 4 sectors/cluster.
	# If it's FAT12 formatted, then the cluster size must be 8 sectors/cluster.
	$clustersize = 4;

	# At 15MB or less, force mformat to do FAT12. It'd be nice if like mkdosfs they
	# offered something like --fat=12 to explicitly say so, but they don't. Our only
	# hope then is to force the size of the FAT table.
	$x = 512 * $cyls * $heads * $sects;
	if ($x < (16*1024*1024)) {
		$part_type = 0x01; # FAT12 <= 32MB
		$clustersize = 8; # Apparently it's FAT12 support demands 8 sectors/cluster

		# how long does the FAT table need to be?
		# doing this calculation is REQUIRED to force mtools to format the partition
		# as FAT12 rather than trying to shoehorn in FAT16, which MS-DOS 3.3 NEC edition
		# won't accept.
		$fat_len = (($x-$part_offset_sects)/512/$clustersize);
		$fat_len = ($fat_len / 2) * 3;
		$fat_len = int(($fat_len+511)/512);
	}
}

$cyls = int($cyls + 0.5);
die if $cyls >= 1024;

print "Chosen disk geometry C/H/S: $cyls/$heads/$sects (disk $act_cyls)\n";

sub unpack_dos_tmp() {
# unpack the compressed files
	my @l = (
		".SY_",".SYS",
		".EX_",".EXE",
		".TX_",".TXT",
		".CP_",".CPI",
		".HL_",".HLP",
		".OV_",".OVL",
		".DL_",".DLL",
		".CO_",".COM",
		".LS_",".LST",
		".38_",".386",
		".IN_",".INI",
		".PR_",".PRG",
		".BA_",".BAS",
		".VI_",".VID",
		".DO_",".DOS",
		".1X_",".1XE",
		".2X_",".2XE",
		".IC_",".ICE",
		".BI_",".BIN",
		"CGA.GR_","CGA.GRB",
		"EGA.GR_","EGA.GRB",
		"EGAMONO.GR_","EGAMONO.GRB",
		"HERC.GR_","HERC.GRB",
		"MONO.GR_","MONO.GRB",
		"VGA.GR_","VGA.GRB",
		".GR_",".GRP",
	);
	for ($i=0;($i+2) <= @l;$i += 2) {
		my $old = $l[$i],$new = $l[$i+1],$nname;

		open(DIR,"find |") || die;
		while (my $n = <DIR>) {
			chomp $n;
			next unless $n =~ s/^\.\/dos.tmp\///;
			next unless -f "dos.tmp/$n";
			next unless $n =~ m/$old$/;
			$nname = $n;
			$nname =~ s/$old$/$new/;

			print "$n -> $nname\n";
			system("./expand dos.tmp/$n dos.tmp/$nname") == 0 || die;
			unlink("dos.tmp/$n") || die;
		}
		close(DIR);
	}
}

print "Constructing HDD image: C/H/S $act_cyls/$heads/$sects\n";
system("rm -v $diskbase; dd if=/dev/zero of=$diskbase bs=512 count=1 seek=".(($act_cyls*$heads*$sects)-1));

print "Formatting disk image: \n";
system("mformat -m 0xF8 ".
	($clustersize > 0 ? ("-c ".$clustersize)." " : "").
	($fat_len > 0 ? ("-L ".$fat_len)." " : "").
	"-t $cyls -h $heads -s $sects -d 2 -i $diskbase\@\@$part_offset") == 0 || die;

print "Unpacking disk 1:\n";
system("xz -c -d $rel/web.cache/$disk1 >tmp.dsk") == 0 || die;

# copy the boot sector of the install disk, being careful not to overwrite the BPB written by mkdosfs
print "Sys'ing the disk:\n";
if ($ver eq "3.3nec" || $ver eq "3.3" || $ver eq "3.2epson") {
	# copy the boot sector of the install disk, being careful not to overwrite the BPB written by mkdosfs
	system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=".($part_offset   )." skip=0 count=11") == 0 || die;
	system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=".($part_offset+54)." skip=54 count=".(512-54)) == 0 || die;

	# the disk table will need some fixup
	open(BIN,"+<","$diskbase") || die
	binmode(BIN);

	# total sector count fixup
	my $x = ($cyls * $heads * $sects) - $part_offset_sects;
	die "$x is too many sectors" if $x > 65535;
	seek(BIN,$part_offset+0x13,0); print BIN pack("v",$x);

	seek(BIN,$part_offset+0x18,0); print BIN pack("v",$sects); # let me tell you the TRUE sectors/track
	seek(BIN,$part_offset+0x1A,0); print BIN pack("v",$heads); # and heads
	seek(BIN,$part_offset+0x1C,0); print BIN pack("V",$sects); # and number of "hidden sectors" preceeding the partition
	seek(BIN,$part_offset+0x1FD,0); print BIN pack("c",0x80); # this is a hard disk

	# non-MSDOS 4.0+ compatible data
	seek(BIN,$part_offset+0x20,0);
	print BIN pack("cccc"."cccc"."cccc"."cccc"."cccc"."cc",
		0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x12,
	
		0x00,0x00,0x00,0x00,
		0x01,0x00);

	close(BIN);
}
else {
	system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=".($part_offset   )." skip=0 count=11") == 0 || die;
	system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=".($part_offset+62)." skip=62 count=".(512-62)) == 0 || die;

	# the disk table will need some fixup
	open(BIN,"+<","$diskbase") || die
	binmode(BIN);

	# total sector count fixup
	my $x = ($act_cyls * $heads * $sects) - $part_offset_sects;
	seek(BIN,$part_offset+0x13,0); print BIN pack("v",$x > 65535 ? 0 : $x);
	seek(BIN,$part_offset+0x20,0); print BIN pack("V",$x);

	seek(BIN,$part_offset+0x18,0); print BIN pack("v",$sects); # let me tell you the TRUE sectors/track
	seek(BIN,$part_offset+0x1A,0); print BIN pack("v",$heads); # and heads
	seek(BIN,$part_offset+0x1C,0); print BIN pack("V",$sects); # and number of "hidden sectors" preceeding the partition
	seek(BIN,$part_offset+0x24,0); print BIN pack("c",0x80); # this is a hard disk

	close(BIN);
}

# and copy IO.SYS and MSDOS.SYS over, assuming that mkdosfs has left the root directory completely empty
# so that our copy operation puts them FIRST in the root directory.
if ($ver eq "3.2epson") {
	# IBMBIO.COM
	unlink("tmp.sys");
	system("mcopy -i tmp.dsk ::IBMBIO.COM tmp.sys") == 0 || die;
	system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::IBMBIO.COM") == 0 || die;
	system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::IBMBIO.COM") == 0 || die;
	unlink("tmp.sys");
	# IBMDOS.COM
	unlink("tmp.sys");
	system("mcopy -i tmp.dsk ::IBMDOS.COM tmp.sys") == 0 || die;
	system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::IBMDOS.COM") == 0 || die;
	system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::IBMDOS.COM") == 0 || die;
	unlink("tmp.sys");
}
else {
	unlink("tmp.sys");
	system("mcopy -i tmp.dsk ::IO.SYS tmp.sys") == 0 || die;
	system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::IO.SYS") == 0 || die;
	system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::IO.SYS") == 0 || die;
	unlink("tmp.sys");

	unlink("tmp.sys");
	system("mcopy -i tmp.dsk ::MSDOS.SYS tmp.sys") == 0 || die;
	system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::MSDOS.SYS") == 0 || die;
	system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::MSDOS.SYS") == 0 || die;
	unlink("tmp.sys");

	if ($ver eq "6.22") {
		unlink("tmp.sys");
		system("mcopy -i tmp.dsk ::DRVSPACE.BIN tmp.sys") == 0 || die;
		system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::DRVSPACE.BIN") == 0 || die;
		system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::DRVSPACE.BIN") == 0 || die;
		unlink("tmp.sys");
	}
	elsif ($ver eq "6.20") {
		unlink("tmp.sys");
		system("mcopy -i tmp.dsk ::DBLSPACE.BIN tmp.sys") == 0 || die;
		system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::DBLSPACE.BIN") == 0 || die;
		system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::DBLSPACE.BIN") == 0 || die;
		unlink("tmp.sys");
	}
}

unlink("tmp.sys");
system("mcopy -i tmp.dsk ::COMMAND.COM tmp.sys") == 0 || die;
system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::COMMAND.COM") == 0 || die;
system("mattrib -a -r -s -i $diskbase\@\@$part_offset ::COMMAND.COM") == 0 || die;
unlink("tmp.sys");

# create DOS subdirectory
system("mmd -i $diskbase\@\@$part_offset DOS") == 0 || die;
system("rm -Rfv dos.tmp; mkdir -p dos.tmp") == 0 || die;

# copy the other contents of the floppy (disk 1) to the DOS subdirectory
system("mcopy -b -Q -n -m -v -s -i tmp.dsk ::. dos.tmp/") == 0 || die;
unlink("tmp.dsk");

# copy the other contents of the floppy (disk 2) to the DOS subdirectory
if ($disk2 ne '') {
	print "Unpacking disk 2:\n";
	system("xz -c -d $rel/web.cache/$disk2 >tmp.dsk") == 0 || die;
	system("mcopy -b -Q -n -m -v -s -i tmp.dsk ::. dos.tmp/") == 0 || die;
	unlink("tmp.dsk");
}

# copy the other contents of the floppy (disk 3) to the DOS subdirectory
if ($disk3 ne '') {
	print "Unpacking disk 3:\n";
	system("xz -c -d $rel/web.cache/$disk3 >tmp.dsk") == 0 || die;
	system("mcopy -b -Q -n -m -v -s -i tmp.dsk ::. dos.tmp/") == 0 || die;
	unlink("tmp.dsk");
}

# and disk 4
if ($disk4 ne '') {
	my $ex = '';

	if ($ver eq "6.20") { # the supplementary disk
		$ex = "supplmnt/";
		mkdir "dos.tmp/$ex";
	}

	print "Unpacking disk 4:\n";
	system("xz -c -d $rel/web.cache/$disk4 >tmp.dsk") == 0 || die;
	system("mcopy -b -Q -n -m -v -s -i tmp.dsk ::. dos.tmp/$ex") == 0 || die;
	unlink("tmp.dsk");
}

# MS-DOS 3.3 NEC: the files on disk are not the complete set. we need to download another
# disk image with a more complete set to make a complete system. we do this NOW so that
# if the file already exists from the NEC disks it's not overwritten.
if ($ver eq "3.3nec") {
	system("rm -Rfv dos.tmp/x; mkdir dos.tmp/x") == 0 || die;

	system("../../download-item.pl --rel $rel --as msdos.330nec.ref1.disk.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/3.3/1.44MB/disk1.ima.xz")) == 0 || die;
	system("xz -c -d $rel/web.cache/msdos.330nec.ref1.disk.xz >tmp.dsk") == 0 || die;
	system("mcopy -b -Q -m -v -s -i tmp.dsk ::. dos.tmp/x/") == 0 || die;
	unlink("tmp.dsk");

	system("../../download-item.pl --rel $rel --as msdos.330nec.ref2.disk.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/3.3/1.44MB/disk2.ima.xz")) == 0 || die;
	system("xz -c -d $rel/web.cache/msdos.330nec.ref2.disk.xz >tmp.dsk") == 0 || die;
	system("mcopy -b -Q -m -v -s -i tmp.dsk ::. dos.tmp/x/") == 0 || die;
	unlink("tmp.dsk");

	system("mv -vn dos.tmp/x/* dos.tmp/") == 0 || die;
	system("rm -Rfv dos.tmp/x") == 0 || die;
}
# MS-DOS 3.3: we need FORMAT.COM and FDISK.COM to cover for the corrupt versions
# on the copy I have of MS-DOS 3.3
elsif ($ver eq "3.3") {
	# same problem a 3.3 NEC: FORMAT.COM and FDISK.COM are corrupt
	system("rm -Rfv dos.tmp/x; mkdir dos.tmp/x") == 0 || die;

	system("../../download-item.pl --rel $rel --as msdos.330nec.boot.disk.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/3.3 NEC Corporation/1.44MB/bootdisk.img.xz")) == 0 || die;
	system("xz -c -d $rel/web.cache/msdos.330nec.boot.disk.xz >tmp.dsk") == 0 || die;
	system("mcopy -b -Q -m -v -s -i tmp.dsk ::. dos.tmp/x/") == 0 || die;
	unlink("tmp.dsk");

	unlink("dos.tmp/x/IO.SYS");
	unlink("dos.tmp/x/MSDOS.SYS");
	unlink("dos.tmp/x/COMMAND.COM");
	unlink("dos.tmp/x/SYS.COM");
	# what remains is FORMAT.COM and FDISK.COM

	system("mv -v dos.tmp/x/* dos.tmp/") == 0 || die;
	system("rm -Rfv dos.tmp/x") == 0 || die;

}

# unpack the compressed files
unpack_dos_tmp();

# HACK: The copy of MS-DOS 3.3 (and the variants) that I have appear to have corrupted files.
#       That's the only explanation I can think of for some files like LABEL.COM having nothing
#       but 'rrrrrrrrrrrrrrrrrrrrrrrrrru7as7w6r7qwr' ASCII gibberish in them, and crashing/hanging
#       when you run them.
if ($ver eq "3.3nec" || $ver eq "3.3") {
	unlink("dos.tmp/LABEL.COM");		# LABEL.COM is corrupt
	unlink("dos.tmp/LINK.EXE");		# LINK.EXE is corrupt
	unlink("dos.tmp/GRAFTABL.COM");		# GRAFTABL.COM is corrupt
	unlink("dos.tmp/KEYB.COM");		# KEYB.COM is corrupt
	unlink("dos.tmp/LCD.CPI");		# LCD.CPI is corrupt, I *think*
	unlink("dos.tmp/JOIN.EXE");		# JOIN.EXE is corrupt
	unlink("dos.tmp/FIND.EXE");		# FIND.EXE is corrupt
	unlink("dos.tmp/GRAPHICS.COM");		# GRAPHICS.COM is corrupt
	unlink("dos.tmp/PRINTER.SYS");		# PRINTER.SYS is corrupt
	unlink("dos.tmp/RAMDRIVE.SYS");		# RAMDRIVE.SYS is corrupt
}

# if DOSSHELL was provided by the supplementary disk, then move it into the main shell
if ( -d "dos.tmp/supplmnt" ) {
	if ($ver eq "6.20") { # the supplementary disk has DOSSHELL and it's swapper and other goodies
		# DOSSHELL, the swapper, and it's video "drivers"
		system("mv -vn dos.tmp/supplmnt/DOSSHELL.* dos.tmp/");
		system("mv -vn dos.tmp/supplmnt/DOSSWAP.EXE dos.tmp/");
		system("mv -vn dos.tmp/supplmnt/*.GRB dos.tmp/");
		system("mv -vn dos.tmp/supplmnt/*.VID dos.tmp/");
		system("mv -vn dos.tmp/supplmnt/*.INI dos.tmp/");

		system("mv -vn dos.tmp/supplmnt/EXE2BIN.EXE dos.tmp/");
	}
}

if ($ver eq "4.01") {
	# the MS-DOS 4.01 disks in my collection have an extra INFO.WAR file that needs to be deleted
	unlink("dos.tmp/info.war");
	unlink("dos.tmp/INFO.WAR");

	# we don't use the CONFIG.SYS and AUTOEXEC.BAT files either
	unlink("dos.tmp/AUTOEXEC.BAT");
	unlink("dos.tmp/CONFIG.SYS");

	# SELECT appears to be the install program, which is a) useless because we installed and
	# b) very crashy in DOSBox, meaning that "SELECT MENU" results in a blue screen with a
	# message followed quickly by garbled text and junk on the screen
	unlink("dos.tmp/SELECT.EXE");
	unlink("dos.tmp/SELECT.PRT");

	# "DOSSHELL" in v4.01 is a batch file to run SHELLC with magic incantations
	system("cp -vn dosshell.bat.v4.01 dos.tmp/DOSSHELL.BAT") == 0 || die;

	# TODO: GWBASIC.EXE (under DOSBox) prints "You cannot SHELL to BASIC". WTF?
	#  - It's not GWBASIC.EXE itself: unmodified between install disk and hard disk copy
	#  - It's not the presence of C:\COMMAND.COM
}

# remove SETUP.EXE
unlink("dos.tmp/SETUP.EXE");
unlink("dos.tmp/DOSSETUP.INI");

# http://support.microsoft.com/kb/95631
# MS-DOS 5.0-6.22: "Configure" DOSSHELL.EXE's video driver by copying VID GRB and INI files
if ($dosshell_vid ne '' && $dosshell_vid ne 'none') {
	if ($ver =~ m/^[56]\./) {
		my $vid = '',$grb = '',$ini = '';

		if ($dosshell_vid eq "vga") {
			$vid = "VGA.VID";	$grb = "VGA.GRB";	$ini = "EGA.INI";
		}
		elsif ($dosshell_vid eq "vgamono") {
			$vid = "VGA.VID";	$grb = "VGAMONO.GRB";	$ini = "MONO.INI";
		}
		elsif ($dosshell_vid eq "ega") {
			$vid = "EGA.VID";	$grb = "EGA.GRB";	$ini = "EGA.INI";
		}
		elsif ($dosshell_vid eq "egamono") {
			$vid = "EGA.VID";	$grb = "EGAMONO.GRB";	$ini = "MONO.INI";
		}
		elsif ($dosshell_vid eq "8514") {
			$vid = "8514.VID";	$grb = "VGA.GRB";	$ini = "EGA.INI";
		}
		elsif ($dosshell_vid eq "8514mono") {
			$vid = "8514.VID";	$grb = "VGAMONO.GRB";	$ini = "MONO.INI";
		}
		elsif ($dosshell_vid eq "herc") {
			$vid = "HERC.VID";	$grb = "HERC.GRB";	$ini = "MONO.INI";
		}
		elsif ($dosshell_vid eq "cga") {
			$vid = "CGA.VID";	$grb = "CGA.GRB";	$ini = "CGA.INI";
		}
		elsif ($dosshell_vid eq "mono") {
			$vid = undef;		$grb = "MONO.GRB";	$ini = "MONO.INI";
		}
		elsif ($dosshell_vid eq "none") {
			$vid = undef;		$grb = undef;		$ini = undef;
		}
		else {
			print "ERROR: Unknown DOSSHELL driver $dosshell_vid\n";
			exit 1;
		}

		# configure the VID
		if (defined($vid) && -f "dos.tmp/$vid")
			{ system("cp -v dos.tmp/$vid dos.tmp/DOSSHELL.VID") == 0 || die; }
		else
			{ unlink("dos.tmp/DOSSHELL.VID"); }

		# configure the GRB
		if (defined($grb) && -f "dos.tmp/$grb")
			{ system("cp -v dos.tmp/$grb dos.tmp/DOSSHELL.GRB") == 0 || die; }
		else
			{ unlink("dos.tmp/DOSSHELL.GRB"); }

		# configure the INI
		if (defined($ini) && -f "dos.tmp/$ini")
			{ system("cp -v dos.tmp/$ini dos.tmp/DOSSHELL.INI") == 0 || die; }
	}
}

# copy them back into the hard disk image
system("mcopy -b -Q -n -m -v -s -i $diskbase\@\@$part_offset dos.tmp/. ::DOS/") == 0 || die;

# remove dos.tmp
system("rm -Rfv dos.tmp; mkdir -p dos.tmp") == 0 || die;

# next, add the OAK IDE CD-ROM driver
system("mcopy -i $diskbase\@\@$part_offset oakcdrom.sys ::DOS/OAKCDROM.SYS") == 0 || die;

# Pre-6.0: add MSCDEX.EXE
if ($ver =~ m/^[45]\./ || $ver eq "3.3nec" || $ver eq "3.3" || $ver eq "3.2epson") { # v4.x and v5.x
	system("mcopy -i $diskbase\@\@$part_offset mscdex.exe.v2.10 ::DOS/MSCDEX.EXE") == 0 || die;
}

# and the default CONFIG.SYS and AUTOEXEC.BAT files
system("mcopy -i $diskbase\@\@$part_offset $config_sys_file ::CONFIG.SYS") == 0 || die;
system("mcopy -i $diskbase\@\@$part_offset $autoexec_bat_file ::AUTOEXEC.BAT") == 0 || die;

# make a zero track and cat them together to make a full disk image
system("dd conv=notrunc,nocreat if=mbr.bin of=$diskbase bs=512 count=1") == 0 || die;

# and then edit the partition table directly. we WOULD use fdisk, but fdisk has this
# terrible fetish for forcing your first partition at least 2048 sectors away from the start
# of the disk, which is an utter waste of disk space. Fuck you fdisk.
open(BIN,"+<","$diskbase") || die
binmode(BIN);
seek(BIN,0x1BE,0);
print BIN pack("cccccccc",
	0x80, # status/physical drive
	0x01, # head 1
	0x01 | (0 << 6), # sector 1 cylinder 0 (high 2 bits)
	0x00, # cylinder 0 (low 8 bits)
	$part_type, # partition type (0x06 = MS-DOS FAT16 >= 32MB)
	$heads-1, # end head
	$sects | ((($cyls - 1) >> 8) << 6), # end sector/cylinder
	($cyls - 1) & 0xFF); # end cylinder
print BIN pack("VV",$sects,($sects*$cyls*$heads)-$sects);
close(BIN);

# make VDI for VirtualBox, QEMU, etc
system("qemu-img convert -f raw -O vdi $diskbase $diskbase.vdi") == 0 || die;

