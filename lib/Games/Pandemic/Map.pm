package Games::Pandemic::Map;
# ABSTRACT: map information for Games::Pandemic

use File::Spec::Functions qw{ catfile rel2abs };
use Moose;
use MooseX::FollowPBP;

use Games::Pandemic::City;
use Games::Pandemic::Disease;
use Games::Pandemic::Utils;

# -- accessors

has _cities => (
    is      => 'ro',
    isa     => 'ArrayRef',
    builder => '_cities_builder',
    lazy    => 1,  # _diseases() needs to be built before
);

has _diseases => (
    is      => 'ro',
    isa     => 'ArrayRef',
    builder => '_diseases_builder',
);

has name => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_name',
);

# -- default builders

sub _cities_builder {
    my $self = shift;

    my @cities;
    foreach my $d ( $self->_raw_cities ) {
        my ($name, $disid, $xreal, $yreal, $x, $y, $neighbours) = @$d;
        my $disease = $self->disease_from_id($disid);
        my $city = Games::Pandemic::City->new(
            name    => $name,
            xreal   => $xreal,
            yreal   => $yreal,
            x       => $x,
            y       => $y,
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
        my ($name, $colors, $nb) = @$d;
        my $disease = Games::Pandemic::Disease->new(
            name   => $name,
            colors => $colors,
            nbmax  => $nb,
            _map   => $self,
        );
        push @diseases, $disease;
    }
    return \@diseases;
}


# -- public methods

sub city_from_id {
    my ($self, $id) = @_;
    return $self->_cities->[$id];
}

sub disease_from_id {
    my ($self, $id) = @_;
    return $self->_get_diseases->[$id];
}

=method my $bgpath = $map->background_path;

Return the path the background image of the map.

=cut

sub background_path {
    my $self = shift;
    return rel2abs( catfile( $SHAREDIR, 'maps', $self->get_name, 'background.jpg' ) );
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__