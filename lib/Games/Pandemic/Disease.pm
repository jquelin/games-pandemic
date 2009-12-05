use 5.010;
use strict;
use warnings;

package Games::Pandemic::Disease;
# ABSTRACT: pandemic disease object

use File::Spec::Functions qw{ catfile };
use Moose                 0.92;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;


# -- attributes

has colors => (
    ro, required,
    traits   => ['Array'],
    isa      => 'ArrayRef[Str]',
    handles  => { color => 'get' },
);
has id    => ( ro, required, isa => 'Int' );
has name  => ( ro, required, isa => 'Str' );
has nbleft => (
    ro, lazy,
    traits  => ['Number'],
    isa     => 'Int',
    builder => '_build_nb',
    handles => {
        return => 'add',
        take   => 'sub',
    },
);
has nbmax => ( ro, required, isa => 'Int' );
has _map  => ( ro, required, weak_ref, isa => 'Games::Pandemic::Map' );

has has_cure => (
    ro,
    traits  => ['Bool'],
    isa     => 'Bool',
    default => 0,
    handles => { find_cure => 'set' },
);

has is_eradicated => (
    ro,
    traits  => ['Bool'],
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

