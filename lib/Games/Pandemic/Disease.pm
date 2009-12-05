use 5.010;
use strict;
use warnings;

package Games::Pandemic::Disease;
# ABSTRACT: pandemic disease object

use File::Spec::Functions qw{ catfile };
use Moose                 0.92;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;


# -- attributes

has colors => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => { color => 'get' },
);
has id    => ( is => 'ro', isa => 'Int', required   => 1 );
has name  => ( is => 'ro', isa => 'Str', required   => 1 );
has nbleft => (
    traits  => ['Number'],
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build_nb',
    handles => {
        return => 'add',
        take   => 'sub',
    },
);
has nbmax => ( is => 'ro', isa => 'Int', required   => 1 );
has _map  => ( is => 'ro', isa => 'Games::Pandemic::Map',required => 1, weak_ref => 1 );

has has_cure => (
    traits  => ['Bool'],
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    handles => { find_cure => 'set' },
);

has is_eradicated => (
    traits  => ['Bool'],
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    handles => { eradicate => 'set' },
);

# -- default builders / finishers

sub DEMOLISH {
    my $self = shift;
    debug( "~disease: " . $self->name . "\n" );
}

sub _build_nb { $_[0]->nbmax }


# -- public methods

=method my $path = $disease->image($what);

Return the C<$path> to an image for the disease. C<$what> can be either
C<cube> or C<cure>.

=cut

sub image {
    my ($self, $what, $size) = @_;
    return catfile( $self->_map->sharedir, $what . '-' . $self->id . "-$size.png" );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for Pod::Coverage
    DEMOLISH

