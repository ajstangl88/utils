package PGDX::FilterTab;

use strict;
use warnings;
use Data::Dumper;
use Module::Load;
use Config::IniFiles;
use PGDX;
$|++;

## Class var
my $DEBUG = 0;
my $HANDLER_SECTION_NAME = 'handlers';

## These are the accepted handlers
my $accept_handlers = {
    'on_pass' => sub { my $mod = shift @_; $mod->on_pass( @_ ); },
    'on_fail' => sub { my $mod = shift @_; $mod->on_fail( @_ ); },
    'header' => sub { my $mod = shift @_; $mod->header( @_ ); }
};

## These are keywords used as paramter names in a value. We handle this
## differently. The values below are default values.
my $special_filter_parts = {
			    'force_pass' => 0,
			    'force_fail' => 0
};

sub filter_tab_file {
    my ($tab, $filter_conf, $filter_opts) = @_;

    &_debug("Parsing tab file [$tab] with filter config [$filter_conf]");

    my ($filters, $handlers, $expected_headers) = &_parse_filters_conf( $filter_conf );

    # Will hold the indexes for the headers
    my $headers_indices = {};

    # Process each filter for each for
    my $fh = PGDX::open_file( $tab, 'in' );
    my $rowcnt=0;
    while( my $row = <$fh> ) {
        chomp($row);

        if( $rowcnt==0 ) {
            # If we have a header handler, handle the header.
            my @header_cols = split(/\t/, $row, -1);

            # Create header index. Important we do this before calling the handler
            $headers_indices = PGDX::getHeaderIndex( \@header_cols, $expected_headers, 1, 1 );

            if( exists( $handlers->{'header'} ) ) {
                @header_cols = $handlers->{'header'}->({'headers' => \@header_cols, 'filter_opts'=> $filter_opts});
            }
            $rowcnt++;
            next;
        }

        my @values = split(/\t/,$row, -1);

        # Let's be optimistic and default to pass
        my $row_passes = 1;

        # Stores the name of failed filters
        my @failed_filters;

        # Cycle through each filter and see if it passes. If not, store the name
        foreach my $filter ( @{$filters} ) {
            my $pass = &_filter_passes( $filter, \@values, $headers_indices ); 
        
            ## force_pass = 1; This means if it passes this filter, the row should pass
            ## regardless of any other filters. If a row has failed filters already,
            ## the row should still be passed. This does short circuit the filter processing
            ## so some filters may not be processed. Don't fail row if force_pass filter fails.
            if( $filter->{'force_pass'} ) {
                if( $pass ) {
                    &_debug("Force passing row for filter $filter->{'filter_name'}");
                    $row_passes = 1;
                    last;
                } else {
                    next;
                }
            }elsif( $filter->{'force_fail'}){
                if( $pass ) {
                    &_debug("Force failing row for filter $filter->{'filter_name'}");
                    $row_passes = 0;
                    last;
                } else {
                    next;
                }
            }

            if( !$pass ) {
                push(@failed_filters, $filter->{'filter_name'});
                $row_passes = 0;
            }
        }

        if( $row_passes && exists( $handlers->{'on_pass'} ) ) {
            @values = $handlers->{'on_pass'}->({ 'row' => \@values, 'headers' => $headers_indices, 'filter_opts' => $filter_opts}  );
        } elsif( !$row_passes && exists( $handlers->{'on_fail'} ) ) {
            @values = $handlers->{'on_fail'}->({ 
                'row' => \@values, 
                'failed_filters' => \@failed_filters, 
                'headers' => $headers_indices, 
                'filter_opts'=> $filter_opts
            });
        }
        $rowcnt++;
    }
    close($fh);

}

# A set of values fails the filter if any of the filter parts
# fail.
sub _filter_passes {
    my ($filter, $values, $header_indices) = @_;
    
    # Assume we pass
    my $pass = 1;

    foreach my $filter_part_key ( keys %{$filter->{'filter_parts'}} ) {
        my $filter_part = $filter->{'filter_parts'}->{$filter_part_key};
        unless( &_filter_part_passes( $filter_part, $values, $header_indices ) )  {
            $pass = 0;
        }
    }

    return $pass;
}

## Will return true if values pass filter part
# Processed filter parts are just subroutines
sub _filter_part_passes {
    my ($filter_part, $values, $headers_indices) = @_;
    my $pass = 1;
    unless( $filter_part->( $values, $headers_indices ) ) {
        $pass = 0;
    }
    return $pass;
}

