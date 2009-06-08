package Games::Pandemic::Disease;
# ABSTRACT: disease object for Games::Pandemic

use Moose;
use MooseX::AttributeHelpers;

has 'colors' => (
    metaclass  => 'Collection::List',
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    required   => 1,
    provides   => { get => 'color' },
);
has 'name'  => ( is => 'ro', required => 1 );
has 'nb'    => ( is => 'rw', default  => 0, isa => 'Int' );
has 'nbmax' => ( is => 'ro', required => 1, isa => 'Int' );
has '_map'  => ( is => 'ro', required => 1, isa => 'Games::Pandemic::Map', weak_ref => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__