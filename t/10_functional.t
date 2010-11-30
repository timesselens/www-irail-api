use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Dumper;
use JSON::XS;
use WWW::IRail::API qw/irail/;
use WWW::IRail::API::Client::LWP;
  
#########################################################################################################
# setup
#########################################################################################################
use_ok('WWW::IRail::API::Client::LWP');

my $irail = new WWW::IRail::API;

#########################################################################################################
# test setup
#########################################################################################################
isa_ok($irail,'WWW::IRail::API');

#########################################################################################################
# station tests
#########################################################################################################

my $irail_0 = new WWW::IRail::API;

## lookup all ...........................................................................................
my $stations_0 = $irail_0->lookup_stations();

ok(ref $stations_0 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_0 > 100, "there must be at least a hundred stations");
ok((grep { /brussel noord/i } (@$stations_0)), "brussel noord (NL) must be one of them");
ok((grep { /brussels nord/i } (@$stations_0)), "brussel nord (EN) must be one of them");
ok((grep { /brussel nord/i } (@$stations_0)), "brussel nord (FR) must be one of them");

## lookup using sub as filter ...........................................................................
my $stations_1 = $irail_0->lookup_stations( filter => sub { /brussel/i } );

ok(ref $stations_1 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_1 > 2, "there must be at least two stations with brussel in their name");
ok((grep { /brussel noord/i } (@$stations_1)), "brussel noord (NL) must be in the partial set");
ok((grep { /brussel nord/i } (@$stations_1)), "brussel nord (FR) must be in the partial set");
ok((grep { /brussels nord/i } (@$stations_1)), "brussel nord (EN) must be in the partial set");
ok((not grep { /oostende/i } (@$stations_1)), "oostende must not be in the set");

## lookup using qr// as a filter ........................................................................
my $stations_2 = $irail_0->lookup_stations( filter => qr/brussel/i );

ok(ref $stations_2 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_2 > 2, "there must be at least two stations with brussel in their name");
ok((grep { /brussel noord/i } (@$stations_2)), "brussel noord (NL) must be in the partial set");
ok((grep { /brussel nord/i } (@$stations_2)), "brussel nord (FR) must be in the partial set");
ok((grep { /brussels nord/i } (@$stations_2)), "brussel nord (EN) must be in the partial set");
ok((not grep { /oostende/i } (@$stations_2)), "oostende must not be in the set");

## lookup using string as a filter ......................................................................
my $stations_3 = $irail_0->lookup_stations( filter => "brussel" );

ok(ref $stations_3 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_3 > 2, "there must be at least two stations with brussel in their name");
ok((grep { /brussel noord/i } (@$stations_3)), "brussel noord (NL) must be in the partial set");
ok((grep { /brussel nord/i } (@$stations_3)), "brussel nord (FR) must be in the partial set");
ok((grep { /brussels nord/i } (@$stations_3)), "brussel nord (EN) must be in the partial set");
ok((not grep { /oostende/i } (@$stations_3)), "oostende must not be in the set");

## return type JSON .....................................................................................
my $json = $irail_0->lookup_stations( filter => "brussel", dataType => 'JSON');

my $obj = decode_json ($json);
ok($obj, "object exists");
ok($obj->{station}, "station key exists in json object");
ok(ref $obj->{station} eq "ARRAY", "station key holds an array");

my $stations_4 = [@{$obj->{station}}];
ok(ref $stations_4 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_4 > 2, "there must be at least two stations with brussel in their name");
ok((grep { /brussel noord/i } (@$stations_4)), "brussel noord (NL) must be in the partial set");
ok((grep { /brussel nord/i } (@$stations_4)), "brussel nord (FR) must be in the partial set");
ok((grep { /brussels nord/i } (@$stations_4)), "brussel nord (EN) must be in the partial set");
ok((not grep { /oostende/i } (@$stations_4)), "oostende must not be in the set");

done_testing();

