#!/usr/bin/perl
# MS-DOS 4.01 does not run in QEMU or Bochs, though it does in VirtualBox.
# But I don't like to monkey around with VirtualBox's storage manager,
# so instead, we'll use DOSBox-X.

# The build script produces a VDI regardless for convenience and
# for the time when eventually QEMU fixes whatever is wrong.

my $disk = "msdos210hdd";

# first we need to read back the geometry.
# being MS-DOS 4.01 it's likely it only supports 63 sectors/track 16 heads
# because it pre-dates the geometry translation later BIOSes needed to do
# to support larger drives. FIXME: Eventually we'll want to read back the
# geometry anyway from the partition table when we add support to the
# builder script for geometries other than 63 sectors/track 16 heads/track.
my $sects = 63,$heads = 16,$cyls,$sectors;
$sectors = ( -s "../../build/$disk" ) / 512;

# read the partition to get the actual geometry
my $xx,$a,$b,$c;
open(X,"<","../../build/$disk") || die;
binmode(X);
seek(X,0x1BE+5,0);
read(X,$xx,3);
($a,$b,$c) = unpack("ccc",$xx);
$heads = $a;
$sects = $b & 0x3F;
$cyls = (($b >> 6) << 8) + $c;
$heads++;
$cyls++;
close(X);

# compute
$cyls = int($sectors / $sects / $heads);
print "Geometry: C/H/S $cyls/$heads/$sects\n";

my $fboot = 0;

while (@ARGV > 0) {
	my $a = shift(@ARGV);
	$fboot = 1 if $a eq "floppy";
}

# generate a minimalist dosbox.conf
open(X,">../../build/$disk.dosbox.conf") || die;
print X "[ide, primary]\n";
print X "enable=true\n";
print X "\n";
print X "[autoexec]\n";
print X "imgmount 2 $disk -t hdd -fs none -size 512,$sects,$heads,$cyls -ide 1m\n";
if ($fboot) {
	print X "boot boot.dsk\n";
}
else {
	print X "imgmount 0 boot.dsk -t floppy -fs none\n";
	print X "boot -l c\n";
}
print X "\n";
close(X);

# go into the build dir and run DOSBox
chdir("../../build") || die;
system("dosbox-x -conf $disk.dosbox.conf");

