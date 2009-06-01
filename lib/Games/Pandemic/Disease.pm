package Games::Pandemic::Disease;

use Moose;

has 'name'  => ( is => 'ro', required => 1 );
has 'color' => ( is => 'ro', required => 1 );
has 'nb'    => ( is => 'rw', default  => 0, isa => 'Int' );
has 'nbmax' => ( is => 'ro', required => 1, isa => 'Int' );
has '_map'  => ( is => 'ro', required => 1, isa => 'Games::Pandemic::Map', weak_ref => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__