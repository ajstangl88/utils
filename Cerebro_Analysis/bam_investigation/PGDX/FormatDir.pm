package PGDX::FormatDir;

use strict;
use warnings;
use Data::Dumper;
use Carp;

my ($ERROR,$WARN,$DEBUG) = (1,2,3);

sub new {
	my ($class, $opts) = @_;
	my $self = bless({},$class);
	$self->_init($opts);
}

sub _init {
	my ($self, $opts) = @_;

	$self->{'debug'} = 1;
	$self->{'devel'} = 0;
	
	if( exists( $opts->{'debug'} ) ) {
		$self->{'debug'} = $opts->{'debug'};
	}
	if( $opts->{'devel'} ) {
		$self->{'devel'} = 1;
	}
	
	return $self;
}

sub format_dir {
	return 1;
}

sub make_symlinks {
	my ($self, $list_file, $dir, $sample) = @_;

	foreach my $file ( `cat $list_file`  ) {
		chomp $file;
		unless( -e $file ) {
			if( $file =~ /\.gz$/ )  {
				$file =~ s/\.gz$//;
			} else {
				$file .= ".gz";
			}
			confess("Couldn't make symlinks for file $file because it (or a gzipped version doesn't exist")
				unless( -e $file );
		}

		my $cmd = "ln -s $file $dir/";
		$self->run_cmd( $cmd );
	}
}

sub dir_is_realign {
	my ($self, $dir, $opts) = @_;

	# Is there a CombinedChanges file?
	my $file = "$dir/$opts->{'sample'}_TN.CombinedChanges.txt";
	return -e $file;
}

sub dir_is_nonrealign {
	my ($self, $dir, $opts) = @_;
	return !($self->dir_is_realign( $dir, $opts ) );
}

sub run_cmd {
	my ($self, $cmd) = @_;
	$self->debug( $cmd );
	system($cmd);
}

sub debug {
	my ($self, $msg) = @_;
	$self->_print_msg( $DEBUG, $msg );
}
sub warn {
	my ($self, $msg) = @_;
	$self->_print_msg( $WARN, $msg );
}
sub error {
	my ($self, $msg) = @_;
	$self->_print_msg( $ERROR, $msg );
}
sub _print_msg {
	my ($self, $level, $msg) = @_;

	if( $level <= $self->{'debug'} ) {
		if( $level == $ERROR ) {
			confess("$msg");
		} elsif( $level == $WARN ) {
			print STDERR "$msg\n";
		} else {
			print "$msg\n";
		}
	}
}
1;
