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

has actions_left => (
    metaclass => 'Counter',
    is        => 'rw',
    isa       => 'Int',
    provides  => {
        dec => 'action_done',
        set => 'set_actions_left',
    },
);

has location => ( is=>'rw', isa=>'Games::Pandemic::City', lazy_build => 1 );


# -- default builders

sub _build_location {
    return Games::Pandemic->instance->map->start_city;
}


# -- methods given by the games::pandemic::role::*

=method my $color = $player->color;

Return the C<$color> (html notation) to be used for this player.


=method my $role = $player->role_name;

Return the (localized) name of C<$player>'s role.

=cut

#
# my $name = $player->_image;
#
# return the internal, non-localized name of the role, used to name the
# various images associated to the role.
#


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


=method my $bool = $player->is_move_possible;

Return true if C<$player> can move, starting from her current location. Always
true. Included here for the sake of completeness.

=cut

sub is_move_possible { 1 }


=method my $bool = $player->is_flight_possible;

Return true if C<$player> can fly (regular flight) starting from her current
location. Flight is possible if the player has at least one city card, which is
not the card representing the city in which the player is.

=cut

sub is_flight_possible {
    my $self = shift;
    my @cards =
        grep { $_->city ne $self->location }
        $self->all_cards;
    return scalar @cards;
}


sub is_charter_possible {}
sub is_shuttle_possible {}
sub is_join_possible {}
sub is_build_possible {}
sub is_discover_possible {}
sub is_cure_possible {}
sub is_share_possible {}


=method my $bool = $player->is_pass_possible;

Return true if C<$player> can pass. Always true. Included here for the sake of
completeness.

=cut

sub is_pass_possible { 1 }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SYNOPSIS

    use Games::Pandemic::Player;
    my $role = 'Games::Pandemic::Role::Medic';
    my $player = Games::Pandemic::Player->new_with_traits(traits=>[$role]);

=head1 DESCRIPTION

This is a class implementing a player.

Among other things, a player has a role. In fact, it is consuming one of
the C<Games::Pandemic::Role::*> roles, which is applied as a trait
during object construction.

Therefore, to create a player, use the C<new_with_traits()> method (as
is done in the synopsis section).



