package BE::mov::Filename;
use warnings;
use strict;
use Data::Dumper;
use IPC::Open3;
use Symbol;
use JSON;
my $JSON = JSON->new->utf8;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 0.01;

	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		new
	);
	%EXPORT_TAGS = qw(
		WHToRes
		probe_height
		fn_parse
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

sub probe($%) {
	my $f = shift;
	my %flags = (@_);
	return $f->{json} if !$flags{force} && defined $f->{json};

	my $prog = $flags{progname} || "ffprobe";
		
	my ($i, $o, $e, $res);
	$e = gensym;
	my $pid = open3($i, $o, $e,
		$prog, qw(-hide_banner -show_chapters -show_programs -show_streams
		-show_format -show_error -print_format json), $f->{dir}."/".$f->{name_orig});

	my $ox;
	{local $/; $/=undef; $ox = <$o>;}
	waitpid($pid, 0);

	return $f->{json} = $JSON->decode( $ox );
}

sub probe_height($%) {
	my $f = shift;
	my %flags = (@_);

	my $json = probe($f, %flags);
	return if !defined $json;


	if ($f->{"res"} && @{$f->{"res"}}) {
		return $f->{"res"} if (!$flags{force})
	}

	my @res;

	for my $s (@{$json->{streams}}) {
		if ($s->{codec_type} eq "video") {
			push @res, WHToRes($f->{w}=$s->{width},
			                   $f->{h}=$s->{height});
		}
	}

	return $f->{res}=[@res];
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
		$f->{res}? join(',', @{$f->{res}}) : (),
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
		} elsif (/^\d+[ikp](?:,\d+[ikp])*$/) { # 1234p, 567i,4k
			push(@{$ret->{res}}, split(/,/, $_));
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
