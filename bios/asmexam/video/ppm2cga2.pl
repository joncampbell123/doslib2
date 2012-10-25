#!/usr/bin/perl
#
# Convert a PPM that uses the CGA palette into CGA raw bitmap data

my $row,$trip,$byt,$width,$height,$max,$x,$y;

binmode(STDIN);
binmode(STDOUT);

$row = <STDIN>; chomp $row;
if ($row ne "P6") {
	die "Must be P6 PPM format, not $row";
}

do {
	$row = <STDIN>; chomp $row;
} while ($row =~ m/^#/);

# width x height
($width,$height) = split(/ +/,$row);
print STDERR "Width: $width\n";
print STDERR "Height: $height\n";
$max = <STDIN>; chomp $max;
die "Max is not 255" unless $max == 255;
die "Width must be a multiple of 8" unless ($width % 8) == 0;
die "Height must be a multiple of 2" unless ($height % 2) == 0;

for ($y=0;$y < $height;$y++) {
	for ($x=0;$x < $width;$x += 8) {
		$byt = 0;
		for ($subx=0;$subx < 8;$subx++) {
			die unless read(STDIN,$trip,3);

			if ($trip eq pack("CCC",255,255,255)) {
				$byt |= 1 << (7 - $subx);
			}
			elsif ($trip eq pack("CCC",0,0,0)) {
			}
			else {
				print STDERR "Unknown triplet\n";
			}	
		}

		print STDOUT pack("C",$byt);
	}
}