sub _parse_filters_conf {
    my ($file) = @_;
    my @ret;

    my @expected_headers = ();

    &_debug( "Parsing filter config: $file" );
    my $fh = PGDX::open_file( $file, 'in' );
    my $cfg = new Config::IniFiles( -file => $fh );
    unless( defined( $cfg ) ) {
        die("Issues with config: ".Dumper( \@Config::IniFiles::errors ) );
    }

    # Parse handlers
    my $handlers = &_parse_filter_handlers( $cfg );

    foreach my $filter_name ( $cfg->Sections() ) {

        next if( $filter_name eq $HANDLER_SECTION_NAME ); 

        my $filter = {
            'filter_name' => $filter_name,
            'filter_parts' => {},
            'filter_display' => {}
        };

		## Add special filter part defaults to hash
		foreach my $key ( keys %{$special_filter_parts} ) {
			$filter->{$key} = $special_filter_parts->{$key};
		}

        foreach my $filter_part ( $cfg->Parameters( $filter_name ) ) {
            my $filter_part_val = $cfg->val($filter_name, $filter_part);

			## Here we handle special parameters for a filter. Example
			## is force_pass, meaning if the filter passes, the row should
			## pass and no more filters should be processed on that row.
			if( exists( $special_filter_parts->{$filter_part} ) ) {
				$filter->{$filter_part} = $filter_part_val;
			} else {
				
				## We've found an actual filter.
				## Grab any headers which are used in the value.
				my @filter_part_headers = &_get_expected_headers( $filter_part_val );
				push(@expected_headers, @filter_part_headers);

				my $filter_part_coderef;
				## Parse the value and turn it into a subroutine.
				eval {
					$filter_part_coderef = &_parse_filter_part( $filter_part_val, $filter_name, $filter_part );
				};
				if( $@ ) {
					die("Failed parsing filter_part $filter_name.$filter_part: $@");
				}


				$filter->{'filter_parts'}->{$filter_part} = $filter_part_coderef;
			}
        }

        push( @ret, $filter );
    }
    close($fh);

    return (\@ret, $handlers, \@expected_headers);
}

# Create a subroutine.
sub _parse_filter_part {
    my ($filter_val, $filter_name, $filter_part) = @_;

    # Make a copy of the original filter value in case 
    # we need it later;
    my $orig_filter_val = $filter_val;

    # Any "variables" here are actually column names
    my $tmp = $filter_val;
    while( $tmp =~ /\$;(.*?)\$;/g ) {
        my $col_name = $1;
        $filter_val =~ s/\$;\Q$col_name\E\$;/\$_[0]->[\$_[1]->{'$col_name'}]/;
    }
  
    # Turning off warnings in the subroutines. Should catch these somehow and display to user
    # what's wrong with the filter comparisons to be able to fix them.
    # I think you can do that somehow with %SIG hash, although how that works with eval'd code
    # references will need to be explored.
    my $ret_coderef = sub { 0 };

	## Module with a dispatch method
    if( $filter_val =~ /^module\(([^\)]+)\)/ ) {
		my $module = $1;
		$module=~s/\;$//; # Remove trailing semi-colon if present.
		load($module);
		$ret_coderef = sub {
			$module->dispatch( $filter_name, $filter_part, @_ );
		};
	} else {
		# Try eval'ing the code now, to see if we get any errors. Tack on a return 1
		# to the beginning so we don't actually run the code, just compile it to make
		# sure it's valid perl syntax.
		my $check_syntax = sub {
			my $results = eval( qq(return 1; $_[0]) );
			die($@) unless( defined( $results ) );
		};

		if( $filter_val =~ /^sub/ ) {
			$check_syntax->($filter_val);
			$ret_coderef = sub {
				no warnings;
				my $sub_ref = eval( $filter_val ); 
				$sub_ref->(@_); 
			}

		} else {
			$check_syntax->($filter_val);
			$ret_coderef = sub { 
				no warnings;
				eval($filter_val) 
			};
		}
	}
    
    return $ret_coderef;
}


sub _parse_filter_handlers {
    my ($cfg) = @_;

    my $handlers = {};

    foreach my $param ( $cfg->Parameters( $HANDLER_SECTION_NAME ) ) {
        if( exists( $accept_handlers->{$param} ) ) {
            my $val = $cfg->val($HANDLER_SECTION_NAME, $param);
            if( $val =~ /^sub/ ) {
                $handlers->{$param} = eval($val);
                unless( $handlers->{$param} ) {
                    die("Error in evaluating handler $param: $@");
                }
            } else {
                # Assume it's a module name
                my $module = $val;
				$module=~s/\;$//; # Remove trailing semi-colon if present.
                load($module);
                $handlers->{$param} = sub {
                    $accept_handlers->{$param}->($module, @_);
                };
            }
        }
    }

    return $handlers;
}

sub _get_expected_headers {
    my ($filter_part_value) = @_;
    my @retval = ();
    while( $filter_part_value =~ /\$;(.*?)\$;/g ) {
        push(@retval, $1);
    }
    return @retval;
}
sub _debug {
    my ($msg) = @_;
    print STDERR $msg."\n" if( $DEBUG );
}

1;
