=head1 NAME

PGDX::Tag.pm

=head1 DESCRIPTION

Functions to tag output files

=head1 AUTHOR

David Riley

driley@personalgenome.com

=cut

package PGDX::Tag;
use strict;
use PGDX::SampleSheet;
use JSON;
use URI::Escape;
use File::Basename;

# This function will take a service, host and config and submit the request. 
# It will then return the result in json
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
        my $ret_string = `curl -s -d $body $url`;
        if($?) {
            print STDERR "ERROR: Unable to connect to $host\n$ret_string\n";
        }
        else {
            my $res = from_json($ret_string);
            $ret = $res;
            if($res->{success}) {
                print STDERR "Success running service\n";
            }            
            else {
                print STDERR "Unable to run service!\n".(to_json($res,{pretty => 1}))."\n";
            }
        }
#    }    
    
    return $ret;
}

# This function will take a service, host and config and submit the request. 
# It will then monitor the resulting task for success.
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
        my $res = from_json(`curl -s -d $body $url`);
        if($res->{success}) {
            print STDERR "Successfully submitted $service\n";
        }
        else {
            print STDERR "Unable to tag $service!".Dumper($res)."\n";
        }
#    }
}
##### 

sub list_files {
    my $dir = shift;
    my $host = shift;

    my $returnlist = &PGDX::Tag::submit_and_return('listFiles_ws.py',$host,{
        'name' => 'local',
        'path' => $dir
    });

    ## Making this a list reference so undefined and empty 
    ## are different. (my @a and my @a = () are equivalent).
    my $retfiles;
    if( defined( $returnlist ) ) {
        my $files = $returnlist->{data};
   
        $retfiles = []; 
        foreach my $f (keys (%$files)) {
            push(@{$retfiles},"$dir/$f");
        }
    }
    return $retfiles;
}

sub get_tag {
    my $tagname = shift;
    my $host = shift;

    my $config = {
        'cluster'=> 'local',
        'detail'=>  JSON::true,
        'criteria' => {'tag_name'=> $tagname}
    };

    my $ret = &submit_and_return('tag_list',$host,$config);
    # Pull the data array out
    my $taglist = $ret->{data};

    return $taglist;
}

# Check that a tag exists on a host
sub check_tag_exists {
    my $tagname = shift;
    my $host = shift;

    my $config = {
        'cluster'=> 'local',
        'criteria' => {'tag_name'=> $tagname}
    };

    my $ret = &submit_and_return('tag_list',$host,$config);
    # Pull the data array out
    my $taglist = $ret->{data};
    my $tag = 0;
    if(scalar @$taglist > 0) {
        $tag = 1
    }
    else {
        print STDERR "Looks like I didn't find $tagname on $host\n";
        $tag = 0;   
    }

    return $tag;
}

# Overwrite the values in a placeholder
sub update_placeholder {
    my $tag = shift;
    my $host = shift;

    if(!$tag->{'tag_name'}) {
        die "Could not create tag because no tag name was passed\n";
    }
    
    $tag->{'action'} = 'overwrite';
    $tag->{'metadata'}->{'placeholder'} = 'True';
    return &submit_and_return('tag_createupdate',$host,$tag);
}

# Create a new placeholder tag 
sub create_placeholder {
    my $tag = shift;
    my $host = shift;
    
    if(!$tag->{'tag_name'}) {
        die "Could not create tag because no tag name was passed\n";
    }
    
    $tag->{'action'} = 'create';
    $tag->{'metadata'}->{'placeholder'} = 'True';
    return &submit_and_return('tag_createupdate',$host,$tag);
}

# Overwrite a tag
sub update_tag {
    my $tag = shift;
    my $host = shift;

    if(!$tag->{'tag_name'}) {
        die "Could not create tag because no tag name was passed\n";
    }
    
    $tag->{'action'} = 'overwrite';
    $tag->{'metadata'}->{'placeholder'} = 'False';
    return &submit_and_return('tag_createupdate',$host,$tag);
}

# Create a new tag
sub create_tag {
    my $tag = shift;
    my $host = shift;
    $tag->{'action'} = 'create';

    if(!$tag->{'tag_name'}) {
        die "Could not create tag because no tag name was passed\n";
    }
    
    $tag->{'metadata'}->{'placeholder'} = 'False';
    return &submit_and_return('tag_createupdate',$host,$tag);
}

