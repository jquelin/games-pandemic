package Games::Pandemic::Player;
# ABSTRACT: pandemic game player

use 5.010;
use strict;
use warnings;

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;
use UNIVERSAL::require;

with 'MooseX::Traits';

use Games::Pandemic::Utils;


# -- accessors

has _cards => (
    metaclass  => 'Collection::Array',
    is         => 'ro',
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    default    => sub { [] },
    auto_deref => 1,
    provides   => {
        elements => 'all_cards',       # my @c = $player->all_cards;
        push     => 'give_card',       # $player->give_card( $card );
    }
);

has location => ( is=>'rw', isa=>'Games::Pandemic::City', lazy_build => 1 );


# -- default builders

sub _build_location {
    return Games::Pandemic->instance->map->start_city;
}


# -- public methods

# default role attribute, superseded by the various roles
sub auto_clean_on_cure { 0 }
sub can_build          { 0 }
sub can_join_others    { 0 }
sub can_move_others    { 0 }
sub can_share          { 0 }
sub cards_needed       { 5 }
sub cure_all           { 0 }
sub max_cards          { 7 }


=method my $path = $player->image( $what, $size );

Return the C$<path> to an image for the player role. C<$what> can be either
C<icon> or C<pawn>. C<$size> can be one of C<orig>, or 32 or 16. Note that not
all combinations are possible.

=cut

sub image {
    my ($self, $what, $size) = @_;
    return catfile(
        $SHAREDIR, 'roles',
        join('-', $self->_image, $what, $size) . '.png'
    );
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 DESCRIPTION

This is a class implementing a player. Note that the player role in the
game is described in a C<Games::Pandemic::Role> subclass.

