=head1 NAME

PGDX

=head1 DESCRIPTION

Common PGDX utilities

=cut

package PGDX;

use strict;
use warnings;
use Carp;

# Parses a ChangeUID into it's component parts
sub parse_changeuid {
    my ($change) = @_;
    return ($1,$2,$3,$4,$5) if( $change =~ /(chr[^\.]+)\.fa\:(\d+)-(\d+)_([^_]*)_([^_]*)/ );
    return (undef,undef,undef,undef,undef);
}

# Returns true if change is an indel.
sub change_is_indel {
    my ($change_uid) = @_;
    my ($chr,$st,$en,$from,$to) = &parse_changeuid( $change_uid );
    return !($from && $to) || ($from eq '(null)' || $to eq '(null)');
}


# Takes a list file and returns the type of tag
# If a type is specified, return true if the tag is that type
sub detectInputType {
    my $listfile = shift;
    my $istype = shift;
    open IN, "<$listfile" or die "Unable to open $listfile\n";
    my @files = <IN>;
    close IN;
    
    my $type;
    my $retval;
    foreach my $f (@files) {

        # Raw data
        if($f =~ /SampleSheet.csv/ && !$type) {
            $type = 'raw';
        }
        elsif($f =~ /runParameters.xml/) {
            $type = 'raw';
            my $version = 1;
            my $rtaversion = `grep RTAVersion $f`;
            if($rtaversion =~ /<RTAVersion>(.*)<\/RTAVersion>/) {
                my $v_string = $1;
                if($v_string =~ /^(\d+)/) {
                    $version = $1;
                }
            }
            if($version > 1) {
                $type = 'raw2';
            }
        }

        # Bam
        elsif($f =~ /.*.bam/) {
            $type = 'bam';
        }

        # Fastq
        elsif($f =~ /.*.fastq/) {
            $type = 'fastq';
        }

        # Export
        elsif($f =~ /.*.export/) {
            $type = 'export';
        }
    }
    if(!$type) {
        die "Couldn't detect the type of tag!\n";
    }
    elsif($istype) {
        if($istype eq $type) {
            $retval = 1;
        }
        else {
            $retval = 0;
        }
    }
    else {
        $retval = $type;
    }
    return $retval;
}

# Duplicates the functionality of export2fastq.pl for use in other scripts.
sub export2fastq {
    my $export = shift;
    my $output = shift;
    
    my $infh = open_file($export,'in');
    open OUT, ">$output" or die "Couldn't open $export\n";

    while (my $line=<$infh>) {
      chomp $line;
      my(@elts)=split(/\t/,$line);
      my $machinename = $elts[0];
      my $runnumber = $elts[1];
      my $lane = $elts[2];
      my $tile = $elts[3];
      my $xcoord = $elts[4];
      my $ycoord = $elts[5];
      my $index = $elts[6];
      my $pair = $elts[7];
      my $seq = $elts[8];
      my $qual = $elts[9];
      my $filter = ($elts[21] eq 'Y' ? 'N' : 'Y');
      my $control = 0;
      my $flowcell = "000000000-00000";

      #Convert phred+64 to phred+33
      my $squal = pack('C*',map {$_-31} (unpack('C*', $qual)));

      #my $oldheader=$elts[0].":".$elts[1].":".$elts[2].":".$elts[3].":".$elts[4].":".$elts[5]."#".$elts[6]."/".$elts[7]."\n";
      my $header1_7 = "$machinename:$lane:$tile:$xcoord:$ycoord"."#"."$index/$pair\n";
      my $header1_8 = "$machinename:$runnumber:$flowcell:$lane:$tile:$xcoord:$ycoord $pair:$filter:$control:$index\n";
      print OUT "@".$header1_8.$seq."\n+\n".$squal."\n";
    }
}


# Takes a row and determines if
# it's a header row. Convenient in
# case this actually changes.
sub is_header_row {
    my ($row) = @_;
    return $row =~ /^ChangeUID/;
}

