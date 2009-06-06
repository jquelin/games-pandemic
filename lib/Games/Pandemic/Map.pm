package Games::Pandemic::Map;

use Games::Pandemic::City;
use Games::Pandemic::Disease;
use Moose;

has '_cities' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    writer  => '_set_cities',
);
has '_diseases' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    reader  => '_get_diseases',
    writer  => '_set_diseases',
);

sub BUILD {
    my $self = shift;

    # build the diseases
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
    $self->_set_diseases( \@diseases );

    # build the cities
    my @cities;
    foreach my $d ( $self->_raw_cities ) {
        my ($name, $disid, $xreal, $yreal, $x, $y, $neighbours) = @$d;
        my $disease = $diseases[$disid];
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
    $self->_set_cities( \@cities );
}


sub city_from_id {
    my ($self, $id) = @_;
    return $self->_cities->[$id];
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__