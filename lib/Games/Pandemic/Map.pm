package Games::Pandemic::Map;
# ABSTRACT: map information for Games::Pandemic

use File::Spec::Functions qw{ catdir catfile };
use Moose;
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::City;
use Games::Pandemic::Disease;
use Games::Pandemic::Utils;

# -- accessors

has _cities => (
    metaclass  => 'Collection::List',
    is         => 'ro',
    isa        => 'ArrayRef[Games::Pandemic::City]',
    builder    => '_cities_builder',
    lazy       => 1,  # _diseases() needs to be built before
    auto_deref => 1,
    provides   => {
        elements => 'all_cities',
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


# -- default builders

sub _cities_builder {
    my $self = shift;

    my @cities;
    foreach my $d ( $self->_raw_cities ) {
        my ($name, $disid, $xreal, $yreal, $x, $y, $neighbours) = @$d;
        my $disease = $self->disease($disid);
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
        my ($name, $colors, $nb, $image) = @$d;
        my $disease = Games::Pandemic::Disease->new(
            name   => $name,
            colors => $colors,
            nbmax  => $nb,
            _image => $image,
            _map   => $self,
        );
        push @diseases, $disease;
    }
    return \@diseases;
}


sub _start_city_builder {
    my $self = shift;
    my $id   = $self->_raw_start_city;
    my $city = $self->city_from_id($id);
    $city->build_station;
    return $city;
}

# -- public methods

sub city_from_id {
    my ($self, $id) = @_;
    return $self->_cities->[$id];
}


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


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__