# Remove a tag
sub remove_tag {
    my $tag = shift;
    my $host = shift;

    if(!$tag->{'tag_name'}) {
        die "Could not create tag because no tag name was passed\n";
    }
           
    &submit_and_return('tag_delete',$host,$tag);
}

sub get_tags_from_outputdir {
    my $config = shift;

    my $tagsuffix = $config->{tagsuffix};
    my $files = $config->{files};
    my $sample = $config->{sample};
    my $metadata = $config->{metadata};
    my $newstyle = $config->{newstyle};
    my $tags = {};

    foreach my $f (@$files) {
        chomp $f;
        if($f =~ /export.txt/) {
            chomp $f;
            my ($name,$path,$suff) = fileparse($f, '.txt.gz','.txt');
            my @fields = split('_',$name);
                          
            # Try both instead possible export file formats
            my $miseqtag = join('_',@fields[0 .. (scalar @fields - 5)]);
            my $hiseqtag = join('_',@fields[0 .. (scalar @fields - 4)]);
            my $newtag = join('_',@fields[0 .. (scalar @fields - 3)]); #Assuming only _R1_export.txt.gz

            # Default to the hiseqtag
            my $tag = $hiseqtag;

            # Check for the lane field. If the lane field is present then we have
            # miseq style output files.
            if($f =~ /_L\d{3}_R\d_export.txt/) {            
                $tag = $miseqtag;
            
            }
            
            # Add a tagsuffix if we have one.
            $tag .= $tagsuffix;
            $newtag .= $tagsuffix;
            if($newstyle || ($sample && $sample eq $newtag)) {
                $tag = $newtag;
            } 
            # If a sample is passed, check that this file is for that sample
            if(!$sample || ($sample && ($sample eq $tag))) {
                if(!$tags->{$tag}) {
                    $tags->{$tag} = {
                        tag_name => $tag,
                        metadata => $metadata,
                        files => []
                    };
                }
                push(@{$tags->{$tag}->{files}}, $f);
            }
#         If there were no tags then try looking for bam. This is  HACK.
#         if(! keys %$tags && $suffix ne 'bam*') {
#             my $sf = '.bam*';
#             my $od = "$outputdir/$relative/";
#             $od =~ s/\/export/\/bam/; # Huge hack here.
#             print STDERR "Checking $od/\*$sf\n";
#             my $ssh = "ssh -i /mnt/keys/vappio_00 -q $ssh_opts $execuser\@$exechost ls $od/\*$sf";
#             @files = `$ssh`;
#             if($options{sample} && $options{sample} =~ /novo/) {
#                 $found_bam = 1;
#             }
#     
#         }
        }
        elsif($f =~ /\.bam/) {
            my $tagname = fileparse($f,'.bam','.bam.bai');

            # Add a tagsuffix if we have one.
            $tagname .= $tagsuffix;
            
            # If a sample is passed then check that this file is for that sample
            if(!$sample || ($sample && $f =~ /${sample}.bam/)) {
                if(!$tags->{$tagname}) {
                    $tags->{$tagname} = {
                        tag_name => $tagname,
                        metadata => $metadata,
                        files => []
                    };
                }
                print "Adding $f to $tagname\n";
                push(@{$tags->{$tagname}->{files}}, $f);
            }
        }
        elsif($f =~ /\.fastq/ || $f =~ /.fq/) {
            my ($tagname,$dir,$suff) = fileparse($f,qr/_?R\d.fastq.*/,qr/_?R\d.fq.*/);

            # Add a tagsuffix if we have one.
            $tagname .= $tagsuffix;
            
            # This is a HACK right now but is at least necessary for now.
            $tagname .= '_fastq'; 

            # If a sample is passed then check that this file is for that sample
            #
            # KG: Will this ever work when a sample name is passed in? You would need
            # to add SAMPLE_suffix_fastq to the option for this to work since
            # the tagname is modified before checking it against the sample name.
            if(!$sample || ($sample && $tagname eq $sample)) {
                if(!$tags->{$tagname}) {
                    $tags->{$tagname} = {
                        tag_name => $tagname,
                        metadata => $metadata,
                        files => []
                    };
                }
                print "Adding $f to $tagname\n";
                push(@{$tags->{$tagname}->{files}}, $f);
            }
        
        }
    }
    my $return_tags = [];
    foreach my $tname (sort keys %$tags) {
        push(@$return_tags, $tags->{$tname});
    }
    return $return_tags;

}


1;
