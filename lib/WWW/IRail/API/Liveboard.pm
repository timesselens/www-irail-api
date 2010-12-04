package WWW::IRail::API::Liveboard;
use strict;
use Carp qw/croak/;
use HTTP::Request::Common;
use JSON::XS;
use XML::Simple;
use YAML qw/freeze/;

our $url_base = $ENV{IRAIL_BASE} || 'http://dev.api.irail.be';

sub make_request {
    my %attr = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    $attr{station} ||= $attr{from} || $attr{to};
    $attr{direction} ||= $attr{dir} || $attr{from} ? 'DEP' : $attr{to} ? 'ARR' : 'DEP';
    $attr{direction} =~ s/^(arr|dep).*/\U$1/i;
    
    croak 'too few arguments' unless $attr{station};

    my %urimap = ( direction => 'arrdep' );

    my $url = $url_base .'/liveboard/?'.
                join '&', map { ($urimap{$_} || $_) .'='.$attr{$_} } 
                qw/station direction/;

    my $req = new HTTP::Request(GET => $url);

    return $req;
}

sub parse_response {
    my ($http_response, $dataType) = @_;

    my $obj = XMLin($http_response->content,
        NoAttr => $dataType eq 'XML' ? 0 : 1,
        SuppressEmpty => 1,
        NormaliseSpace => 2,
        ForceArray => [ 'departure', 'arrival' ],
        KeyAttr => [],
        GroupTags => { departures => 'departure', arrivals => 'arrival' },
    );

    ($obj->{timestamp}) = ($http_response->content =~ m/timestamp="(\d+)"/);

    for ($dataType) {
        /xml/i and return XMLout $obj, RootName => 'liveboard', GroupTags => { departures => 'departure', arrivals => 'arrival' };
        /json/i and return JSON::XS->new->ascii->pretty->allow_nonref->encode($obj);
        /yaml/i and return freeze $obj;
        /perl/i and return $obj;
    }

    return $obj; # default to perl

}

42;

__END__

=head1 NAME

WWW::IRail::API::Liveboard - HTTP::Request builder and HTTP::Response parser for the IRail API Liveboard data

=head1 SYNOPSIS

    make_request ( station => 'oostende' );     # departures by default

    make_request ( to => 'oostende' );          # arrivals coming into oostende

=head1 DESCRIPTION

This module builds a L<HTTP::Request> and has a parser for the
L<HTTP::Response>. It's up to you to transmit it over the wire. If don't want
to do that yourself, don't use this module directly and use L<WWW::IRail::API>
instead.

=head1 METHODS

=method make_request( I<key => 'val'> | I<{ key => 'val' }> )

Only the C<station> argument is required, but if you either use C<to> or C<from> it will be seen as
the station name with the direction set accordingly. Memento: trains leaving B<from> => 'oostende' and
trains arriving inB<to> => 'oostende'. If the direction could not be deduced it defaults to C<'departures'>

    make_request ( from => 'oostende' );

    make_request ( station => 'oostende', direction => 'departures' );

    make_request ( { station => 'oostende', dir => 'arr' } );

the API direction parameter is extracted from your input using C<m/(arr|dep)/i>
so you can choose between less typing or better readability.

=method parse_response( I<$http_response>, I<dataType> )


rses the HTTP::Response you got back from the server, which if all went well contains XML.
That XML is then transformed into other data formats

=for :list
* xml
* XML
* YAML
* JSON
* perl (default)
                                                                                                                                                                  
=head3 example of output when dataType = 'xml'

    <liveboard station="MOLLEM" timestamp="1291044188">
      <departures>
        <departure platform="1" station="DENDERMONDE" time="1291043100" vehicle="BE.NMBS.CR1564" />
        <departure platform="1" station="DENDERMONDE" time="1291044480" vehicle="BE.NMBS.CR5316" />
        <departure platform="2" station="GERAARDSBERGEN" time="1291046100" vehicle="BE.NMBS.CR1588" />
        <departure platform="1" station="DENDERMONDE" time="1291046700" vehicle="BE.NMBS.CR1565" />
      </departures>
    </liveboard>

