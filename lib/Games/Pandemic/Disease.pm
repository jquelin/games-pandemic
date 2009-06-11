package Games::Pandemic::Disease;
# ABSTRACT: disease object for Games::Pandemic

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;

# -- attributes

has 'colors' => (
    metaclass  => 'Collection::List',
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    required   => 1,
    provides   => { get => 'color' },
);
has _image  => ( is => 'ro', required => 1, isa => 'Str' );
has 'name'  => ( is => 'ro', required => 1 );
has 'nb'    => ( is => 'rw', default  => 0, isa => 'Int' );
has 'nbmax' => ( is => 'ro', required => 1, isa => 'Int' );
has '_map'  => ( is => 'ro', required => 1, isa => 'Games::Pandemic::Map', weak_ref => 1 );


# -- public methods

=method my $path = $disease->image;

Return the C<$path> to an image for the disease B<cure>.

=cut

sub image {
    my $self = shift;
    return catfile( $self->_map->sharedir, $self->_image );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__