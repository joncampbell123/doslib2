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
#             8.0winme   MS-DOS 8.0 (DOS-only portion of Windows ME--an incredible feat if you can believe it)
#             7.1win98se MS-DOS 7.1 (DOS-only portion of Windows 98 SE)
#             7.1win98   MS-DOS 7.1 (DOS-only portion of Windows 98)
#             7.1osr2    MS-DOS 7.1 (DOS-only portion of Windows 95 OSR2)
#             7.0sp1     MS-DOS 7.0 (DOS-only portion of Windows 95 SP1)
#             7.0        MS-DOS 7.0 (DOS-only portion of Windows 95)
#             6.22       MS-DOS 6.22 (default)
#             6.21       MS-DOS 6.21
#             6.20       MS-DOS 6.20
#             6.0        MS-DOS 6.0
#             5.0        MS-DOS 5.0
#             4.01       MS-DOS 4.01
#             3.3nec     MS-DOS 3.3 [NEC version]
#             3.3        MS-DOS 3.3
#             3.2epson   MS-DOS 3.2 [SEIKO EPSON version]
#             2.2td      MS-DOS 2.2 [Weird TeleDisk version, non-bootable by itself, so we combine with 2.1 files]
#             2.1        MS-DOS 2.1 (actually PC-DOS)
#
#     Installed image is English language (US) version.
#
#     --geomemtry C/H/S             allows you to specify a custom disk geometry

my $dosshell_vid = "vga";
my $target_size = 0;
my $ver = "6.22";
my $do_supp = 0;
my $fat = -1;
my $config_sys_file;
my $autoexec_bat_file;

