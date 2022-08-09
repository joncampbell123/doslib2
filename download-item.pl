#!/usr/bin/perl
#
# cached download helper
#
# download-item.sh --url <relative path> --as <relative path> --rel <path of invocation relative to root>
#
# other options: --no-interactive          don't prompt for credentials and web address if credentials file not present
my $url,$as,$rel;
my $web_root,$user,$pass;
my $no_interactive;
my $web_cache;
my $a;

for ($i=0;$i < @ARGV;) {
	$a = $ARGV[$i++];

	if ($a =~ s/^\-+//) {
		if ($a eq "url") {
			$url = $ARGV[$i++];
			$url =~ s/ /%20/g;
		}
		elsif ($a eq "as") {
			$as = $ARGV[$i++];
		}
		elsif ($a eq "rel") {
			$rel = $ARGV[$i++];
		}
		elsif ($a eq "no-interactive") {
			$no_interactive = 1;
		}
		else {
			print "Unknown switch $a\n";
		}
	}
	else {
		die "Unknown arg";
	}
}

$rel = "." if ($rel eq "" || !defined($rel));
die "$rel not a valid dir" unless -d $rel;
die "What do I download?" unless (defined($url) && $url ne "");
die "Whas do I save it as?" unless (defined($as) && $as ne "");

# if .web.dl.nfo is not present, prompt user for info
if (!( -f "$rel/.web.dl.nfo" )) {
	die "No web nfo and not interactive" if $no_interactive > 0;

	print "What web address should I pull all files from. All relative URLs are based\n";
	print "off the web root given.\n";
	print "\n";
	print "URL: "; $|++;
	$web_root = <STDIN>; chomp $web_root;
	die "unsupported protocol" unless $web_root =~ m/^(http|https|ftp)\:\/\//;

	print "If the web address requires authentication, what username do I use?\n";
	print "Username: "; $|++;
	$user = <STDIN>; chomp $user;

	if ($user ne "" && defined($user)) {
		print "Password: "; $|++;
		system("stty -echo");
		$pass = <STDIN>; chomp $pass;
		system("stty echo");
	}

	open(CFG,">$rel/.web.dl.nfo") || die;
	print CFG "base=$web_root\n";
	print CFG "user=$user\n";
	print CFG "pass=$pass\n";
	close(CFG);
}

open(CFG,"<$rel/.web.dl.nfo") || die;
while (my $line = <CFG>) {
	my $nam,$val,$i;

	chomp $line;
	next if $line =~ m/^[ \t]*$/;
	$i = index($line,'=');
	next if $i <= 0;
	$nam = substr($line,0,$i);
	$val = substr($line,$i+1);

	$web_root = $val if $nam eq "base";
	$user = $val if $nam eq "user";
	$pass = $val if $nam eq "pass";
}
close(CFG);

die unless ($url ne '' && $web_root ne '');

sub shellesc($) {
	my $a = shift @_;
	$a =~ s/([^0-9a-zA-Z\.\-])/\\$1/g;
	return $a;
}

$web_cache = "$rel/web.cache";
system("mkdir -p ".shellesc($web_cache)) == 0 || die;

if ( -f "$web_cache/$as" ) {
	print "$as [$web_root/$url] already downloaded\n";
	exit 0;
}

my $cmd;

print "Downloading: $web_root/$url\n";
$cmd = 'curl --show-error -f --globoff --insecure --progress-bar -o '.shellesc("$web_cache/$as").'.part ';
if ($user ne '') {
	# 2022/08/08: Curl you dumbass, why isn't this the default?
	#             Failure to authenticate to my local network storage because you assumed "basic"
	#             authentication when you should have been using "digest" authentication.
	$cmd .= '--anyauth ';
	$cmd .= '--user '.shellesc($user);
	$cmd .= ':'.shellesc($pass) if $pass ne '';
	$cmd .= ' ';
}
if ( -f "$web_cache/$as.part" ) {
	# the file already exists, tell curl to continue downloading
	print "$as [$web_root/$url] resuming download\n";
	$cmd .= ' --continue-at '.( -s "$web_cache/$as.part" ).' ';
}
$cmd .= shellesc("$web_root/$url");

# OK, do it
$res = system($cmd);
if ($res != 0) {
	print "Download failed\n";
	exit 1;
}

system("mv -vn ".shellesc("$web_cache/$as.part")." ".shellesc("$web_cache/$as")) == 0 || exit 1;