## Meant to replace the formatpodpath script used to turn
## /mnt/user_data/PGDX-DATA9-POD5/Raw_Data_Backups style paths
## to pgdx-pod local paths.
#
#Expects file paths in /mnt/user_data like
#PGDX-DATA2-POD1 -> /data2-pgdx-pod1/
#PGDX-DATA1-POD1 -> /data-pgdx-pod1/
#PGDX-POD1 -> /data-pgdx-pod1/
#And assumes all others are local.
sub formatpodpath {
    my ($path, $remote_user) = @_;

    #################################
    # Some config options for below #
    $remote_user = "pgdxuser" unless( $remote_user );
    #################################

    ## If the file does not exist, try and find a gz version
    ## or a non-gz version.
    if( ! -e "$path"){ 
        my $nozip = $path;
        $nozip =~ s/\.gz\s+$//g;
        if(-e "$path.gz" ){ #zip exists
            $path = "$path.gz";
        } elsif(-e "$nozip"){
            $path = "$nozip";
        }
    }

    my $full_path;
    if( $path =~ m|^/mnt/user_data/+PGDX-(DATA\d+)-(POD\d+)/+|i){
        my $dir=lc($1);
        my $pod=lc($2);
        $path =~ s|^/mnt/user_data/+PGDX-DATA\d+-POD\d+/+||i;
        $full_path = "$remote_user\@pgdx-$pod:/$dir/$path";
    }
    elsif( $path =~ m|^/mnt/user_data/+PGDX-POD1/+|i ) {
        #Assume legacy notation
        $path =~ s|^/mnt/user_data/+PGDX-POD1/+||i;	
        $full_path = "$remote_user\@pgdx-pod1:/data1/$path";
    }
    else {
        #If it doesn't match the above paths, assume it's local.
        $full_path = $path;
    }

    return $full_path; 
}

sub getChangesHeaderIndex {
    my $config = shift;
    my $expected_headers = $config->{headers};
    my $die_on_missing = 0;
    if( exists( $config->{'die_on_missing_header'} ) && $config->{'die_on_missing_header'} ) {
        $die_on_missing = 1;
    }   

    # Open the file, grab the first line (assume it's a header?)
    open(IN, "<$config->{changes}") or die("Unable to open changes file [$config->{'changes'}]: $!");
    chomp( my $head = <IN> );
    close(IN);
    die("Couldn't get the header for $config->{changes} $head") unless( $head );

    my @hvals = split(/\t/,$head);

    my $headerslookup = &getHeaderIndex( \@hvals, $expected_headers, $die_on_missing );
    return $headerslookup;
}

sub getHeaderIndex {
    my ($header_names, $expected_headers, $die_on_missing, $full_index) = @_;

    my $headerslookup = {};
    map { $headerslookup->{$_} = '' } @{$expected_headers};

    $full_index = 0 unless( defined( $full_index ) || @{$expected_headers} == 0 );

    # We only keep the indices we need.
    for( my $i =0; $i < @{$header_names}; $i++ ) {
        if( $full_index || exists( $headerslookup->{$header_names->[$i]} ) ) {
            $headerslookup->{$header_names->[$i]} = $i;
        }
    }

    # If we choose to die when an expected header is missing
    if( $die_on_missing ) {
        foreach my $colName ( @{$expected_headers} ) {
            if( !exists( $headerslookup->{$colName} ) || $headerslookup->{$colName} eq '' ) {
                die("Unable to find column name [$colName] in header");
            }
        }
    }

    return $headerslookup;
}

sub open_file {

    my $file = shift;
    my $direction = shift;
    my $fh;

    if( $direction eq 'out' ) {
        if( $file =~ /\.gz$/ ) {
            open( $fh, ">:gzip", $file ) or confess("can't open $file ($!)");
            print "using gzip\n";
        } else {
            open( $fh, "> $file" ) or confess("Can't open $file ($!)");
        }
    } elsif( $direction eq 'concat' ) {
        if( $file =~ /\.gz$/ ) {
            open( $fh, ">>:gzip", $file ) or confess("can't open $file ($!)");
            print "using gzip\n";
        } else {
            open( $fh, ">> $file" ) or confess("Can't open $file ($!)");
        }
    } elsif( $direction eq 'in' ) {

        if( -e $file ) {

            if( $file =~ /\.gz$/ ) {
                open( $fh, "<:gzip", $file ) or confess("can't open $file ($!)");
            } else {
                open( $fh, "< $file") or confess("can't open $file ($!)");
            }
        } elsif( -e $file.".gz" ) {
            my $tmp = $file.".gz";
            open( $fh, "<:gzip", $tmp ) or confess("Can't open $tmp ($!)");
        } else {
            confess("Could not find $file or a gz version");
        }

    } else {
        confess("Please specifiy a direction.  'in', 'out', or 'concat'");
    }

    return $fh;
}

