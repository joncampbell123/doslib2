#!/usr/bin/perl
#
# Given a version number and NE image, patch the version number in the image
# (C) 2012 Jonathan Campbell

if (@ARGV < 2) {
	print STDERR "chgnever.pl [options] <version major.minor> <NE image>\n";
	print STDERR "  --progflag [-+]flag\n";
	print STDERR "       protonly        Protected mode only\n";
	print STDERR "       8086            8086 instructions\n";
	print STDERR "       286             286 instructions (implies 8086...)\n";
	print STDERR "       386             386 instructions (implies 286...)\n";
	print STDERR "       486             486 instructions (implies 386...)\n";
	print STDERR "  --linkver <a.b>\n";
	print STDERR "       Set linker version field to major a, minor b\n";
	print STDERR "  --apptype <n>\n";
	print STDERR "       0 = None (Pre-Windows 3.0?)\n";
	print STDERR "       1 = Full screen\n";
	print STDERR "       2 = Compatible with Windows/PM API\n";
	print STDERR "       3 = Uses Windows/PM API\n";
	exit 1;
}

my $vmaj,$vmin;
my $link_ver = undef;
my $pflags_mask = 0xFFFF,$pflags_or = 0;

while (@ARGV && $ARGV[0] =~ m/^-+/) {
	my $sw = shift @ARGV;
	$sw =~ s/^-+//;

	if ($sw eq "apptype") {
		my $typ = (shift @ARGV)+0;
		$typ &= 3;

		$pflags_mask = ~(7 << 8);
		$pflags_or |= ($typ << 8);
	}
	elsif ($sw eq "linkver") {
		$link_ver = shift @ARGV;
	}
	elsif ($sw eq "progflag") {
		my $what = shift @ARGV;
		my $on = undef;

		$on = 0 if (substr($what,0,1) eq "-");
		$on = 1 if (substr($what,0,1) eq "+");
		die unless defined($on);
		$what = substr($what,1);

		if ($what eq "protonly") {
			$pflags_mask &= ~(1 << 3) if $on == 0;
			$pflags_or |= (1 << 3) if $on == 1;
		}
		elsif ($what eq "8086") {
			$pflags_mask &= ~(1 << 4) if $on == 0;
			$pflags_or |= (1 << 4) if $on == 1;
		}
		elsif ($what eq "286") {
			$pflags_mask &= ~(1 << 5) if $on == 0;
			$pflags_or |= (3 << 4) if $on == 1;
		}
		elsif ($what eq "386") {
			$pflags_mask &= ~(1 << 6) if $on == 0;
			$pflags_or |= (7 << 4) if $on == 1;
		}
		elsif ($what eq "486") {
			$pflags_mask &= ~(1 << 7) if $on == 0;
			$pflags_or |= (15 << 4) if $on == 1;
		}
		else {
			die "I don't know progflag $what = $on";
		}
	}
	else {
		die "Unknown option $sw";
	}
}

my $version_str = shift @ARGV;
my $ne_file = shift @ARGV;
die "$ne_file does not exist" unless -f $ne_file;
($vmaj,$vmin) = split(/\./,$version_str);
$vmaj = $vmaj + 0;
$vmin = $vmin + 0;

my $tmp;
my $ne_offset = 0;

open(NE,"+<",$ne_file) || die;
binmode(NE);
seek(NE,0,0);
read(NE,$tmp,2);

if ($tmp ne "MZ") {
	print "Not MS-DOS executable\n";
	exit 1;
}

seek(NE,0x3C,0);
read(NE,$tmp,4);
$ne_offset = unpack("l",$tmp);
#print "Extended header at $ne_offset\n";

seek(NE,$ne_offset,0);
read(NE,$tmp,2);
if ($tmp ne "NE") {
	print "Not an NE image\n";
	exit 1;
}

# ok, patch
seek(NE,$ne_offset+0x3E,0);
read(NE,$tmp,2);
($ovminor,$ovmajor) = unpack("CC",$tmp);

#print "Old version: v$ovmajor.$ovminor\n";

seek(NE,$ne_offset+0x3E,0);
print NE pack("CC",$vmin,$vmaj);

print "Patching to: v$vmaj.$vmin\n";

if ($pflags_mask != 0xFFFF || $pflags_or != 0) {
	seek(NE,$ne_offset+0x0C,0);
	read(NE,$tmp,2);
	$tmp = unpack("v",$tmp);

	$tmp &= $pflags_mask;
	$tmp |= $pflags_or;

	print "Changing program flags to ".sprintf("%04X",$tmp)."\n";

	seek(NE,$ne_offset+0x0C,0);
	print NE pack("v",$tmp);
}

if (defined($link_ver) && $link_ver ne '') {
	($major,$minor) = split(/\./,$link_ver);
	$minor = 0 if !defined($minor);
	$major = 0 if !defined($major);

	seek(NE,$ne_offset+0x02,0);
	print NE pack("CC",$major,$minor);
}

close(NE);

