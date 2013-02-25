#!/usr/bin/perl
#
# ./replace-bootsector-mkvfat.pl test160.dsk 0xFE 8 1 40 0x800 1
#
my $file = shift @ARGV;
my $fattype = oct(shift @ARGV);
my $sect_p_track = oct(shift @ARGV);
my $heads = oct(shift @ARGV);
my $tracks = oct(shift @ARGV);
my $root_dir_size = oct(shift @ARGV);
my $sect_p_cluster = oct(shift @ARGV);

open(F,"+<",$file) || die;
binmode(F);

my $roots = int(($root_dir_size + 31) / 32);

$x = system("dd if=/dev/zero of=__tmp__.dsk bs=512 count=320");
die unless ($x == 0);
$x = system("mkfs.vfat -s $sect_p_cluster -f 2 -F 12 -r $roots -R 1 __tmp__.dsk");
die unless ($x == 0);

open(R,"<","__tmp__.dsk") || die;
binmode(R);
my $tmp;
seek(R,0,0);
seek(F,0,0);
read(R,$tmp,512);
print F $tmp;
close(R);

# OK, then patch over the filesystem
seek(F,0x200,0);
print F pack("C",$fattype);
seek(F,21,0);
print F pack("C",$fattype);

close(F);

system("rm -f __tmp__.dsk");

