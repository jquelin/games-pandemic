use 5.010;
use strict;
use warnings;

package Games::Pandemic::Map;
# ABSTRACT: pandemic map information

use File::Spec::Functions qw{ catdir catfile };
use Moose;
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Card::City;
use Games::Pandemic::Card::Special::Airlift;
use Games::Pandemic::Card::Special::GovernmentGrant;
use Games::Pandemic::Card::Special::OneQuietNight;
use Games::Pandemic::Card::Special::ResilientPopulation;
use Games::Pandemic::City;
use Games::Pandemic::Disease;
use Games::Pandemic::Utils;

# -- accessors

has _cities => (
    metaclass  => 'Collection::Array',
    is         => 'ro',
    isa        => 'ArrayRef[Games::Pandemic::City]',
    builder    => '_cities_builder',
    lazy       => 1,  # _diseases() needs to be built before
    auto_deref => 1,
    provides   => {
        elements => 'all_cities',       # my @c = $map->all_cities;
        get      => 'city',             # my $c = $map->city(23);
        find     => '_find_city',
    }
);

has _diseases => (
    metaclass  => 'Collection::Array',
    is         => 'ro',
    isa        => 'ArrayRef[Games::Pandemic::Disease]',
    builder    => '_diseases_builder',
    auto_deref => 1,
    provides   => {
        elements => 'all_diseases',     # my @d = $map->all_diseases;
        get      => 'disease',          # my $d = $map->disease(0);
    },
);

has max_infections => ( is => 'ro', isa => 'Int', lazy_build => 1 );

has name => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_name',
);

has start_city => (
    is       => 'ro',
    isa      => 'Games::Pandemic::City',
    builder  => '_start_city_builder',
    lazy     => 1, # _cities needs to be built before
    weak_ref => 1,
);

has start_diseases => ( is=>'ro', isa=>'ArrayRef[Int]', auto_deref=>1, lazy_build => 1 );


# -- default builders / finishers


sub DEMOLISH {
    my $self = shift;
    debug( "~map: " . $self->name . "\n" );
}


sub _cities_builder {
    my $self = shift;

    my @cities;
    foreach my $d ( $self->_raw_cities ) {
        my ($name, $disid, $xreal, $yreal, $x, $y, $neighbours) = @$d;
        my $disease = $self->disease($disid);
        my $city = Games::Pandemic::City->new(
            id      => scalar(@cities),
            name    => $name,
            xreal   => $xreal,
            yreal   => $yreal,
            coordx  => $x,
            coordy  => $y,
            disease => $disease,
            _map    => $self,
            neighbour_ids => $neighbours,
        );
        push @cities, $city;
    }
    return \@cities;
}

sub _diseases_builder {
    my $self = shift;

    my @diseases;
    foreach my $d ( $self->_raw_diseases ) {
        my ($id, $name, $colors, $nb) = @$d;
        my $disease = Games::Pandemic::Disease->new(
            name   => $name,
            colors => $colors,
            nbmax  => $nb,
            id     => $id,
            _map   => $self,
        );
        push @diseases, $disease;
    }
    return \@diseases;
}


sub _start_city_builder {
    my $self = shift;
    my $id   = $self->_raw_start_city;
    my $city = $self->city($id);
    $city->build_station;
    return $city;
}


# -- public methods

=method my $bgpath = $map->background_path;

Return the path the background image of the map.

=cut

sub background_path {
    my $self = shift;
    return catfile( $self->sharedir, 'background.jpg' );
}


=method my $dir = $map->sharedir;

Return the path to the private directory C<$dir> where C<$map> stores
various files.

=cut

sub sharedir {
    my $self = shift;
    return catdir( $SHAREDIR, 'maps', $self->name );
}


=method my @cards = $map->cards;

Return a list of C<Games::Pandemic::Card>: special event cards depending
on the map, plus one card per city defined in the map. They will be used
for the regular deck. Note that the cards will B<not> be shuffled.

=cut

sub cards {
    my $self = shift;
    my @citycards =
        map { Games::Pandemic::Card::City->new(city=>$_) }
        $self->all_cities;
    my @special =
        map { my $class = "Games::Pandemic::Card::Special::$_"; $class->new }
        $self->_raw_special_cards;
    return (@citycards, @special);
}


=method my @cards = $map->disease_cards;

Return a list of C<Games::Pandemic::Card::City>, one per city defined in
the map. They will be used for the infection deck. Note that the cards
will B<not> be shuffled.

=cut

sub disease_cards {
    my $self = shift;
    return
        map { Games::Pandemic::Card::City->new(city=>$_) }
        $self->all_cities;
}


=method my $city = $map->find_city( $name );

=cut

sub find_city {
    my ($self, $name) = @_;
    return $self->_find_city( sub { $_[0]->name eq $name } );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

DEMOLISH

=end Pod::Coverage

