package Games::Pandemic::Player;
# ABSTRACT: pandemic game player

use 5.010;
use strict;
use warnings;

use File::Spec::Functions qw{ catfile };
use List::MoreUtils       qw{ any };
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


=method my $role = $player->role;

Return the (localized) name of C<$player>'s role.

=cut

#
# my $name = $player->_role;
#
# return the internal, non-localized name of the role, used to name the
# various images associated to the role.
#


# -- public methods

#- default role attributes, superseded by the various roles

=method my $bool = $player->auto_clean_on_cure;

Return true if the C<$player> applies automatically a cure by just being
in the city.

=method my $bool = $player->can_build;

Return true if the C<$player> can build a research station in a city
even if she doesn't have the city card.

=method my $bool = $player->can_join_others;

Return true if the C<$player> can move till a city where there's
another player.

=method my $bool = $player->can_move_others;

Return true if the C<$player> can move the other's pawns during her
turn.

=method my $bool = $player->can_share;

Return true if the C<$player> can give a card to another player even if
it isn't the card of the city in which they are.

=method my $nb = $player->cards_needed;

Return the number of cards of the same color that the C<$player> needs
to find a cure for a disease.

=method my $bool = $player->cure_all;

Return true if the C<$player> cures all the disease cubes in a city in
one go, even if the cure the city disease has not been discovered yet.

=method my $max = $player->max_cards;

Return the maximum number of cards that a player can have in her hands.

=cut

sub auto_clean_on_cure { 0 }
sub can_build_anywhere { 0 }
sub can_join_others    { 0 }
sub can_move_others    { 0 }
sub can_share          { 0 }
sub cards_needed       { 5 }
sub cure_all           { 0 }
sub max_cards          { 7 }


#- misc methods

=method my $path = $player->image( $what, $size );

Return the C$<path> to an image for the player role. C<$what> can be either
C<icon> or C<pawn>. C<$size> can be one of C<orig>, or 32 or 16. Note that not
all combinations are possible.

=cut

sub image {
    my ($self, $what, $size) = @_;
    return catfile(
        $SHAREDIR, 'roles',
        join('-', $self->_role, $what, $size) . '.png'
    );
}


=method my $bool = $player->owns_city_card( $city );

Return true if the C<$player> owns a card representing C<$city>.

=cut

sub owns_city_card {
    my ($self, $city) = @_;
    return
        any { $_->city eq $city }
        grep { $_->can('city') }
        $self->all_cards;
}


#- methods to check what actions are currently possible *now*

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

=method my $bool = $player->is_charter_possible;

=cut

sub is_charter_possible {}

=method my $bool = $player->is_shuttle_possible;

=cut

sub is_shuttle_possible {}

=method my $bool = $player->is_join_possible;

=cut

sub is_join_possible {}


=method my $bool = $player->is_build_possible;

Return true if C<$player> can build a research station in her current
location. It is possible if she owns the card of the city, or if she is
the operation expert.

=cut

sub is_build_possible {
    my $self = shift;
    return 1 if $self->can_build_anywhere;
    return $self->owns_city_card( $self->location);
}

=method my $bool = $player->is_discover_possible;

=cut

sub is_discover_possible {}

=method my $bool = $player->is_cure_possible;

=cut

sub is_cure_possible {}

=method my $bool = $player->is_share_possible;

=cut

sub is_share_possible {}


=method my $bool = $player->is_pass_possible;

Return true if C<$player> can pass. Always true. Included here for the sake of
completeness.

=cut

sub is_pass_possible { 1 }


#- methods to control whether an action (with all params) is valid

=method my $bool = $player->can_travel_to($city);

Return true if C<$player> can travel to C<$city> by proximity. This
means that C<$player> is in a location next to C<$city>.

=cut

sub can_travel_to {
    my ($self, $city) = @_;
    return any { $_ eq $city } $self->location->neighbours;
}


=method my $bool = $player->can_fly_to($city);

=cut

sub can_fly_to {}

=method my $bool = $player->can_charter_to($city);

=cut

sub can_charter_to {}

=method my $bool = $player->can_shuttle_to($city);

=cut

sub can_shuttle_to {}

=method my $bool = $player->can_join_to($city);

=cut

sub can_join_to {}




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