=head3 example of output when dataType = 'XML'

    <liveboard timestamp="1291044222" version="1.0">
      <departures name="departure" number="4">
        <departure id="0" delay="1200" vehicle="BE.NMBS.CR1564">
          <platform normal="1">1</platform>
          <station id="BE.NMBS.137" locationX="4.101431" locationY="51.022775">DENDERMONDE</station>
          <time formatted="2010-11-29T15:05:00Z">1291043100</time>
        </departure>
        <departure id="1" delay="1140" vehicle="BE.NMBS.CR5316">
          <platform normal="1">1</platform>
          <station id="BE.NMBS.137" locationX="4.101431" locationY="51.022775">DENDERMONDE</station>
          <time formatted="2010-11-29T15:28:00Z">1291044480</time>
        </departure>
        <departure id="2" delay="0" vehicle="BE.NMBS.CR1588">
          <platform normal="1">2</platform>
          <station id="BE.NMBS.210" locationX="3.871956" locationY="50.771025">GERAARDSBERGEN</station>
          <time formatted="2010-11-29T15:55:00Z">1291046100</time>
        </departure>
        <departure id="3" delay="0" vehicle="BE.NMBS.CR1565">
          <platform normal="1">1</platform>
          <station id="BE.NMBS.137" locationX="4.101431" locationY="51.022775">DENDERMONDE</station>
          <time formatted="2010-11-29T16:05:00Z">1291046700</time>
        </departure>
      </departures>
      <station id="BE.NMBS.376" locationX="4.21675" locationY="50.932808">MOLLEM</station>
    </liveboard>

=head3 example of output when dataType = 'YAML'

    ---
    departures:
      - platform: 1
        station: DENDERMONDE
        time: 1291043100
        vehicle: BE.NMBS.CR1564
      - platform: 1
        station: DENDERMONDE
        time: 1291044480
        vehicle: BE.NMBS.CR5316
      - platform: 2
        station: GERAARDSBERGEN
        time: 1291046100
        vehicle: BE.NMBS.CR1588
      - platform: 1
        station: DENDERMONDE
        time: 1291046700
        vehicle: BE.NMBS.CR1565
    station: MOLLEM
    timestamp: 1291044267

=head3 example of output when dataType = 'JSON'

    {
       "departures" : [
          {
             "station" : "DENDERMONDE",
             "time" : "1291043100",
             "vehicle" : "BE.NMBS.CR1564",
             "platform" : "1"
          },
          {
             "station" : "DENDERMONDE",
             "time" : "1291044480",
             "vehicle" : "BE.NMBS.CR5316",
             "platform" : "1"
          },
          {
             "station" : "GERAARDSBERGEN",
             "time" : "1291046100",
             "vehicle" : "BE.NMBS.CR1588",
             "platform" : "2"
          },
          {
             "station" : "DENDERMONDE",
             "time" : "1291046700",
             "vehicle" : "BE.NMBS.CR1565",
             "platform" : "1"
          }
       ],
       "station" : "MOLLEM",
       "timestamp" : "1291044295"
    }

=head3 example of output when dataType = 'perl'

    {
          'departures' => [
                          {
                            'station' => 'DENDERMONDE',
                            'time' => '1291043100',
                            'vehicle' => 'BE.NMBS.CR1564',
                            'platform' => '1'
                          },
                          {
                            'station' => 'DENDERMONDE',
                            'time' => '1291044480',
                            'vehicle' => 'BE.NMBS.CR5316',
                            'platform' => '1'
                          },
                          {
                            'station' => 'GERAARDSBERGEN',
                            'time' => '1291046100',
                            'vehicle' => 'BE.NMBS.CR1588',
                            'platform' => '2'
                          },
                          {
                            'station' => 'DENDERMONDE',
                            'time' => '1291046700',
                            'vehicle' => 'BE.NMBS.CR1565',
                            'platform' => '1'
                          }
                        ],
          'station' => 'MOLLEM',
          'timestamp' => '1291044344'
   };

=cut

































