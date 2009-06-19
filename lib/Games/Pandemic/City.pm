package Games::Pandemic::City;
# ABSTRACT: city object for Games::Pandemic

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;

# -- accessors

has name    => ( is => 'ro', required => 1, isa => 'Str' );
has x       => ( is => 'ro', required => 1, isa => 'Num' );
has y       => ( is => 'ro', required => 1, isa => 'Num' );
has xreal   => ( is => 'ro', required => 1, isa => 'Num' );
has yreal   => ( is => 'ro', required => 1, isa => 'Num' );
has disease => ( is => 'ro', required => 1, isa => 'Games::Pandemic::Disease', weak_ref => 1 );
has _map    => ( is => 'ro', required => 1, isa => 'Games::Pandemic::Map', weak_ref => 1 );
has nb      => ( is => 'rw', default  => 0, isa => 'Int' );

has has_station => (
    metaclass => 'Bool',
    is        => 'rw',
    isa       => 'Bool',
    default   => 0,
    provides  => {
        set     => 'build_station',
        unset   => 'quash_station',
    }
);

#
# _infections is an array of integer. the indexes are the disease ids,
# and the values are the number of disease items on the city.
has _infections => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => 'ArrayRef[Int]',
    default   => sub { [] },
    provides  => {
        get => '_get_infection',
        set => '_set_infection',
    },
);

has neighbour_ids => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    required  => 1,
    isa       => 'ArrayRef',
    provides  => {
        elements => '_neighbour_ids',
    },
);


# -- public methods

=method my @cities = $city->neighbours;

Return a list of C<Games::Pandemic::City>, which are the direct
neighbours of C<$city>.

=cut

sub neighbours {
    my $self = shift;
    my $map = $self->_map;
    return map { $map->city($_) } $self->_neighbour_ids;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__