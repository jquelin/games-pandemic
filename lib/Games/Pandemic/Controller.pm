package Games::Pandemic::Controller;
# ABSTRACT: controller for a pandemic game

use 5.010;
use strict;
use warnings;

use List::Util qw{ shuffle };
use MooseX::Singleton;  # should come before any other moose
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use Readonly;

use Games::Pandemic::Deck;
use Games::Pandemic::Map::Pandemic;
use Games::Pandemic::Player;

Readonly my $K  => $poe_kernel;

# -- accessors

# -- initialization

#
# START()
#
# called as poe session initialization.
#
sub START {
    $K->alias_set('controller');
}

# -- public events

=method event: new_game()

Create a new game: (re-)initialize the map, and various internal states.

=cut

event new_game => sub {
    my $game = Games::Pandemic->instance;

    # create the map
    my $map = Games::Pandemic::Map::Pandemic->new;
    $game->set_map( $map );

    # 5 research stations available. FIXME: should it be part of the map?
    $game->set_stations( 5 );

    # create the player cards deck
    my @pcards = shuffle $map->cards;
    my $pcards = Games::Pandemic::Deck->new( cards => \@pcards );
    $game->set_cards( $pcards );

    # create the infection deck
    my @icards = shuffle $map->disease_cards;
    my $icards = Games::Pandemic::Deck->new( cards => \@icards );
    $game->set_infection( $icards );

    # do the initial infections
    foreach my $nb ( $map->start_diseases ) {
        my $card = $icards->next;
        $K->yield( _infect => $card->city, $nb );
        $icards->discard( $card );
    }

    # create the players
    # FIXME: by now we're creating a fixed set of players, should be
    # configurable
    # FIXME: initial number of card depends of map / number of players
    $K->yield( _new_player => 'Scientist', 4 );
    $K->yield( _new_player => 'OperationsExpert', 4 );
#    $K->yield( _new_player => 'Medic', 4 );
#    $K->yield( _new_player => 'Researcher', 4 );
#    $K->yield( _new_player => 'Dispatcher', 4 );

    # signal main window that we have started a new game
    $K->post( 'main' => 'new_game' );
};


# -- private event

#
# _deal_card( $player, $nb );
#
# deal $nb cards to $player. check whether player has too much cards in
# her hands, and also for game over condition.
#
event _deal_card => sub {
    my ($player, $nb) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $deck = $game->cards;

    # deal some cards to the players
    foreach my $i ( 1 .. $nb ) {
        my $card = $deck->next;
        $player->give_card($card);
        $K->post(main=>'got_card', $player, $card);
    }

    # FIXME: game over if no more card
    # FIXME: if player has too much cards
};


#
# _infect( $city [, $nb [, $disease ] ] );
#
# infect $city with $nb items of $disease. perform an outbreak on
# neighbour cities if needed. $nb defaults to 1, $disease defaults to
# the city default disease.
#
event _infect => sub {
    my ($city, $nb, $disease) = @_[ARG0..$#_];
    $nb      //= 1;
    $disease //= $city->disease;

    # update the disease
    $disease->take($nb);
    #if ( $disease->nbleft <= 0 ) { # FIXME: gameover }

    # perform the infection & update the gui
    my $outbreak = $city->infect($nb, $disease);
    $K->post( main => 'infection', $city, $outbreak );

    return unless $outbreak;
    # FIXME: outbreak!
};


#
# event: _new_player( $role, $nb )
#
# request to create & store a new player, having $role and starting with
# $nb cards.
#
event _new_player => sub {
    my ($role, $nbcards) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;

    my $player = Games::Pandemic::Player->new(role_class=>$role);
    $game->add_player($player);
    $K->post( main => 'new_player', $player );
    $K->yield( '_deal_card', $player, $nbcards );
};


no Moose;
# singleton classes cannot be made immutable
#__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

START

=end Pod::Coverage
