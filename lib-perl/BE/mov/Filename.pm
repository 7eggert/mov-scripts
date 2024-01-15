package BE::mov::Filename;
use warnings;
use strict;
use Data::Dumper;
use IPC::Open3;
use Symbol;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 0.01;

	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		new
q	);
	%EXPORT_TAGS = qw(
		WHToRes
		probe_height
k		fn_parse
	);;     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = (); #qw(&func3);
}
our @EXPORT_OK;

# exported package globals go here
#our %Hashit;

# non-exported package globals go here
our @TLTLD;

# initialize package globals, first exported ones
#$Var1   = '';
#%Hashit = ();

# then the others (which are still accessible as $Some::Module::stuff)
@TLTLD=();

# file-private lexicals go here
#my $priv_var    = '';
#my %secret_hash = ();


my $lang1re = qr/[a-z]{2}(?:\+H)?/;
my $langre = qr/$lang1re(?:,$lang1re)*/;
my %res_k = ( 4096 => "4k" );
my $extrare = qr/^(?:Fehler|Soundfehler|Colorized|Koloriert|DEFA|DVBT||LIVE|TV)$/;

sub WHToRes($$) {
	my ($width, $height) = @_;
	my $kres = $res_k{$width};
	return $kres if $kres;
	return "$height"."p";
}

sub probe_height($%) {
	my $f = shift;
	my %flags = (@_);

	return if $f->{res} && @{$f->{res}} && !($flags{force});

	my $prog = $flags{progname} || "ffprobe";
		
	my ($i, $o, $e, $res);
	$e = gensym;
	my $pid = open3($i, $o, $e, $prog, $f->{dir}."/".$f->{name_orig});
	my $mode = 0;
	while (<$e>) {
		chomp;
		if    ($mode == 0 && /^\s+Metadata:$/) {
			$mode++;
		} elsif ($mode == 1 && /^\s+height\s*:\s*(\d+)/) {
			$res=$f->{h}=$1;
		} elsif (/^\s+Stream .0\.\d(?:\([^)]+\))?\: Video\: \w+(?: \([^)]+\))?, (\d+)x(\d+)/) {
			$f->{w}=$1; $f->{h}=$2;
			$res=WHToRes($1, $2);last;
		} elsif (/^\s+Stream .0[.:]\d(?:\([^)]+\))?\: Video\:(?:\s*\w+(?:\s*\([^)]+\))*,)* (\d+)x(\d+)/) {
			$f->{w}=$1; $f->{h}=$2;
			$res=WHToRes($1, $2);last;
		}
#     Stream #0:0(eng): Video: h264 (Main) (avc1 / 0x31637661), yuv420p(tv), 1280x720 [SAR 1:1 DAR 16:9], 3581 kb/s, 25 fps, 25 tbr, 25k tbn, 50 tbc (default)
	}
	while (<$e>){};
	waitpid($pid, 0);
	return $f->{res}=[$res] if $res;
}

sub joindata($) {
	my $f = shift;
	return $f->{data_joined} = '' if $f->{_} && @{$f->{_}};
	return $f->{data_joined} = join(' ',
		$f->{year}->[0] || (),
		$f->{lang}? join(',', @{$f->{lang}}) : (),
		$f->{st}  ? "st=".join(',', @{$f->{st}}) : (),
		$f->{other}? @{$f->{other}} : (),
		$f->{FSK}->[0] || (),
		$f->{res}->[0] || (),
	);
}

sub newbase($) {
	my $f = shift;
	return join(' - ', (@{$f->{name_new}}, $f->{data_joined})) if $f->{data_joined} ne "";
	return join(' - ', (@{$f->{name_new}}));
}

sub newname($) {
	my $f = shift;
	my $newbase = $f->newbase();
	return $newbase .".$f->{ext}" if defined $f->{ext};
	return $newbase;
}

sub fn_parse($%) {
	my $f     = shift;
	my %flags = (@_);
	my $ret   = { name_orig => $f };
	if ($f =~ m,(.*)/(.*),) {
		$ret->{dir} = $1;
		$f = $2;
	} else {
		$ret->{dir} = ".";
	}
	if ($f =~ /(.*)\.(.*)/) {
		$f = $ret->{base_orig} = $1;
		$ret->{ext}  = $2;
	} else {
		$ret->{base_orig} = $f;
	}
	my @f   = split(/ - /, $f);
	my @p   = split(/\s+/, @f[@f-1]);
	my @p2  = split(/\s+/, @f[@f-2]);
	if (@p == 1 && $p[0] =~ /^\d+[ikp]$/ && grep {$_ eq $p[0]} @p2) {
		pop @f;
		@p = @p2;
	}
	my $shorten_f = 0;
	for (@p) {
		if (/^\d{4}$/) {
			push(@{$ret->{year}}, $_);
			$shorten_f = 1;
		} elsif (/^\d+[ikp]$/) {
			push(@{$ret->{res}}, $_);
			$shorten_f = 1;
		} elsif (/^FSK\d+$/) {
			push(@{$ret->{FSK}}, $_);
			$shorten_f = 1;
		} elsif (/^st=($langre)$/) {
			push(@{$ret->{st}}, split(/,/, $1));
			$shorten_f = 1;
		} elsif (/^$langre$/) {
			push(@{$ret->{lang}}, split(/,/, $_));
			$shorten_f = 1;
		} elsif (/$extrare/) {
			push(@{$ret->{other}}, $_);
			$shorten_f = 1;
		} else {
			push(@{$ret->{_}}, $_);
		}
	}
	if ($ret->{"_"} && @{$ret->{"_"}}) {
		delete($ret->{year});
		delete($ret->{res});
		delete($ret->{FSK});
		delete($ret->{st});
		delete($ret->{lang});
		delete($ret->{other});
		delete($ret->{_});
	} else {
		pop @f if $shorten_f;
	}
	
	probe_height($ret, %flags) if ($flags{vheight});
	
	joindata($ret);
	$ret->{name_new} = \@f;
	
	return $ret;
}

sub new($%) {
	my $f = shift;
	my $ret = fn_parse($f, @_);
	return bless($ret, "BE::mov::Filename");
}

1;