my $part_type = 0x06;
my $cyls = 1020,$act_cyls;
my $heads = 16;
my $sects = 63;
my $user_chs_override = 0;
my $clustersize = -1;
my $root_len = -1;
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
			my $tc;
			($tc,$heads,$sects) = split(/[-\\\/]+/,$ARGV[$i++]);
			$heads = $heads + 0;
			$sects = $sects + 0;
			$user_chs_override = 1;
			$tc = $tc + 0;
			$cyls = $tc if $tc >= 1;

			die "Invalid geometry C/H/S $cyls/$heads/$sects" if $cyls < 1 || $cyls > 8192 ||
				$heads < 1 || $heads > 255 ||
				$sects < 1 || $sects > 63;

			$target_size = $cyls * $heads * $sects * 512 if $tc >= 1;
		}
		elsif ($a eq "help" || $a eq "h") {
			print "   --size <n>                Size of hard drive in MB to create.\n";
			print "                               Note that very early versions of MS-DOS have limits\n";
			print "                               on disk capacity. If the size you specify is too large\n";
			print "                               then this script will limit the partition in the image\n";
			print "                               to the maximum supported by DOS and the rest of the image\n";
			print "                               will remain unused by DOS.\n";
			print "   --supp                    install Supplementary Disk 4, if available (MS-DOS 6.22)\n";
			print "   --geometry C/H/S          Force hard disk geometry (default: S=63 H=16 C=however many tracks)\n";
			print "                               Note that MS-DOS 3.x and earler have known issues with\n";
			print "                               certain geometry values, such as MS-DOS 3.0 and hard drives\n";
			print "                               with more than about 40 sectors/track. Unless you know what\n";
			print "                               you're doing or you're using a more recent version, do not\n";
			print "                               use this option.\n";
			print "   --dosshell-vid <n>        pre-configure DOSSHELL.EXE video.\n";
			print "        none                   Don't configure any driver\n";
			print "        vga                    VGA color (default)\n";
			print "        vgamono                VGA mono\n";
			print "        ega                    EGA color\n";
			print "        egamono                EGA mono\n";
			print "        herc                   MDA/Hercules\n";
			print "        cga                    CGA\n";
			print "        mono                   Mono text\n";
			print "        8514                   8514 color\n";
			print "        8514mono               8514 mono\n";
			print "   --ver <n>                 setup a specific version of DOS\n";
			print "        8.0winme               MS-DOS 8.0 (DOS-only portion of Windows ME)\n";
			print "        7.1win98se             MS-DOS 7.1 (DOS-only portion of Windows 98 SE)\n";
			print "        7.1win98               MS-DOS 7.1 (DOS-only portion of Windows 98)\n";
			print "        7.1osr2                MS-DOS 7.1 (DOS-only portion of Windows 95 OSR2)\n";
			print "        7.0sp1                 MS-DOS 7.0 (DOS-only portion of Windows 95 SP1)\n";
			print "        7.0                    MS-DOS 7.0 (DOS-only portion of Windows 95)\n";
			print "        6.22                   MS-DOS 6.22 (default)\n";
			print "        6.21                   MS-DOS 6.21\n";
			print "        6.20                   MS-DOS 6.20\n";
			print "        6.0                    MS-DOS 6.0\n";
			print "        5.0                    MS-DOS 5.0\n";
			print "        4.01                   MS-DOS 4.01\n";
			print "        3.3nec                 MS-DOS 3.3 [NEC version]\n";
			print "        3.3                    MS-DOS 3.3\n";
			print "        3.2epson               MS-DOS 3.2 [SEIKO EPSON version]\n";
			print "        2.2td                  MS-DOS 2.2 [Weird TeleDisk version, non-bootable by itself, so we combine with 2.1 files]\n";
			print "        2.1                    MS-DOS 2.1 (actually PC-DOS)\n";
			exit 1;
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

if ($ver eq "8.0winme") {
	$diskbase = "$rel/build/msdos80winmehdd";

	$config_sys_file = "config.sys.init.v80winme";
	$autoexec_bat_file = "autoexec.bat.init.v80winme";

	$disk1 = "msdos.80winme.boot.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/8.0/Windows ME EBD Boot and pure DOS setup/WinME EBD Boot (DOS8.0) + Essentials.ima.xz";

	# default size
	$target_size = (4*1024*1024*1024) if $target_size <= 0;
}
elsif ($ver eq "7.1win98se") {
	$diskbase = "$rel/build/msdos710win98sehdd";

	$config_sys_file = "config.sys.init.v710win98se";
	$autoexec_bat_file = "autoexec.bat.init.v710win98se";

	$disk1 = "msdos.710win98se.boot.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/7.10 (Windows 98 SE, DOS mode only)/files/bootdisk.dsk.xz";

	# default size
	$target_size = (4*1024*1024*1024) if $target_size <= 0;

	# TODO: The Windows 98 CD-ROM has an "oldmsdos" folder with some of the classic DOS utilities there.
	#       Add code here to download those files if --supp is given as the "supplementary" set of files.
}
elsif ($ver eq "7.1win98") {
	$diskbase = "$rel/build/msdos710win98hdd";

	$config_sys_file = "config.sys.init.v710win98";
	$autoexec_bat_file = "autoexec.bat.init.v710win98";

	$disk1 = "msdos.710win98.boot.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/7.10 (Windows 98, DOS mode only)/files/bootdisk.dsk.xz";

	# default size
	$target_size = (4*1024*1024*1024) if $target_size <= 0;

	# TODO: The Windows 95 CD-ROM has an "oldmsdos" folder with some of the classic DOS utilities there.
	#       Add code here to download those files if --supp is given as the "supplementary" set of files.
}
elsif ($ver eq "7.1osr2") {
	$diskbase = "$rel/build/msdos710osr2hdd";

	$config_sys_file = "config.sys.init.v710osr2";
	$autoexec_bat_file = "autoexec.bat.init.v710osr2";

	$disk1 = "msdos.710osr2.boot.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/7.10 (Windows 95 OSR2, DOS mode only)/files/bootdisk.dsk.xz";

	# default size
	$target_size = (2*1024*1024*1024) if $target_size <= 0;

	# TODO: The Windows 95 CD-ROM has an "oldmsdos" folder with some of the classic DOS utilities there.
	#       Add code here to download those files if --supp is given as the "supplementary" set of files.
}
elsif ($ver eq "7.0sp1") {
	$diskbase = "$rel/build/msdos70sp1hdd";

	$config_sys_file = "config.sys.init.v70sp1";
	$autoexec_bat_file = "autoexec.bat.init.v70sp1";

	$disk1 = "msdos.70sp1.boot.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/7.0 (Windows 95 SP1, DOS mode only)/files/bootdisk.dsk.xz";

	# default size
	$target_size = (2*1024*1024*1024) if $target_size <= 0;

	# TODO: The Windows 95 CD-ROM has an "oldmsdos" folder with some of the classic DOS utilities there.
	#       Add code here to download those files if --supp is given as the "supplementary" set of files.
}
elsif ($ver eq "7.0") {
	$diskbase = "$rel/build/msdos70hdd";

	$config_sys_file = "config.sys.init.v70";
	$autoexec_bat_file = "autoexec.bat.init.v70";

	$disk1 = "msdos.70.boot.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/7.0 (Windows 95, DOS mode only)/files/bootdisk.dsk.xz";

	# default size
	$target_size = (1*1024*1024*1024) if $target_size <= 0;

	# TODO: The Windows 95 CD-ROM has an "oldmsdos" folder with some of the classic DOS utilities there.
	#       Add code here to download those files if --supp is given as the "supplementary" set of files.
}
elsif ($ver eq "6.22") {
	$diskbase = "$rel/build/msdos622hdd";

	$config_sys_file = "config.sys.init";
	$autoexec_bat_file = "autoexec.bat.init";

	$disk1 = "msdos.622.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 1.img.xz";

	$disk2 = "msdos.622.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 2.img.xz";

	$disk3 = "msdos.622.install.3.disk.xz";
	$disk3_url = "Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 3.img.xz";

	# default size
	$target_size = (800*1024*1024) if $target_size <= 0;

	if ($do_supp) {
		$disk4 = "msdos.622.install.4.disk.xz";
		$disk4_url = "Software/DOS/Microsoft MS-DOS/6.22/1.44MB[2]/disc4.ima.xz";
	}
}
elsif ($ver eq "6.21") {
	$diskbase = "$rel/build/msdos621hdd";

	$config_sys_file = "config.sys.init";
	$autoexec_bat_file = "autoexec.bat.init";

	# default size
	$target_size = (600*1024*1024) if $target_size <= 0;

	$disk1 = "msdos.621.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/6.21/1.44MB/DISK1.IMA.xz";

	$disk2 = "msdos.621.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/6.21/1.44MB/DISK2.IMA.xz";

	$disk3 = "msdos.621.install.3.disk.xz";
	$disk3_url = "Software/DOS/Microsoft MS-DOS/6.21/1.44MB/DISK3.IMA.xz";
}
elsif ($ver eq "6.20") {
	$diskbase = "$rel/build/msdos620hdd";

	# default size
	$target_size = (520*1024*1024) if $target_size <= 0;

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

	# default size
	$target_size = (504*1024*1024) if $target_size <= 0;

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

	# default size
	$target_size = (250*1024*1024) if $target_size <= 0;

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

	# default size
	$target_size = (120*1024*1024) if $target_size <= 0;

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

	# default size
	$target_size = (24*1024*1024) if $target_size <= 0;

	$config_sys_file = "config.sys.init.v330nec";
	$autoexec_bat_file = "autoexec.bat.init.v330nec";

	$disk1 = "msdos.330nec.boot.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/3.3 NEC Corporation/1.44MB/bootdisk.img.xz";
}
elsif ($ver eq "3.3") {
	$part_type = 0x04; # FAT16 <= 32MB

	$diskbase = "$rel/build/msdos330hdd";

	# default size
	$target_size = (24*1024*1024) if $target_size <= 0;

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

	# default size
	$target_size = (24*1024*1024) if $target_size <= 0;

	$config_sys_file = "config.sys.init.v320";
	$autoexec_bat_file = "autoexec.bat.init.v320";

	$disk1 = "msdos.320epson.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/3.2 Seiko Epson/360KB/DISK1.IMA.xz";

	$disk2 = "msdos.320epson.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/3.2 Seiko Epson/360KB/DISK2.IMA.xz";

	$disk3 = "msdos.320epson.install.3.disk.xz";
	$disk3_url = "Software/DOS/Microsoft MS-DOS/3.2 Seiko Epson/360KB/DISK3.IMA.xz";
}
elsif ($ver eq "2.2td") {
	$part_type = 0x01; # FAT12 <= 32MB

	# default size
	$target_size = (20*1024*1024) if $target_size <= 0;

	$diskbase = "$rel/build/msdos220tdhdd";

	$config_sys_file = "config.sys.init.v220td";
	$autoexec_bat_file = "autoexec.bat.init.v220td";

	$disk1 = "msdos.210.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/2.1/180KB/DISK1.IMA.xz";

	$disk2 = "msdos.210.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/2.1/180KB/DISK2.IMA.xz";
}
elsif ($ver eq "2.1") {
	$part_type = 0x01; # FAT12 <= 32MB

	# default size
	$target_size = (20*1024*1024) if $target_size <= 0;

	$diskbase = "$rel/build/msdos210hdd";

	$config_sys_file = "config.sys.init.v210";
	$autoexec_bat_file = "autoexec.bat.init.v210";

	$disk1 = "msdos.210.install.1.disk.xz";
	$disk1_url = "Software/DOS/Microsoft MS-DOS/2.1/180KB/DISK1.IMA.xz";

	$disk2 = "msdos.210.install.2.disk.xz";
	$disk2_url = "Software/DOS/Microsoft MS-DOS/2.1/180KB/DISK2.IMA.xz";
}
else {
	die "Unknown MS-DOS version";
}

die if $target_size == 0;

if ($ver eq "6.22" || $ver eq "6.21" || $ver eq "6.20" || $ver eq "6.0" || $ver eq "7.0" || $ver eq "7.0sp1" || $ver eq "7.1osr2" || $ver eq "7.1win98" || $ver eq "7.1win98se" || $ver eq "8.0winme") {
	# minimum required disk size for this install: 8MB
	# silent change the size if the user specified anything less.
	# if they really want to force it, they can specify a custom geometry.
	if ($target_size < (8*1024*1024)) {
		$target_size = (8*1024*1024);
	}
}
elsif ($ver eq "5.0") {
	# minimum required disk size for this install: 3MB
	# silent change the size if the user specified anything less.
	# if they really want to force it, they can specify a custom geometry.
	if ($target_size < (3*1024*1024)) {
		$target_size = (3*1024*1024);
	}
}
elsif ($ver eq "4.01") {
	# minimum required disk size for this install: 2MB
	# silent change the size if the user specified anything less.
	# if they really want to force it, they can specify a custom geometry.
	if ($target_size < (2*1024*1024)) {
		$target_size = (2*1024*1024);
	}
}
elsif ($ver eq "2.1" || $ver eq "2.2td") {
	# MS-DOS 2.x doesn't seem to boot properly with images less than 2MB
	if ($target_size < (2*1024*1024)) {
		$target_size = (2*1024*1024);
	}
}
else {
	if ($target_size < (1*1024*1024)) {
		$target_size = (1*1024*1024);
	}
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

# geometry restrictions
if ($ver eq "3.2epson" || $ver eq "2.1" || $ver eq "2.2td") {
	if ($user_chs_override == 0) {
		$sects = 8;
		$cyls = int(($target_size / 512 / $heads / $sects) + 0.5);
		# MS-DOS 3.2 cannot handle >= 1024 cylinders OR > 16 heads. Period.
		# Geometry hacks familiar to later versions don't work. Also keep
		# sectors per track up but no over 40.
		while ($sects < 40 && $cyls > 100) {
			$sects++;
			$cyls = int(($target_size / 512 / $heads / $sects) + 0.5);
		}
	}
}
else {
	if ($user_chs_override == 0) {
# try to pick more realistic geometries for small hard disk images
		$sects = 8;
		$cyls = int(($target_size / 512 / $heads / $sects) + 0.5);
		while ($sects < 63 && $cyls > 100) {
			$sects++;
			$cyls = int(($target_size / 512 / $heads / $sects) + 0.5);
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
	}
}

if ($user_chs_override == 0) {
	$cyls = int(($target_size / 512 / $heads / $sects) + 0.5);
	$cyls = 1 if $cyls == 0;
}
else {
	$target_size = $cyls * $heads * $sects * 512 if $tc >= 1;
}
die if $cyls != int($cyls);
$act_cyls = $cyls;

if ($ver eq "3.2epson" || $ver eq "2.1" || $ver eq "2.2td") {
	# See http://www.os2museum.com/wp/?p=685 for more information.
	# MS-DOS v3.2 and 2.xx have bugs in the bootloader related to
	# hard drives having more than about 26KB (52 sectors) per track.
	# It likes to load a track at a time, which was fine back when
	# hard drives had 17 sectors/track, but can end up overwriting
	# itself or trashing it's own stack on modern 63 sector/track disks.
	#
	# Our fix: Unless the user has specifically given us a geometry,
	# set the sectors/track to a smaller value.
	if ($sects > 40) { # FIXME: What's the upper limit?
		print "WARNING: 40 or more sectors/track with MS-DOS 2.x/3.2 is not reliable\n";
		print "For more information visit: http://www.os2museum.com/wp/?p=685\n";
		sleep 1;
	}
}

$x = 512 * $cyls * $heads * $sects;
if ($ver eq "7.1osr2" || $ver eq "7.1win98" || $ver eq "7.1win98se" || $ver eq "8.0winme") {
	# Windows 95 OSR2 and higher DO support partitions larger than 2GB
	# IF formatted as FAT32.
	if ($x >= (7000*1024*1024)) {
		$part_type = 0x0C; # FAT32 (LBA)
		$fat = 32;
	}
	elsif ($x >= (2048*1024*1024)) {
		$part_type = 0x0B; # FAT32 (CHS)
		$fat = 32;
	}
}
else {
	if ($x >= (2048*1024*1024)) {
		# limit the partition to keep within MS-DOS 6.22's capabilities.
		# A partition larger than 2GB is not supported.
		$x = (2047*1024*1024);
		$cyls = int(($x / 512 / $heads / $sects) + 0.5);
	}
}

if ($ver eq "3.3nec" || $ver eq "3.3") {
	# MS-DOS v3.3 and earlier cannot support >= 32MB partitions.
	if ($x >= (32*1024*1024)) {
		$x = (31*1024*1024);
		$cyls = int(($x / 512 / $heads / $sects) + 0.5);
	}
}
elsif ($ver eq "3.2epson") {
	# MS-DOS v3.2 and earlier cannot support >= 32MB partitions.
	if ($x >= (32*1024*1024)) {
		$x = (31*1024*1024);
		$cyls = int(($x / 512 / $heads / $sects) + 0.5);
	}
}
elsif ($ver eq "2.1" || $ver eq "2.2td") {
	# MS-DOS v2.1 and earlier cannot support >= 32MB partitions.
	# It also cannot support FAT16. Unfortunately, mtools has this
	# fetish for FAT16 whenever the partition is 16MB or larger.
	# There's no way to force FAT12 formatting.
	if ($x >= (16*1024*1024)) {
		$x = (15*1024*1024);
		$cyls = int(($x / 512 / $heads / $sects) + 0.5);
	}
}

if ($ver eq "7.1osr2" || $ver eq "7.1win98" || $ver eq "7.1win98se" || $ver eq "8.0winme") {
}
else {
	# cap cylinders at 1024
	$cyls = 1024 if $cyls > 1024;
}

my $part_offset_sects = $sects;
my $part_offset = 0x200 * $part_offset_sects;

if ($ver eq "3.3nec" || $ver eq "3.3") {
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
elsif ($ver eq "3.2epson") {
	$clustersize = 4;

	# At 15MB or less, force mformat to do FAT12. It'd be nice if like mkdosfs they
	# offered something like --fat=12 to explicitly say so, but they don't. Our only
	# hope then is to force the size of the FAT table.
	$x = 512 * $cyls * $heads * $sects;
	if ($x < (16*1024*1024)) {
		$part_type = 0x01; # FAT12 <= 32MB

		# how long does the FAT table need to be?
		# doing this calculation is REQUIRED to force mtools to format the partition
		# as FAT12 rather than trying to shoehorn in FAT16, which MS-DOS 3.3 NEC edition
		# won't accept.
		$fat_len = (($x-$part_offset_sects)/512/$clustersize);
		$fat_len = ($fat_len / 2) * 3;
		$fat_len = int(($fat_len+511)/512);
	}
}
elsif ($ver eq "2.1" || $ver eq "2.2td") {
	$clustersize = 4;

	# Always do FAT12. FAT16 is not supported by v2.1
	$x = 512 * $cyls * $heads * $sects;
	$part_type = 0x01; # FAT12 <= 32MB

	# MS-DOS v2.1 is VERY VERY picky.
	$root_len = 16;		# root directory MUST be 256 entries
	if ($x >= (5*1024*1024)) {
		$root_len = 32;
		$clustersize = 8;
	}
}

die "$cyls is non-integer" if $cyls != int($cyls);
die if $cyls > $act_cyls;
if ($ver eq "7.1osr2" || $ver eq "7.1win98" || $ver eq "7.1win98se" || $ver eq "8.0winme") {
}
else {
	die if $cyls >= 1024;
}

print "Chosen disk geometry C/H/S: $cyls/$heads/$sects (disk $act_cyls/$heads/$sects)\n";

sub unpack_dos_tmp() {
# unpack the compressed files
	my @l = (
		"DRVSPACE.IN_","DRVSPACE.INF",	# NTS: This must be first, or else DRVSPACE.IN_ will be incorrectly installed as DRVSPACE.INI
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
	($root_len > 0 ? ("-r ".$root_len)." " : "").
	($fat == 32 ? "-F " : "").
	"-t $cyls -h $heads -s $sects -d 2 -i $diskbase\@\@$part_offset") == 0 || die;

# mtools fills in Windows 95 fields like creation time, which needs to be zeroed out.
# Older versions of MS-DOS leave a copy of the root directory at 0000:0500 which
# includes IO.SYS. GWBASIC/BASIC/BASICA uses byte 0000:050F as a "am I running" flag
# which if nonzero means yes. If we do not zero the bytes, the image in memory has
# a nonzero byte at 0000:050F and GWBASIC will ALWAYS say "you cannot SHELL to basic".
# 
# To do this, we need to locate the root directory.
#
# Note that by Windows 95/98/ME, Microsoft doesn't keep the root directory there anymore
# and leaves 0000:0500-0000:051F alone (presumably to zero) presumably to avoid this
# problem, so we don't need to do it for those versions. To keep things simple, skip
# this zeroing out for FAT32 (which makes the root directory an allocation chain anyway).
my $rootdirstart = 0;
my $rootdircount = 0;

if ($fat < 32) {
	# only for FAT12/FAT16
	open(BIN,"<","$diskbase") || die
	binmode(BIN);

	my $bpb;
	seek(BIN,$part_offset+11,0);
	read(BIN,$bpb,25); # only care for the BPB

	my $bypersec = unpack("v",substr($bpb,0,2));
	my $rsrvsec = unpack("v",substr($bpb,3,2));
	my $numfat = unpack("C",substr($bpb,5,1));
	my $rdirent = unpack("v",substr($bpb,6,2));
	my $fatsz = unpack("v",substr($bpb,11,2));

	if ($numfat >= 1 && $fatsz >= 1 && $numfat <= 2 && $rsrvsec >= 1 && $rsrvsec <= 16 && $rdirent > 0 && $rdirent < 2048) {
		$rootdircount = $rdirent;
		$rootdirstart = ($bypersec * ($rsrvsec + ($numfat * $fatsz))) + $part_offset;
	}

	close(BIN);
}

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

	# mystery value
	my $myval = 0x12;
	$myval = 0x0F if $ver eq "3.2epson";

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
		0x00,0x00,0x00,$myval,
	
		0x00,0x00,0x00,0x00,
		0x01,0x00);

	close(BIN);
}
elsif ($ver eq "2.1" || $ver eq "2.2td") {
	# copy the boot sector of the install disk, being careful not to overwrite the BPB written by mkdosfs
	system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=".($part_offset   )." skip=0 count=11") == 0 || die;
	system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=".($part_offset+32)." skip=32 count=".(512-32)) == 0 || die;

	# the disk table will need some fixup
	open(BIN,"+<","$diskbase") || die
	binmode(BIN);

	# total sector count fixup
	my $x = ($cyls * $heads * $sects) - $part_offset_sects;
	die "$x is too many sectors" if $x > 65535;
	seek(BIN,$part_offset+0x13,0); print BIN pack("v",$x);

	seek(BIN,$part_offset+0x18,0); print BIN pack("v",$sects); # let me tell you the TRUE sectors/track
	seek(BIN,$part_offset+0x1A,0); print BIN pack("v",$heads); # and heads
	seek(BIN,$part_offset+0x1C,0); print BIN pack("v",$sects); # and number of "hidden sectors" preceeding the partition
	seek(BIN,$part_offset+0x1E,0); print BIN pack("cc",0x80,0); # this is a hard disk
}
elsif ($fat == 32) {
	# Windows 9x FAT32
	if ($ver eq "7.1osr2") {
		system("dd conv=notrunc,nocreat if=fat32.boot.win95osr2.bin of=$diskbase bs=1 seek=".($part_offset   )." skip=0 count=11") == 0 || die;
		system("dd conv=notrunc,nocreat if=fat32.boot.win95osr2.bin of=$diskbase bs=1 seek=".($part_offset+90)." skip=90 count=".(512-90)) == 0 || die;

		system("dd conv=notrunc,nocreat if=fat32.boot.win95osr2.part2.bin of=$diskbase bs=1 seek=".($part_offset+(512*2))." skip=0 count=512") == 0 || die;
		system("dd conv=notrunc,nocreat if=fat32.boot.win95osr2.part2.bin of=$diskbase bs=1 seek=".($part_offset+(512*(2+6)))." skip=0 count=512") == 0 || die;
	}
	elsif ($ver eq "7.1win98") {
		system("dd conv=notrunc,nocreat if=fat32.boot.win98.bin of=$diskbase bs=1 seek=".($part_offset   )." skip=0 count=11") == 0 || die;
		system("dd conv=notrunc,nocreat if=fat32.boot.win98.bin of=$diskbase bs=1 seek=".($part_offset+90)." skip=90 count=".(512-90)) == 0 || die;

		system("dd conv=notrunc,nocreat if=fat32.boot.win98.part2.bin of=$diskbase bs=1 seek=".($part_offset+(512*2))." skip=0 count=512") == 0 || die;
		system("dd conv=notrunc,nocreat if=fat32.boot.win98.part2.bin of=$diskbase bs=1 seek=".($part_offset+(512*(2+6)))." skip=0 count=512") == 0 || die;
	}
	elsif ($ver eq "7.1win98se") {
		system("dd conv=notrunc,nocreat if=fat32.boot.win98se.bin of=$diskbase bs=1 seek=".($part_offset   )." skip=0 count=11") == 0 || die;
		system("dd conv=notrunc,nocreat if=fat32.boot.win98se.bin of=$diskbase bs=1 seek=".($part_offset+90)." skip=90 count=".(512-90)) == 0 || die;

		system("dd conv=notrunc,nocreat if=fat32.boot.win98se.part2.bin of=$diskbase bs=1 seek=".($part_offset+(512*2))." skip=0 count=512") == 0 || die;
		system("dd conv=notrunc,nocreat if=fat32.boot.win98se.part2.bin of=$diskbase bs=1 seek=".($part_offset+(512*(2+6)))." skip=0 count=512") == 0 || die;
	}
	elsif ($ver eq "8.0winme") {
		system("dd conv=notrunc,nocreat if=fat32.boot.winme.bin of=$diskbase bs=1 seek=".($part_offset   )." skip=0 count=11") == 0 || die;
		system("dd conv=notrunc,nocreat if=fat32.boot.winme.bin of=$diskbase bs=1 seek=".($part_offset+90)." skip=90 count=".(512-90)) == 0 || die;

		system("dd conv=notrunc,nocreat if=fat32.boot.winme.part2.bin of=$diskbase bs=1 seek=".($part_offset+(512*2))." skip=0 count=512") == 0 || die;
		system("dd conv=notrunc,nocreat if=fat32.boot.winme.part2.bin of=$diskbase bs=1 seek=".($part_offset+(512*(2+6)))." skip=0 count=512") == 0 || die;
	}
	else {
		die;
	}

	# the disk table will need some fixup
	open(BIN,"+<","$diskbase") || die
	binmode(BIN);

	# total sector count fixup
	my $x = ($cyls * $heads * $sects) - $part_offset_sects;
	seek(BIN,$part_offset+0x13,0); print BIN pack("v",0);
	seek(BIN,$part_offset+0x20,0); print BIN pack("V",$x);

	seek(BIN,$part_offset+0x18,0); print BIN pack("v",$sects); # let me tell you the TRUE sectors/track
	seek(BIN,$part_offset+0x1A,0); print BIN pack("v",$heads); # and heads
	seek(BIN,$part_offset+0x1C,0); print BIN pack("V",$sects); # and number of "hidden sectors" preceeding the partition
	seek(BIN,$part_offset+0x40,0); print BIN pack("c",0x80); # this is a hard disk

	# copy the sector we just modified to the backup copy at sector +6
	seek(BIN,$part_offset,0); read(BIN,$x,512);
	seek(BIN,$part_offset+(512*6),0); print BIN $x;

	# copy the FSInfo part as well
	seek(BIN,$part_offset+(512*1),0); read(BIN,$x,512);
	seek(BIN,$part_offset+(512*(6+1)),0); print BIN $x;

	close(BIN);
}
else {
	system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=".($part_offset   )." skip=0 count=11") == 0 || die;
	system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=".($part_offset+62)." skip=62 count=".(512-62)) == 0 || die;

	# the disk table will need some fixup
	open(BIN,"+<","$diskbase") || die
	binmode(BIN);

	# total sector count fixup
	my $x = ($cyls * $heads * $sects) - $part_offset_sects;
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
if ($ver eq "3.2epson" || $ver eq "2.1" || $ver eq "2.2td") {
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
elsif ($ver eq "8.0winme") {
	# FIXME: Is there anything we can do to the patched IO.SYS to change
	# "Starting Windows Emergency Boot Disk" to "Starting Windows Millenium Edition"?

	# FIXME: EMM386.EXE when added to CONFIG.SYS as DEVICE=EMM386.EXE does NOT WORK (it hangs). Why?
	system("mcopy -i $diskbase\@\@$part_offset winme.hdd.patched.io.sys ::IO.SYS") == 0 || die;
	system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::IO.SYS") == 0 || die;

	unlink("tmp.sys");
	system("mcopy -i tmp.dsk ::MSDOS.SYS tmp.sys") == 0 || die;
	system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::MSDOS.SYS") == 0 || die;
	system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::MSDOS.SYS") == 0 || die;
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

	if ($ver eq "6.22" || $ver eq "7.0" || $ver eq "7.0sp1") {
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

	if ($ver eq "6.20" || $ver eq "6.21" || $ver eq "6.22") { # the supplementary disk
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
# MS-DOS 2.2 TeleDisk: we installed MS-DOS 2.1 for the bootable part, now we
# need to copy the 2.2 parts in
elsif ($ver eq "2.2td") {
	system("rm -Rfv dos.tmp/x; mkdir dos.tmp/x") == 0 || die;

	system("../../download-item.pl --rel $rel --as msdos.220td.ref1.disk.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/2.2/360KB/dos22_disk1.ima.xz")) == 0 || die;
	system("xz -c -d $rel/web.cache/msdos.220td.ref1.disk.xz >tmp.dsk") == 0 || die;
	system("mcopy -b -Q -m -v -s -i tmp.dsk ::. dos.tmp/x/") == 0 || die;
	unlink("tmp.dsk");

	system("rm -v dos.tmp/COMP.COM; mv -vn dos.tmp/x/COMP.EXE dos.tmp/") == 0 || die;
	system("rm -v dos.tmp/x/COMMAND.COM") == 0 || die; # Fucking worthless COMMAND.COM
	system("mv -v dos.tmp/x/* dos.tmp/") == 0 || die;
	system("rmdir dos.tmp/x") == 0 || die;
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
	if ($ver eq "6.20" || $ver eq "6.21" || $ver eq "6.22") { # the supplementary disk has DOSSHELL and it's swapper and other goodies
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

# Windows 95: bring in the second set of files
if ($ver eq "7.0") {
	system("../../download-item.pl --rel $rel --as msdos.70.win95.dos.tar.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/7.0 (Windows 95, DOS mode only)/files/win95.dos.tar.xz")) == 0 || die;
	system("cd dos.tmp && tar -xJvf ../$rel/web.cache/msdos.70.win95.dos.tar.xz") == 0 || die;
}
elsif ($ver eq "7.0sp1") {
	system("../../download-item.pl --rel $rel --as msdos.70sp1.win95.dos.tar.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/7.0 (Windows 95 SP1, DOS mode only)/files/win95.dos.tar.xz")) == 0 || die;
	system("cd dos.tmp && tar -xJvf ../$rel/web.cache/msdos.70sp1.win95.dos.tar.xz") == 0 || die;
}
elsif ($ver eq "7.1osr2") {
	system("../../download-item.pl --rel $rel --as msdos.710osr2.win95.dos.tar.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/7.10 (Windows 95 OSR2, DOS mode only)/files/win95.dos.tar.xz")) == 0 || die;
	system("cd dos.tmp && tar -xJvf ../$rel/web.cache/msdos.710osr2.win95.dos.tar.xz") == 0 || die;
}
elsif ($ver eq "7.1win98") {
	system("../../download-item.pl --rel $rel --as msdos.710.win98.dos.tar.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/7.10 (Windows 98, DOS mode only)/files/win98.dos.tar.xz")) == 0 || die;
	system("cd dos.tmp && tar -xJvf ../$rel/web.cache/msdos.710.win98.dos.tar.xz") == 0 || die;
}
elsif ($ver eq "7.1win98se") {
	system("../../download-item.pl --rel $rel --as msdos.710.win98se.dos.tar.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/7.10 (Windows 98 SE, DOS mode only)/files/win98se.dos.tar.xz")) == 0 || die;
	system("cd dos.tmp && tar -xJvf ../$rel/web.cache/msdos.710.win98se.dos.tar.xz") == 0 || die;
}
elsif ($ver eq "8.0winme") {
	system("../../download-item.pl --rel $rel --as msdos.80.winme.dos.zip --url ".shellesc("Software/DOS/Microsoft MS-DOS/8.0/Windows ME EBD Boot and pure DOS setup/MSDOS 8.0 US.zip")) == 0 || die;
	system("cd dos.tmp && unzip ../$rel/web.cache/msdos.80.winme.dos.zip") == 0 || die;
	system("cd dos.tmp && mv -v DOS/* .") == 0 || die;
	system("cd dos.tmp && mv -v EBD/* .") == 0 || die;
	system("cd dos.tmp && mv -v WIN/* .") == 0 || die;
	system("cd dos.tmp && mv -v Drivers/* .") == 0 || die;
	system("cd dos.tmp && rmdir DOS WIN EBD Drivers") == 0 || die;

	# HACK: Suggested patch to COMMAND.COM to make it pure DOS bootable.
	#       This removes Microsoft's deliberate crippling of COMMAND.COM.
	#       They could have left pure DOS alone but coded Windows ME to outright
	#       ignore any realmode TSRs.
	open(CMD,"+<","dos.tmp/COMMAND.COM") || die;
	binmode(CMD);
	seek(CMD,0x6510,0);
	read(CMD,$x,1);
	if ($x eq chr(0x75)) {
		seek(CMD,0x6510,0);
		print CMD chr(0xEB);
	}
	else {
		print "WARNING: COMMAND.COM did not have expected byte\n";
	}
	close(CMD);

	# make sure the root directory copy is also updated
	system("mdel -i $diskbase\@\@$part_offset ::COMMAND.COM");
	system("mcopy -i $diskbase\@\@$part_offset dos.tmp/COMMAND.COM ::COMMAND.COM") == 0 || die;
	system("mattrib -a -r -s -i $diskbase\@\@$part_offset ::COMMAND.COM") == 0 || die;
}

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

# make sure certain "copies" of files in the DOS directory are hidden
system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::DOS/IO.SYS >/dev/null 2>&1");
system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::DOS/MSDOS.SYS >/dev/null 2>&1");
system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::DOS/IBMBIO.COM >/dev/null 2>&1");
system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::DOS/IBMDOS.COM >/dev/null 2>&1");
system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::DOS/WINBOOT.SYS >/dev/null 2>&1");

if ($ver ne "2.1" && $ver ne "2.2td") {
	# next, add the OAK IDE CD-ROM driver
	system("mcopy -o -n -i $diskbase\@\@$part_offset oakcdrom.sys ::DOS/OAKCDROM.SYS") == 0 || die;
}

# Pre-6.0: add MSCDEX.EXE
if ($ver =~ m/^[45]\./ || $ver eq "3.3nec" || $ver eq "3.3" || $ver eq "3.2epson") { # v4.x and v5.x
	system("mcopy -i $diskbase\@\@$part_offset mscdex.exe.v2.10 ::DOS/MSCDEX.EXE") == 0 || die;
}

# and the default CONFIG.SYS and AUTOEXEC.BAT files
system("mcopy -i $diskbase\@\@$part_offset $config_sys_file ::CONFIG.SYS") == 0 || die;
system("mcopy -i $diskbase\@\@$part_offset $autoexec_bat_file ::AUTOEXEC.BAT") == 0 || die;

# make sure root directory entries have zeroed out creation time
if ($rootdircount > 0 && $rootdirstart > 0) {
	open(BIN,"+<","$diskbase") || die
	binmode(BIN);

	my $dirent;

	for ($i=0;$i < $rootdircount;$i++) {
		seek(BIN,$rootdirstart+($i*32),0);
		read(BIN,$dirent,32);

		last if (substr($dirent,0,1) eq chr(0));

		# +0x0E = Windows 95 file creation time
		# +0x10 = Windows 95 file creation date
		# +0x12 = Windows 95 file last access date
		# +0x14 = FAT32 high cluster value (this is FAT12/FAT16!)
		# -------------------------------------------------------
		# +0x16 = Last modified time
		# +0x18 = Last modified date
		# +0x1A = First cluster (low 16 bits on FAT32!)
		# +0x1C = file size
		substr($dirent,14,8) = (chr(0) x 8);

		seek(BIN,$rootdirstart+($i*32),0);
		print BIN $dirent;
	}

	close(BIN);
}

# make a zero track and cat them together to make a full disk image
system("dd conv=notrunc,nocreat if=mbr.bin of=$diskbase bs=512 count=1") == 0 || die;

# and then edit the partition table directly. we WOULD use fdisk, but fdisk has this
# terrible fetish for forcing your first partition at least 2048 sectors away from the start
# of the disk, which is an utter waste of disk space. Fuck you fdisk.
my $prt_cyls = $cyls;
$prt_cyls = 1024 if $prt_cyls > 1024;
open(BIN,"+<","$diskbase") || die;
binmode(BIN);
seek(BIN,0x1BE,0);
print BIN pack("cccccccc",
	0x80, # status/physical drive
	0x01, # head 1
	0x01 | (0 << 6), # sector 1 cylinder 0 (high 2 bits)
	0x00, # cylinder 0 (low 8 bits)
	$part_type, # partition type (0x06 = MS-DOS FAT16 >= 32MB)
	$heads-1, # end head
	$sects | ((($prt_cyls - 1) >> 8) << 6), # end sector/cylinder
	($prt_cyls - 1) & 0xFF); # end cylinder
print BIN pack("VV",$sects,($sects*$cyls*$heads)-$sects);
close(BIN);

# FAT32: patch FSInfo
if ($fat == 32) {
	# patch FSInfo to report free clusters as "unknown"
	open(BIN,"+<","$diskbase") || die
	binmode(BIN);
	seek(BIN,$part_offset+(512*1)+0x1E8,0); print BIN pack("VV",0xFFFFFFFF,0xFFFFFFFF);
	seek(BIN,$part_offset+(512*(1+6))+0x1E8,0); print BIN pack("VV",0xFFFFFFFF,0xFFFFFFFF);
	close(BIN);
}

# make VDI for VirtualBox, QEMU, etc
system("qemu-img convert -f raw -O vdi $diskbase $diskbase.vdi") == 0 || die;
# ah, but that's not quite enough. qemu-img devs apparently never considered
# the idea that disk geometry might be something that would matter, it doesn't
# even have the option! so we have to patch the VDI image header!
open(VDI,"+<","$diskbase.vdi") || die;
binmode(VDI);
seek(VDI,0x15C,0);
print VDI pack("VVV",$cyls,$heads,$sects);
close(VDI);

