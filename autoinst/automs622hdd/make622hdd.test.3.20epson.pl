#!/usr/bin/perl
# MS-DOS 3.2 runs in QEMU, but does not support the 1.44MB floppy format.
# Unfortunately QEMU does not support the 720KB floppy format it does
# support. So we use DOSBox.

# The build script produces a VDI regardless for convenience and
# for the time when eventually QEMU fixes whatever is wrong.

# FIXME: MS-DOS 3.2 relies on the C/H/S values of the drive! It's not
#        like later versions where it doesn't seem to matter.

# first we need to read back the geometry.
# being MS-DOS 4.01 it's likely it only supports 63 sectors/track 16 heads
# because it pre-dates the geometry translation later BIOSes needed to do
# to support larger drives. FIXME: Eventually we'll want to read back the
# geometry anyway from the partition table when we add support to the
# builder script for geometries other than 63 sectors/track 16 heads/track.
my $sects = 63,$heads = 16,$cyls,$sectors;
$sectors = ( -s "../../build/msdos320epsonhdd" ) / 512;
$cyls = $sectors / $sects / $heads;
print "Geometry: C/H/S $cyls/$heads/$sects\n";

my $fboot = 0;

while (@ARGV > 0) {
	my $a = shift(@ARGV);
	$fboot = 1 if $a eq "floppy";
}

# generate a minimalist dosbox.conf
open(X,">../../build/msdos320epsonhdd.dosbox.conf") || die;
print X "[ide, primary]\n";
print X "enable=true\n";
print X "\n";
print X "[autoexec]\n";
print X "imgmount 2 msdos320epsonhdd -t hdd -fs none -size 512,$sects,$heads,$cyls -ide 1m\n";
if ($fboot) {
	print X "boot boot320.dsk\n";
}
else {
	print X "imgmount 0 boot320.dsk -t floppy -fs none\n";
	print X "boot -l c\n";
}
print X "\n";
close(X);

# go into the build dir and run DOSBox
chdir("../../build") || die;
system("dosbox-x -conf msdos320epsonhdd.dosbox.conf");

