package BE::mov::Languages;
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
	);
	%EXPORT_TAGS = qw(
	);;     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw(
		@Languages
		%Languages
	); #qw(&func3);
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


our @Languages = ( [ "Deutsch mit Audiodeskription", "ger", "+H", [ "Mit Audiodeskription", qw(Audiodeskription Hörfassung Hörfilm) ] ],
               [ "English", "eng", ",en", [ qw(Englisch Originalversion OV), "Originalversion Mit Untertitel", "OV - English", "englische Fassung", "(Originalversion) (OV)" ] ],
               [ "Danish", "dan", ",dk", [ qw(dan) ] ],
               [ "Français", "fre", ",fr", [ qw(Französisch), "Französische Originalfassung" ] ],
               [ "Norwegian", "nor", ",no", [ qw(nor) ] ],
               [ "Swedish", "swe", ",sv", [ qw(swe) ] ],
);

our %Languages = (
	de => {
		name => "Deutsch",
		code3 => "ger",
		code2 => "de",
		#code2p => ,
		fn_heuristic => [],
	},
	de_H => {
		name => "Deutsch mit Audiodeskription",
		code3 => "ger",
		code2 => "de",
		code2p => "H",
		fn_heuristic => ["Mit Audiodeskription", qw(Audiodeskription Hörfassung Hörfilm)],
	},
	de_K => {
		name => "Deutsch Klare Sprache",
		code3 => "ger",
		code2 => "de",
		code2p => "K",
		fn_heuristic => ["Klare Sprache"],
	},
	en => {
		name => "English",
		code3 => "eng",
		code2 => "en",
		#code2p => 
		fn_heuristic => [qw(Englisch Originalversion OV), "Originalversion Mit Untertitel", "OV - English", "englische Fassung", "(Originalversion) (OV)"],
	},
	dk => {
		name => "Danish",
		code3 => "dan",
		code2 => "dk",
		#code2p => 
		fn_heuristic => [qw(dan)],
	},
	fr => {
		name => "Français",
		code3 => "fre",
		code2 => "fr",
		#code2p => 
		fn_heuristic => [qw(Französisch), "Französische Originalfassung"],
	},
	no => {
		name => "Norwegian",
		code3 => "nor",
		code2 => "no",
		#code2p => 
		fn_heuristic => [qw(nor)],
	},
	sv => {
		name => "Swedish",
		code3 => "swe",
		code2 => "sv",
		#code2p => 
		fn_heuristic => [qw(swe)],
	},
	Es => {
		name => "Español",
		code3 => "esp",
		code2 => "es",
		#code2p => 
		fn_heuristic => [qw(esp)],
	},
);