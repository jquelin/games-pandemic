package Games::Pandemic::City;
# ABSTRACT: city object for Games::Pandemic

use Moose;
use MooseX::AttributeHelpers;

has 'name'    => ( is => 'ro', required => 1, isa => 'Str' );
has 'x'       => ( is => 'ro', required => 1, isa => 'Num' );
has 'y'       => ( is => 'ro', required => 1, isa => 'Num' );
has 'xreal'   => ( is => 'ro', required => 1, isa => 'Num' );
has 'yreal'   => ( is => 'ro', required => 1, isa => 'Num' );
has 'disease' => ( is => 'ro', required => 1, isa => 'Games::Pandemic::Disease', weak_ref => 1 );
has '_map'    => ( is => 'ro', required => 1, isa => 'Games::Pandemic::Map', weak_ref => 1 );
has 'nb'      => ( is => 'rw', default  => 0, isa => 'Int' );

has 'neighbour_ids' => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    required  => 1,
    isa       => 'ArrayRef',
    provides  => {
        elements => '_neighbour_ids',
    },
);

sub neighbours {
    my $self = shift;
    my $map = $self->_map;
    return map { $map->city_from_id($_) } $self->_neighbour_ids;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__