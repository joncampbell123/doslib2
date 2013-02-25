#!/usr/bin/perl
#
# ./replace-bootsector-pther.pl test160.dsk image
#
my $file = shift @ARGV;
my $other = shift @ARGV;

open(F,"+<",$file) || die;
if ($other =~ m/\.xz$/) {
	open(O,"xz -c -d $other |") || die;
}
else {
	open(O,"<",$other) || die;
}
binmode(O);
binmode(F);

my $raw;
seek(O,0,0);
seek(F,0,0);

read(O,$raw,512);
print F $raw;

close(O);
close(F);

