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


=method $city->build_station;

Create a research station in the city.

=method $city->quash_station;

Remove the research station that was in the city.

=method my $bool = $city->has_station;

Return true if the city has a research station.

=cut

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
#
# private methods provided:
#  . my $nb = $city->_get_infection($id);
#    return the number of item for disease $id in the $city.
#    see public method get_infection()
#
#  . $city->_set_infection($id, $nb);
#    set the new number $nb of items for disease $id in the $city.
#    see public method infect()
#
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


=method my $outbreak = $city->infect( [ $nb [, $disease] ] )

Infect C<$city> with C<$nb> items of C<$disease>. Return true if an
outbreak happened following this infection, false otherwise.

C<$nb> defaults to 1, and C<$disease> to the city disease.

=cut

sub infect {
    my ($self, $nb, $disease) = @_;
    $nb      //= 1;
    $disease //= $self->disease;

    # perform the infection
    my $id  = $disease->id;
    my $old = $self->_get_infection($id) // 0; # FIXME//padre
    my $new = $old + $nb;
    my $max = $self->_map->max_infections;

    # check for outbreak
    my $outbreak = 0;
    if ( $new > $max ) {
        $new      = $max;
        $outbreak = 1;
    }

    # store new infection state & return outbreak status
    $self->_set_infection( $id, $new );
    return $outbreak;
}


=method my $nb = $city->get_infection( $disease );

Return the number of C<$disease> items for the C<$city>.

=cut

sub get_infection {
    my ($self, $disease) = @_;
    return $self->_get_infection( $disease->id ) // 0; # FIXME//padre
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 DESCRIPTION

This module implements a class for city objects, used in Pandemic. They
have different attributes:

=over 4

=item * name: the city name

=item * xreal: the x coord of the city

=item * yreal: the y coord of the city

=item * x: the x coord where city information will be put

=item * y: the y coord where city information will be put

=item * disease: a ref to a C<Games::Pandemic::Disease> object, which is
the disease which will infect the city by default

=back
