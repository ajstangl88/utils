#!/usr/bin/perl

=pod

=head1 NAME

Pipeline Launcher Daemon

=head1 SYNOPSIS

dirminder --conf=dirs.ini

=head1 DESCRIPTION

A simple daemon to monitor a directory

=head1 OPTIONS

=over

=item B<--conf>=I<config file>

The .ini formatted config file with the following parameters:

 [global]
    Sleep interval time in seconds


=item B<-h>, B<--help>

Displays usage information.

=back

=head1 EXAMPLES

    launcherd --conf=config.ini
    launcherd --stop
    launcherd --help

=head1 AUTHOR

AJ Stangl <L<astangl@personalgenome.com|mailto:astangl@personalgenome.com>>

=head1 COPYRIGHT

Copyright 2016 Personal Genome Diagnostics

=cut

use strict;
use warnings;
use Proc::Daemon;
use Proc::PID::File;
use Getopt::Long;
use Cwd;
use Cwd 'abs_path';
use File::Spec::Functions;
use Config::Simple;
use Pod::Usage;
use DateTime;
use DateTime::Format::Duration;
use Data::Dumper;

$| = 1;

# Command line parameters
my %options = ();
my $res = GetOptions(\%options, 'config=s', 'start', 'stop', 'help|h');

if ($options{'help'}) { pod2usage({-exitval => 0, -verbose => 2, -output => \*STDOUT}); }

# Get config file values
my $conf_file;
my $config;

unless ($options{config}) {
    $conf_file = '/mnt/user_data/aj_dev/RemoteReporting/Dameon/configs/config.ini';
    $config = new Config::Simple($conf_file);
}
else {
    $conf_file = abs_path($options{config});
    $config = new Config::Simple($conf_file);
}




# Common parameters
my $sleep_interval_s = $config->param('global.sleep_interval_s');
my $pid_file = $config->param('global.pidfile');
my $stderr = $config->param('global.stderr');
my $stdout = $config->param('global.stdout');
my $cmd = $config->param('global.cmd');

# Create the daemon process
my $daemon = Proc::Daemon->new(
    work_dir    => getcwd(),
    pid_file    => $pid_file,
    child_STDOUT => "+>>$stdout",
    child_STDERR => "+>>$stderr",
);

# Kill the daemon when --stop is passed
if ($options{stop}) {
    if ($daemon->Kill_Daemon($pid_file)) {
        print STDOUT "Reporting daemon stopped.\n";
    }

    else {
        print STDERR "Failed to stop Reporting daemon. Was it running?\n";
    }

    exit(0);
}

die "Reporting daemon already running!\n" if Proc::PID::File->running({dir => getcwd(), name => 'pidfile'});

my $pid = $daemon->Init();

if ($pid) {
    print "Started Reporting daemon with pid $pid.\n";
    exit(0);    # Exit the parent process
}


print STDOUT "[".localtime,"]: Reporting daemon initialized.\n";

my $go = 1;
$SIG{TERM} = sub { $go = 0 };

select(STDERR);
$| = 1;
select(STDOUT);
$| = 1;


while ($go) {

    # Your Command Here!
    print `$cmd`;
    sleep $sleep_interval_s;
}