sub reorder_columns {
	my ($opts) = @_;

	map { confess("Options $_ is required") unless(exists($opts->{$_})) } qw(headers_file);

	my $headers = $opts->{'headers_file'};
	my $outfh = \*STDOUT;
	if( exists( $opts->{'outfile'} ) ) {
		$outfh = &open_file( $opts->{'outfile'}, "out" );
	}

	## Could also pass in file handle or array or something 
	## and handle that as well.
	if( $opts->{'file'} ) {
		confess("File $opts->{'file'} doesn't exist") unless( -e $opts->{'file'});

		## Parse the headers file
		open(IN, "< $headers") or confess("Unable to open header file $headers");
		my @output_headers = ();
		my @header_order = ();
		my $new_headers = {};
		my $regex_heads = {};
		my $mapped_heads = {};
		my $mapped_heads_by_full = {};
		my $mapped_indices = {};
		my $mapped_heads_new = {};
		my $i = 0;
		while(<IN>) {
			chomp;
			if(/^regex\((.*)\)$/) {
				$regex_heads->{$1} = $i;
			}
			if(/^MAP\((.*)\|(.*)\)$/) {
				$mapped_heads_by_full->{$_} = 1;
				$mapped_heads_new->{$2} = $i;
				$mapped_heads->{$1} = {
					pos => $i,
					newhead => $2
				};
				$mapped_indices->{$i} = $2;
			}
			$new_headers->{$_} = 1;
			push(@output_headers,$_);
			push(@header_order,$_);
			$i++;
		}

		close IN;


		open(IN, "< $opts->{'file'}") or confess("Unable to open changes file $opts->{'file'}}");

		chomp( my $head = <IN> );

		my @current_headers = split(/\t/,$head);
		my $current_header_lookup;
		# First check for headers in the changes file
		# that are not in the order file
		$i = 0;
		foreach my $head (@current_headers) {
			my $found = 0;
			if(!$new_headers->{$head} && !$mapped_heads_new->{$head}) {
				print STDERR "Couldn't find $head in the order file, check the regexes\n";
				foreach my $reg (keys %$regex_heads) {
					if($head =~ /$reg/) {
						print STDERR "Found $reg matched $head, setting $head as the header\n";
						$found =1;
						$output_headers[$regex_heads->{$reg}] = $head;
						$header_order[$regex_heads->{$reg}] = $head;
					}
				}
				if(!$found && !$opts->{'trim_extra'}) {
					print STDERR "Couldn't find $head in the order file, will append\n";
					push(@header_order, $head);
					push(@output_headers,$head);
				}        
			}

			# Check that this column is not supposed to be mapped somewhere else too
			if($mapped_heads->{$head}) {
				$header_order[$mapped_heads->{$head}->{pos}] = $head;
				$output_headers[$mapped_heads->{$head}->{pos}] = $mapped_heads->{$head}->{newhead};
			}
			else {
				foreach my $rhead (keys %$regex_heads) {
					my $key="regex($rhead)";
					if($mapped_heads->{$key} && $head =~ /$rhead/) {
						$header_order[$mapped_heads->{$key}->{pos}] = $head;
						$output_headers[$mapped_heads->{$key}->{pos}] = $mapped_heads->{$key}->{newhead};
					}
				}
			}

			$current_header_lookup->{$head} = $i;
			$i++;
		}

		# Next check for headers in the order file 
		# that are not in the changes file
		my $cnf_string = "COLUMN NOT FOUND";
		$cnf_string = "" if( $opts->{'remove_cnf'} );

		my $missing_cols;
		foreach my $head (@header_order) {
			if($head =~ /^MAP\((.*)\|(.*)\)$/) {
				my $oldname = $1;
				my $newname = $2;
				if(!$current_header_lookup->{$newname}) {
					$missing_cols->{$newname} = 1;
					$output_headers[$mapped_heads->{$oldname}->{pos}] = $mapped_heads->{$oldname}->{newhead};

				}
			}
			if(!exists $current_header_lookup->{$head} && !exists $regex_heads->{$head} && !exists $mapped_heads_by_full->{$head}) {
				print STDERR "Couldn't find $head in the changes file, all entries will be [$cnf_string]\n";
				$missing_cols->{$head}=1;
			}
		}

		# Lastly, print
		print $outfh join("\t",@output_headers)."\n";

		while(<IN>) {
			chomp;
			my @f = split(/\t/,$_);
			my @vals;
			my $foocount=0; # HACK - need to change the lookupkey column in the report section.
			my $c = 0;
			foreach my $head (@header_order) {

				if($missing_cols->{$head}) {
					push(@vals,$cnf_string);
				}
				else {
					if(exists($current_header_lookup->{$head})) {
						my $val = $f[$current_header_lookup->{$head}];
						if($head eq 'LookupKey') {
							$foocount ++;
							if($foocount > 1) {
								$val =~ s/\.fa_/_/;
							}
						}

						if( $opts->{'remove_cnf'} && $val eq 'COLUMN NOT FOUND' ) {
							if( exists( $mapped_indices->{$c}) ) {
								push(@vals,"-");
							} else {
								push(@vals, "");
							}
						} else {
							if( exists( $mapped_indices->{$c} ) && $val eq "" ) {
								push(@vals, "-");
							} else {
								push(@vals,$val);
							}
						}
					}
					else { 
						push(@vals,$cnf_string);
					}
				}
				$c++;
			}
			print $outfh join("\t",@vals)."\n";
		}

	}
}

1;

