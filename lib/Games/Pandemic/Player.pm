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
    metaclass  => 'Collection::Hash',
    is         => 'ro',
    isa        => 'HashRef[Games::Pandemic::Card]',
    default    => sub { {} },
    auto_deref => 1,
    provides   => {
        count   => 'nb_cards',        # my $nb = $player->nb_cards;
        values  => 'all_cards',       # my @c = $player->all_cards;
        delete  => 'drop_card',       # $player->drop_card( $card );
        set     => '_add_card',       # $player->_add_card( $card, $card );
        exists  => 'owns_card',       # my $bool = $player->owns_card($card);
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

=method my $bool = $player->can_build_anywhere;

Return true if the C<$player> can build a research station in a city
even if she doesn't have the city card.

=method my $bool = $player->can_join_others;

Return true if the C<$player> can move till a city where there's
another player.

=method my $bool = $player->can_move_others;

Return true if the C<$player> can move the other's pawns during her
turn.

=method my $bool = $player->can_share_anywhere;

Return true if the C<$player> can give a card to another player even if
it isn't the card of the city in which they are.

=method my $nb = $player->cards_needed;

Return the number of cards of the same color that the C<$player> needs
to find a cure for a disease.

=method my $bool = $player->treat_all;

Return true if the C<$player> treats all the disease cubes in a city in
one go, even if the cure for the disease has not been discovered yet.

=method my $max = $player->max_cards;

Return the maximum number of cards that a player can have in her hands.

=cut

sub auto_clean_on_cure { 0 }
sub can_build_anywhere { 0 }
sub can_join_others    { 0 }
sub can_move_others    { 0 }
sub can_share_anywhere { 0 }
sub cards_needed       { 5 }
sub treat_all          { 0 }
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


=method my $card = $player->owns_city_card( $city );

Return the C<$card> representing C<$city> if the C<$player> owns it,
undef otherwise.

=cut

sub owns_city_card {
    my ($self, $city) = @_;
    my ($card) =
        grep { $_->can('city') && $_->city eq $city }
        $self->all_cards;
    return $card;
}


=method $player->gain_card( $card )

C<$player> gains a new C<$card>.

=cut

sub gain_card {
    my ($self, $card) = @_;
    $self->_add_card( $card, $card );
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
the operation expert. Of course it is impossible if there's already a
station in the city.

=cut

sub is_build_possible {
    my $self = shift;
    my $city = $self->location;

    return 0 if $city->has_station;
    return 1 if $self->can_build_anywhere;
    return $self->owns_city_card( $city );
}


=method my $disease = $player->is_discover_possible;

Return the C<$disease> that C<$player> can cure, that is, if she owns
enough city cards of this disease and she is in a city with a research
station. Return undef otherwise.

=cut

sub is_discover_possible {
    my $self = shift;

    return unless $self->location->has_station;

    # get list of city cards
    my @cards =
        grep { $_->isa('Games::Pandemic::Card::City') }
        $self->all_cards;

    # check if we have enough cards
    my %seen;
    foreach my $card ( @cards ) {
        my $disease = $card->city->disease;
        my $name = $disease->name;
        $seen{$name}++;
        return $disease if $seen{$name} == $self->cards_needed;
    }

    return 0;
}


=method my $bool = $player->is_treat_possible;

Return true if C<$player> can treat a disease. It is possible if her current
location is infected by one (or more) disease.

=cut

sub is_treat_possible {
    my $self = shift;
    my $city = $self->location;
    my $game = Games::Pandemic->instance;
    my $map  = $game->map;

    foreach my $disease ( $map->all_diseases ) {
        return 1 if $city->get_infection($disease);
    }
    return 0;
}


=method my $bool = $player->is_share_possible;

Return true if C<$player> can share a card in her current location. It is
possible if she owns the card of the city, or if she is the researcher. Of
course it is impossible if player's alone in the city.

=cut

sub is_share_possible {
    my $self = shift;
    my $city = $self->location;
    my $game = Games::Pandemic->instance;

    return 0 unless grep { $_ ne $self && $_->location eq $city } $game->all_players;
    return 1 if $self->can_share_anywhere;
    return $self->owns_city_card( $city );
}


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


=method my $bool = $player->can_shuttle_to($city);

Return true if C<$player> can shuttle through research station to
C<$city>. This means that both current player location and remote
C<$city> have a research station. Of course, return value is false if
C<$player> is currently located in <$city>.

=cut

sub can_shuttle_to {
    my ($self, $city) = @_;
    my $location = $self->location;
    return $city ne $location && $location->has_station && $city->has_station;
}


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



