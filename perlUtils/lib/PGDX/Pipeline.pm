=head1 NAME

PGDX::Pipeline.pm

=head1 DESCRIPTION

Functions to submit/configure pipelines

=head1 AUTHOR

David Riley

driley@personalgenome.com

=cut

package PGDX::Pipeline;
use strict;
use JSON;
use URI::Escape;
use Data::Dumper;

# Takes a config object of the following format and returns a complete 
# pipeline config give the presets and params
# {
#  protocol => 'pgdx_alignment_v1',
#  host => 'pgdx-pr1',
#  params => {
#    input.INPUT_TAG => 'TEST_RUN_1',
#    pipeline.DESC => 'A Test Pipeline',
# }}
# 
# The return value is a config object that can be passed directly to the run_pipeline subroutine
sub configure_pipeline {
    my $config = shift;
    my $protocol = $config->{protocol};
    my $preset = $config->{preset};
    my $host = $config->{host};
    my $params = $config->{params};
    my $opts = &get_protocol_config($config);

    # Set defaults
    my $pipe_config;
    foreach my $op (@$opts) {
    
        if(exists $config->{params}->{$op->{name}}) {
            $pipe_config->{$op->{name}} = $config->{params}->{$op->{name}};
        }
        elsif($op->{value}) {
            print  "$op->{name}: $op->{value}\n";
            $pipe_config->{$op->{name}} = "$op->{value}";
        }
        else {
            $pipe_config->{$op->{name}} = "$op->{default}"
        }
    }
    
    # This is a hack to correct a bug in the vappio backend.
    if($preset && $pipe_config->{'pipeline.PRESETS_USED'} eq '') {
        $pipe_config->{'pipeline.PRESETS_USED'} = join(',',@$preset);
    }
    return $pipe_config;
}

# Takes a hash with the following format and submits the pipeline to the specified host
# {
#  host => 'pgdx-pr1',
#  pipeconfig => {
#    param1 => val1,
#    param2 => val2,
# }}
sub run_pipeline {
    my $config = shift;
    my $overwrite = shift;
    my $request;
    if($overwrite eq "true"){
		print "OVERWRITING\n";
		$request = {
			config => $config->{pipeconfig},
			 bare_run => JSON::false,
			 overwrite => JSON::true,
			 run_mode => 'now',
			 cluster => "local"
		};
	}else{
		print "NOT OVERWRITING\n";
		$request = {
			config => $config->{pipeconfig},
			 bare_run => JSON::false,
			 overwrite => JSON::true,
			 run_mode => 'now',
			 cluster => "local"
		};
    }
    my $ret = &submit_and_return('pipeline_run',$config->{host},$request);

    return $ret;

}

# Takes a config object of the following format and returns the config populated 
# with the specified presets. The config is a key/value hash.
# {'protocol' => 'pgdx_alignment_v1',
#  'host' => 'pgdx-pr1'
#  }
sub get_protocol_config {
    my $config = shift;
    my $host = $config->{host};
    my $protocol = $config->{protocol};
    my $opts = {};
    
    my $prots = &submit_and_return('protocol_list',$host,{
        cluster=>'local',
        detail=>'Simple',
        protocol=>$protocol,
        preset=>$config->{preset}});
        
    foreach my $p (@{$prots->{data}}) {
        if($p->{protocol} eq $protocol) {
            $opts = $p->{config};
        }
    }
    return $opts;

}

# This function will take a service, host and config and submit the request. It will return
# the object given back by the webservice.
# config should look something like this:
#     my $tag_config = {
#        'cluster'=> 'local',
#        'action'=> 'create',
#        'tag_name' => $run_name,
#        'metadata' => {
#            'description' => $run_name,
#            'format_type' => 'bcl'
#        }
#    };
sub submit_and_return {
    my $service = shift;
    my $host = shift;
    my $config = shift;

    if(!$config->{'cluster'}) {
        $config->{'cluster'} = 'local';
    }

    my $url = "http://$host/vappio/$service";
    print STDERR "http://$host/vappio/$service?request=".encode_json($config)."\n";
    my $body = "request=".uri_escape(encode_json($config));
    
    my $ret;
#    if(!$options{do_not_run}) {
		my $pid = $$;
		my $bodyfile = "/tmp/$pid.body.txt";
		open OUT, ">", $bodyfile or die "Unable to write body file";
		print OUT "$body";
		close OUT;
        my $ret_string = `curl -s -d \@$bodyfile $url`;
        if($?) {
            print STDERR "ERROR: Unable to connect to $host\n$ret_string\n";
        }
        else {
            $ret = from_json($ret_string);
            if($ret->{success}) {
                print STDERR "Success running service\n";
            }            
            else {
                print STDERR "Unable to run service!\n".(to_json($ret,{pretty => 1}))."\n";
            }
        }
#    }    
    
    return $ret;
}

# Reads a config from a flat file. Assumes a 2 column file with key/value
sub read_config_file {
    my $config = shift;

    my $config_opts = {};
    open IN, "<$config" or die "Unable to open $config\n";
    while(my $line = <IN>) {
        chomp $line;
        my @fields = split(/\t/,$line);
        my $val = $fields[1] ? $fields[1] : '';
        $config_opts->{$fields[0]} = $val;
    }
    close IN;
    
    return $config_opts;
}


##### NOT COMPLETE YET ######
sub submit_and_monitor {
    my $service = shift;
    my $host = shift;
    my $config = shift;
    
    if(!$config->{'cluster'}) {
        $config->{'cluster'} = 'local';
    }
    
    my $url = "http://$host/vappio/$service";
    print "http://$host/vappio/$service?request=".encode_json($config)."\n";
    my $body = "request=".uri_escape(encode_json($config));
#    if(!$options{do_not_run}) {
		my $pid = $$;
		my $bodyfile = "/tmp/$pid.body.txt";
		open OUT, ">", $bodyfile or die "Unable to write body file";
		print OUT "$body";
		close OUT;
        my $res = from_json(`curl -s -d \@$bodyfile $url`);
        if($res->{success}) {
            print STDERR "Successfully submitted $service\n";
        }
        else {
            print STDERR "Unable to tag $service!".Dumper($res)."\n";
        }
#    }
}
##### 



1;
