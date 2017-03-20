#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Storable;
use Data::Dumper;
use REST::Client;
use JSON;
use File::Basename;
my $dirname = dirname(__FILE__);
my $filename = $dirname . "/pgdxids.dat";
my $URL = "http://pgdx-util/utils/pgdxids.dat";
my $client = REST::Client->new();
$client->setContentFile( $filename );
$client->GET($URL)->responseContent();
my $href = retrieve($filename, {binmode=>':raw'});
my $json = encode_json \%$href;
print $json;
